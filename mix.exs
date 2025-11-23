defmodule Manole.MixProject do
  use Mix.Project

  def project do
    [
      app: :manole,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: ["lib", "test"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        lint: :test
      ],
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:ecto, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      lint: ["compile --warnings-as-errors", "credo --strict", "format --check-formatted"]
    ]
  end
end
