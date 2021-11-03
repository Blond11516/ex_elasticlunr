defmodule Elasticlunr.IndexTest do
  use ExUnit.Case

  alias Elasticlunr.{Field, Index}

  describe "creating an index" do
    test "creates a new instance" do
      assert %Index{name: name} = Index.new()
      assert is_binary(name)
      assert %Index{name: :test_index, ref: :id, fields: %{}} = Index.new(name: :test_index)

      assert %Index{name: :test_index, ref: :name, fields: %{}} =
               Index.new(name: :test_index, ref: :name)
    end

    test "creates a new instance and populate fields" do
      fields = ~w[id name]a

      assert %Index{fields: %{id: %Field{}, name: %Field{}}} = Index.new(fields: fields)
    end
  end

  describe "modifying an index" do
    test "adds new fields" do
      index = Index.new()
      assert %Index{fields: %{}} = index
      assert index = Index.add_field(index, :name)
      assert %Index{fields: %{name: %Field{}}} = index
      assert %Index{fields: %{name: %Field{}, bio: %Field{}}} = Index.add_field(index, :bio)
    end

    test "save document" do
      index = Index.add_field(Index.new(), :name)

      assert %Index{fields: %{name: %Field{store: true}}} = index
      assert %Index{fields: %{name: %Field{store: false}}} = Index.save_document(index, false)
    end
  end

  describe "fiddling with an index" do
    test "adds document" do
      index = Index.new(fields: ~w[id bio]a)

      assert index =
               Index.add_documents(index, [
                 %{
                   id: 10,
                   bio: Faker.Lorem.paragraph()
                 }
               ])

      assert %Index{documents_size: 1} = index

      assert %Index{documents_size: 2} =
               Index.add_documents(index, [
                 %{
                   id: 29,
                   bio: Faker.Lorem.paragraph()
                 }
               ])
    end

    test "allows addition of document with empty field" do
      index = Index.new(fields: ~w[id title bio]a)

      assert index = Index.add_documents(index, [%{id: 10, bio: "", title: "test"}])

      assert term_frequency =
               index
               |> Index.get_field(:title)
               |> Field.term_frequency("test")

      assert term_frequency
             |> Enum.count()
             |> Kernel.==(1)

      assert term_frequency
             |> Map.get(10)
             |> Kernel.==(1)
    end

    test "fails when adding duplicate document" do
      index = Index.new(fields: ~w[id bio]a)

      document = %{
        id: 10,
        bio: Faker.Lorem.paragraph()
      }

      assert index = Index.add_documents(index, [document])

      assert_raise RuntimeError, "Document id 10 already exists in the index", fn ->
        Index.add_documents(index, [document])
      end
    end

    test "removes document" do
      index = Index.new(fields: ~w[id bio]a)

      document = %{
        id: 10,
        bio: "this is a test"
      }

      document_2 = %{
        id: 30,
        bio: "this is another test"
      }

      assert index = Index.add_documents(index, [document_2, document])
      assert %Index{documents_size: 2} = index
      assert index = Index.remove_documents(index, [10])
      assert %Index{documents_size: 1} = index
      assert field = Index.get_field(index, :bio)
      refute Field.has_token(field, "a")
      assert Field.has_token(field, "another")
      assert is_nil(Field.get_token(field, "a"))
      assert %{idf: idf} = Field.get_token(field, "another")
      assert idf > 0
      assert %{documents: [30]} = Field.get_token(field, "another")
    end

    test "does not remove unknown document" do
      index = Index.new(fields: ~w[id bio]a)

      document = %{
        id: 10,
        bio: Faker.Lorem.paragraph()
      }

      assert index = Index.add_documents(index, [document])
      assert %Index{documents_size: 1} = index
      assert %Index{documents_size: 1} = Index.remove_documents(index, [11])
    end

    test "update existing document" do
      index = Index.new(fields: ~w[id bio]a)

      document = %{
        id: 10,
        bio: Faker.Lorem.paragraph()
      }

      index = Index.add_documents(index, [document])

      assert %Index{documents_size: 1} = index
      updated_document = %{document | bio: Faker.Lorem.paragraph()}
      assert %Index{documents_size: 1} = Index.update_documents(index, [updated_document])
    end

    test "search for a document" do
      index = Index.new(fields: ~w[bio]a)

      document = %{
        id: 10,
        bio: "foo"
      }

      index = Index.add_documents(index, [document])

      assert Index.search(index, "foo") |> Enum.count() == 1
      updated_document = %{document | bio: "bar"}
      index = Index.update_documents(index, [updated_document])
      assert Index.search(index, "bar") |> Enum.count() == 1
      assert Index.search(index, "foo") |> Enum.empty?()
    end
  end
end
