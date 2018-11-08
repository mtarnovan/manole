# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger, level: :warn

config :manole, ecto_repos: [Manole.Repo]

config :manole, Manole.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "manole_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
