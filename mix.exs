defmodule Dropex.MixProject do
  use Mix.Project

  @github_url "https://github.com/binajmen/dropex"
  @version "0.1.0"

  def project do
    [
      app: :dropex,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Dropex",
      source_url: @github_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Dropex.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5.2"},
      {:jason, "~> 1.4.4"}
    ]
  end

  defp description() do
    "An Elixir library for interacting with the Dropbox API v2."
  end

  defp package() do
    [
      maintainers: ["Benjamin Decoster"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github_url}
    ]
  end
end
