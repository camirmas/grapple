defmodule Grapple.Mixfile do
  use Mix.Project

  def project do
    [
      app: :grapple,
      version: "1.2.3",
      elixir: "~> 1.6.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: "Webhook magic in Elixir",
      package: package(),
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Docs
      name: "Grapple",
      source_url: "https://github.com/camirmas/grapple",
      # logo: "",
      docs: [canonical: "https://hexdocs.com/grapple", extras: ["README.md"]]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def package do
    [
      maintainers: ["Cameron Irmas, Erik Vavro"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/camirmas/grapple"}
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:httpoison, :logger, :gen_stage],
      mod: {Grapple, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 1.0"},
      {:gen_stage, "~> 0.4"},
      {:ex_doc, "~> 0.13", only: :dev}
    ]
  end
end
