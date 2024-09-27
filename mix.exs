defmodule Envelope.Mixfile do
  use Mix.Project

  def project() do
    [
      app: :envelope,
      version: "1.4.1",
      elixir: "~> 1.2",
      description: description(),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application() do
    [applications: [:logger, :geo, :distance]]
  end

  defp deps() do
    [
      {:geo, "~> 1.0 or ~> 2.0 or ~> 3.0 or ~> 4.0"},
      {:distance, "~> 0.2.1 or ~> 1.0"},
      {:excoveralls, "~> 0.4", only: :test},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:poison, "~> 5.0", only: [:dev, :test]},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:topo, "~> 0.4", only: [:test]}
    ]
  end

  defp description do
    """
    A library for calculating envelopes of geometries and tools to compare them.
    """
  end

  defp package() do
    [
      files: ["lib/envelope.ex", "mix.exs", "README*"],
      maintainers: ["Powell Kinney"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/pkinney/envelope_ex",
        "Docs" => "https://hexdocs.pm/envelope/Envelope.html"
      }
    ]
  end

  defp aliases() do
    [
      validate: [
        "clean",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo",
        "dialyzer"
      ]
    ]
  end
end
