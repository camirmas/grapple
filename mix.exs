defmodule Grapple.Mixfile do
  use Mix.Project

  def project do
    [app: :grapple,
     version: "0.2.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "Webhooks service in a PubSub manner",
     package: package,
     deps: deps(),
   
     # Docs
     name: "Grapple",
     source_url: "https://github.com/camirmas/grapple",
     docs: [# logo: "",
            canonical: "https://hexdocs.com/grapple",
            extras: ["README.md"]]]
  end

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
      applications: [:httpoison, :logger, :plug, :gen_stage, :timex],
      mod: {Grapple, []},
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
      {:graphql, "~> 0.3"},
      {:httpoison, "~> 0.9.0"},
      {:uuid, "~> 1.1"},
      {:plug, "~> 1.2.0"},
      {:gen_stage, "~> 0.4"},
      {:ex_doc, "~> 0.13", only: :dev},
      {:timex, "~> 3.0"},
    ]
  end
end
