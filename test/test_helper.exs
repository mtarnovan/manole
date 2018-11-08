ExUnit.start()

{:ok, _} = Manole.Repo.start_link()

Mix.Task.run("ecto.create", ~w(-r Manole.Repo --quiet))
Ecto.Migrator.up(Manole.Repo, 0, Manole.Test.Migration, log: false)
Ecto.Adapters.SQL.Sandbox.mode(Manole.Repo, :manual)
