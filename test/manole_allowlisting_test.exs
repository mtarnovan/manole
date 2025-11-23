defmodule ManoleAllowlistingTest do
  use Manole.DataCase, async: true
  alias Manole.{Dog, Person}

  test "default allows everything (nil allowlist)" do
    Repo.insert!(%Person{name: "Alice", age: 30})
    filter = %{combinator: :and, rules: [%{field: "name", operator: "=", value: "Alice"}]}

    # No options provided -> allows all
    assert {:ok, query} = Manole.build_query(Person, filter)
    assert Repo.aggregate(query, :count, :id) == 1
  end

  test "allows fields in explicit allowlist" do
    Repo.insert!(%Person{name: "Alice", age: 30})
    filter = %{combinator: :and, rules: [%{field: "name", operator: "=", value: "Alice"}]}

    opts = [allowlist: [:name]]
    assert {:ok, query} = Manole.build_query(Person, filter, opts)
    assert Repo.aggregate(query, :count, :id) == 1
  end

  test "blocks fields not in allowlist" do
    filter = %{combinator: :and, rules: [%{field: "age", operator: ">", value: "20"}]}
    # 'age' is missing
    opts = [allowlist: [:name]]

    assert {:error, "Field 'age' is not in allowlist"} = Manole.build_query(Person, filter, opts)
  end

  test "allows nested fields in allowlist" do
    p1 = Repo.insert!(%Person{name: "Alice", age: 30})
    Repo.insert!(%Dog{name: "Gigi", person_id: p1.id})

    filter = %{combinator: :and, rules: [%{field: "dogs.name", operator: "=", value: "Gigi"}]}
    opts = [allowlist: [dogs: [:name]]]

    assert {:ok, query} = Manole.build_query(Person, filter, opts)
    assert Repo.aggregate(query, :count, :id) == 1
  end

  test "blocks nested fields not in allowlist" do
    filter = %{combinator: :and, rules: [%{field: "dogs.age", operator: ">", value: "5"}]}
    # 'dogs.age' is missing
    opts = [allowlist: [dogs: [:name]]]

    assert {:error, "Field 'dogs.age' is not in allowlist"} =
             Manole.build_query(Person, filter, opts)
  end

  test "empty allowlist allows NOTHING" do
    filter = %{combinator: :and, rules: [%{field: "name", operator: "=", value: "Alice"}]}

    # Empty list provided -> Strict mode, allow nothing
    assert {:error, "Field access denied (empty allowlist)"} =
             Manole.build_query(Person, filter, allowlist: [])
  end
end
