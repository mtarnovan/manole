# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

config :logger, level: :warning

config :manole, ecto_repos: [Manole.Repo]

config :manole, Manole.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "manole_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
