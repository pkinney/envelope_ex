defmodule Envelope.Mixfile do
  use Mix.Project

  @source_url "https://github.com/pkinney/envelope_ex"
  @version "1.3.1"

  def project do
    [
      app: :envelope,
      version: @version,
      elixir: "~> 1.2",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [applications: [:logger, :geo, :distance]]
  end

  defp deps do
    [
      {:geo, "~> 1.0 or ~> 2.0 or ~> 3.0"},
      {:distance, "~> 0.2.1 or ~> 1.0"},
      {:excoveralls, "~> 0.4", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:poison, "~> 3.0", only: [:dev, :test]},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      description:
        "A library for calculating envelopes of geometries " <>
          "and tools to compare them.",
      files: ["lib/envelope.ex", "mix.exs", "README*"],
      maintainers: ["Powell Kinney"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp aliases do
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

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "master",
      formatters: ["html"]
    ]
  end
end
