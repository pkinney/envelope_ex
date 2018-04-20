defmodule Envelope.Mixfile do
  use Mix.Project

  def project do
    [
      app: :envelope,
      version: "1.1.0",
      elixir: "~> 1.2",
      description: description(),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :geo, :distance]]
  end

  defp deps do
    [
      {:geo, "~> 1.0 or ~> 2.0 or ~> 3.0"},
      {:distance, "~> 0.2.1"},
      {:excoveralls, "~> 0.4", only: :test},
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.16", only: :dev},
      {:poison, "~> 3.0", only: [:dev, :test]},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false}
    ]
  end

  defp description do
    """
    A library for calculating envelopes of geometries and tools to compare them.
    """
  end

  defp package do
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
end
