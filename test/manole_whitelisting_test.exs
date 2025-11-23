defmodule ManoleWhitelistingTest do
  use ExUnit.Case, async: true
  alias Ecto.Adapters.SQL.Sandbox
  alias Manole.{Dog, Person, Repo}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "allows fields in whitelist" do
    p1 = Repo.insert!(%Person{name: "Mihai", age: 30})

    filter = %{
      combinator: :and,
      rules: [%{field: "name", operator: "=", value: "Mihai"}]
    }

    whitelist = [:name]
    {:ok, query} = Manole.build_query(Person, filter, whitelist)
    assert Repo.aggregate(query, :count, :id) == 1
  end

  test "blocks fields not in whitelist" do
    Repo.insert!(%Person{name: "Mihai", age: 30})

    filter = %{
      combinator: :and,
      rules: [%{field: "age", operator: ">", value: "20"}]
    }

    # 'age' is missing
    whitelist = [:name]

    # Expecting an error (once implemented)
    assert {:error, "Field 'age' is not whitelisted"} =
             Manole.build_query(Person, filter, whitelist)
  end

  test "allows nested fields in whitelist" do
    p1 = Repo.insert!(%Person{name: "Mihai", age: 30})
    Repo.insert!(%Dog{name: "Gigi", person_id: p1.id})

    filter = %{
      combinator: :and,
      rules: [%{field: "dogs.name", operator: "=", value: "Gigi"}]
    }

    whitelist = [dogs: [:name]]
    {:ok, query} = Manole.build_query(Person, filter, whitelist)
    assert Repo.aggregate(query, :count, :id) == 1
  end

  test "blocks nested fields not in whitelist" do
    filter = %{
      combinator: :and,
      rules: [%{field: "dogs.age", operator: ">", value: "5"}]
    }

    # 'dogs.age' is missing
    whitelist = [dogs: [:name]]

    assert {:error, "Field 'dogs.age' is not whitelisted"} =
             Manole.build_query(Person, filter, whitelist)
  end

  test "empty whitelist allows nothing (if strict mode? or default deny?)" do
    # Assuming whitelist means "only allow these".
    # If whitelist is empty list [], does it mean "allow all" (backwards compat) or "allow none"?
    # The signature default is `_whitelist \\ []`.
    # Usually empty whitelist means no filtering restrictions (allow all) OR allow nothing.
    # Given the previous behavior was "allow all", [] likely means "allow all" to maintain compatibility?
    # Or we need a way to distinguish "no whitelist provided" vs "empty whitelist".
    # The function signature has default `[]`.
    # README says: "If a field in the filter is not found in the whitelist, an error is returned."
    # This implies if you pass a whitelist, it enforces it.
    # But if default is passed, we shouldn't break existing calls.
    # Let's assume if whitelist is explicitly provided as non-empty, we check.
    # What if I want to block everything? Pass specific flag?
    # Let's treat `[]` as "no whitelist, allow all".

    filter = %{combinator: :and, rules: [%{field: "name", operator: "=", value: "Mihai"}]}

    # Default: allow all
    assert {:ok, _} = Manole.build_query(Person, filter, [])
  end
end
