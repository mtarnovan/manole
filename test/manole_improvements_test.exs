defmodule ManoleImprovementsTest do
  use ExUnit.Case, async: true
  alias Ecto.Adapters.SQL.Sandbox
  alias Manole.{Person, Repo}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "rejects invalid operator" do
    filter = %{
      combinator: :and,
      rules: [%{field: "name", operator: "invalid_op", value: "Mihai"}]
    }

    assert {:error, "Invalid operator: \"invalid_op\""} = Manole.build_query(Person, filter)
  end

  test "escapes wildcards in contains" do
    # We insert a person with a literal "%" in their name
    Repo.insert!(%Person{name: "100%", age: 30})
    Repo.insert!(%Person{name: "100", age: 30})

    # If escaping works, searching for "%" should only return "100%", not "100" (because % matches anything in SQL)
    # But wait, % in LIKE matches anything.
    # If we search for "100%", escaping transforms it to "100\%" -> SQL LIKE "%100\%%".
    # This matches anything containing literal "100%".

    filter = %{
      combinator: :and,
      rules: [%{field: "name", operator: "contains", value: "100%"}]
    }

    {:ok, query} = Manole.build_query(Person, filter)
    results = Repo.all(query)

    assert length(results) == 1
    assert hd(results).name == "100%"
  end
end
