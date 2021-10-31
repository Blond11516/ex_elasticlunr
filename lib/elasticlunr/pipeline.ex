defmodule Elasticlunr.Pipeline do
  @moduledoc false

  alias Elasticlunr.Token
  alias Elasticlunr.Pipeline.{Stemmer, StopWordFilter, Trimmer}

  defstruct callback: []

  @type t :: %__MODULE__{
          callback: list()
        }

  @callback call(Token.t(), list(Token.t())) :: Token.t() | list(Token.t())

  @spec new(list(module())) :: struct
  def new(callbacks) when is_list(callbacks) do
    struct!(__MODULE__, callback: callbacks)
  end

  @spec add(t(), module()) :: t()
  def add(%__MODULE__{callback: callback} = pipeline, module) do
    callback = Enum.uniq([module] ++ callback)
    %{pipeline | callback: callback}
  end

  @spec default_runners() :: list(module())
  def default_runners, do: [Trimmer, StopWordFilter, Stemmer]

  @spec run(Elasticlunr.Pipeline.t(), list(Token.t())) :: list(Token.t())
  def run(%__MODULE__{callback: []}, tokens), do: tokens

  def run(%__MODULE__{callback: callback}, tokens) do
    callback
    |> Enum.reduce(tokens, fn module, acc ->
      excute_runner(acc, module)
    end)
  end

  @spec insert_before(t(), module(), module()) :: t()
  def insert_before(%__MODULE__{callback: callback} = pipeline, module, before_module) do
    case Enum.find_index(callback, &(&1 == before_module)) do
      nil ->
        add(pipeline, module)

      index ->
        callback =
          callback
          |> List.insert_at(index, module)
          |> Enum.uniq()

        %{pipeline | callback: callback}
    end
  end

  @spec insert_after(t(), module(), module()) :: t()
  def insert_after(%__MODULE__{callback: callback} = pipeline, module, before_module) do
    case Enum.find_index(callback, &(&1 == before_module)) do
      nil ->
        add(pipeline, module)

      index ->
        callback =
          callback
          |> List.insert_at(index + 1, module)
          |> Enum.uniq()

        %{pipeline | callback: callback}
    end
  end

  @spec remove(t(), module()) :: t()
  def remove(%__MODULE__{callback: callback} = pipeline, module) do
    callback = Enum.reject(callback, &(&1 == module))
    %{pipeline | callback: callback}
  end

  defp excute_runner(tokens, module) do
    Enum.reduce(tokens, [], fn token, state ->
      output = module.call(token, state)

      output =
        case is_list(output) do
          true ->
            output

          false ->
            [output]
        end

      output = Enum.filter(output, &(not is_nil(&1)))

      state ++ output
    end)
  end
end
