defmodule SwooshGroundmail.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/Groundmail/swoosh_groundmail"

  def project do
    [
      app: :swoosh_groundmail,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Swoosh adapter for Groundmail transactional email. Send Phoenix and Elixir email through the Groundmail API.",
      package: package(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: "https://docs.groundmail.dev/frameworks/phoenix"
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:swoosh, "~> 1.16"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5", optional: true},
      {:bypass, "~> 2.1", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://docs.groundmail.dev/frameworks/phoenix",
        "Groundmail" => "https://groundmail.dev"
      },
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [main: "readme", extras: ["README.md"], source_ref: "v#{@version}"]
  end
end
