defmodule Envelope.Mixfile do
  use Mix.Project

  def project do
    [app: :envelope,
     version: "0.2.0",
     elixir: "~> 1.2",
     description: description,
     package: package,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:geo, "~> 1.0"},
      {:distance, "~> 0.2.1"},
      {:benchfella, "~> 0.3.0", only: :dev},
      {:excoveralls, "~> 0.4", only: :test},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}
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
      links: %{ "GitHub" => "https://github.com/pkinney/envelope_ex",
                "Docs" => "https://hexdocs.pm/envelope/Envelope.html"}
    ]
  end
end
