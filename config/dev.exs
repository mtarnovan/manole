# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

import_config "test.exs"

config :logger, level: :info

config :manole, Manole.Repo, database: "manole_dev"
