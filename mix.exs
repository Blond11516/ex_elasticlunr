defmodule Elasticlunr.MixProject do
  use Mix.Project

  @source_url "https://github.com/heywhy/ex_elasticlunr"

  def project do
    [
      app: :elasticlunr,
      version: "0.6.4",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: @source_url,

      # Coverage
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],

      # Dialyxir
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],

      # Docs
      name: "Elasticlunr",
      homepage_url: "https://hexdocs.pm/elasticlunr",
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {Elasticlunr.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:faker, "~> 0.16", only: :test},
      {:jason, "~> 1.3"},
      {:mox, "~> 1.0", only: :test},
      {:stemmer, "~> 1.0"},
      {:uniq, "~> 0.4"}
    ]
  end

  defp description do
    "Elasticlunr is a lightweight full-text search engine. It's a port of Elasticlunr.js with more improvements."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Atanda Rasheed"],
      licenses: ["MIT License"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/elasticlunr"
      }
    ]
  end
end
