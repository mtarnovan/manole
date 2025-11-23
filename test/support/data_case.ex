defmodule Manole.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Manole.Repo

      import Ecto
      import Ecto.Query
      import Manole.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Manole.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Manole.Repo, {:shared, self()})
    end

    :ok
  end
end
