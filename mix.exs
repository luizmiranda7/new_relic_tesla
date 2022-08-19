defmodule NewRelicTesla.MixProject do
  use Mix.Project

  def project do
    [
      app: :new_relic_tesla,
      description: "New Relic Instrumentation for Tesla",
      version: "0.0.2",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      name: "New Relic Tesla",
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Luiz Miranda"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/luizmiranda7/new_relic_tesla"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.1"},
      {:new_relic_agent, "~> 1.19"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
