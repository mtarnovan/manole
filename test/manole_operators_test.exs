defmodule ManoleOperatorsTest do
  use ExUnit.Case, async: true
  alias Ecto.Adapters.SQL.Sandbox
  alias Manole.{Person, Repo}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "operators" do
    # Setup data
    p1 = Repo.insert!(%Person{name: "Mihai", age: 10})
    p2 = Repo.insert!(%Person{name: "Paul", age: 20})
    p3 = Repo.insert!(%Person{name: "Adriana", age: 30})

    # 1. Equals (==)
    filter_eq = %{
      combinator: :and,
      rules: [%{field: "name", operator: "==", value: "Mihai"}]
    }

    assert [p1] == build_query!(Person, filter_eq) |> Repo.all()

    # 2. Not Equals (!=)
    filter_neq = %{
      combinator: :and,
      rules: [%{field: "name", operator: "!=", value: "Mihai"}]
    }

    # Order might vary, so sort by ID
    assert [p2, p3] ==
             build_query!(Person, filter_neq) |> Repo.all() |> Enum.sort_by(& &1.id)

    # 3. Greater Than (>)
    filter_gt = %{
      combinator: :and,
      rules: [%{field: "age", operator: ">", value: 20}]
    }

    assert [p3] == build_query!(Person, filter_gt) |> Repo.all()

    # 4. Greater Than Or Equal (>=)
    filter_gte = %{
      combinator: :and,
      rules: [%{field: "age", operator: ">=", value: 20}]
    }

    assert [p2, p3] ==
             build_query!(Person, filter_gte) |> Repo.all() |> Enum.sort_by(& &1.id)

    # 5. Less Than (<)
    filter_lt = %{
      combinator: :and,
      rules: [%{field: "age", operator: "<", value: 20}]
    }

    assert [p1] == build_query!(Person, filter_lt) |> Repo.all()

    # 6. Less Than Or Equal (<=)
    filter_lte = %{
      combinator: :and,
      rules: [%{field: "age", operator: "<=", value: 20}]
    }

    assert [p1, p2] ==
             build_query!(Person, filter_lte) |> Repo.all() |> Enum.sort_by(& &1.id)

    # 7. Contains (contains)
    filter_contains = %{
      combinator: :and,
      rules: [%{field: "name", operator: "contains", value: "au"}]
    }

    assert [p2] == build_query!(Person, filter_contains) |> Repo.all()
  end

  test "empty filter returns all" do
    p1 = Repo.insert!(%Person{name: "Mihai", age: 10})
    filter_empty = %{combinator: :and, rules: []}
    assert [p1] == build_query!(Person, filter_empty) |> Repo.all()
  end

  test "unknown field raises error" do
    Repo.insert!(%Person{name: "Mihai", age: 10})

    filter_unknown_field = %{
      combinator: :and,
      rules: [%{field: "non_existent_field", operator: "==", value: "Mihai"}]
    }

    assert_raise ArgumentError, ~r/does not exist in schema/, fn ->
      build_query!(Person, filter_unknown_field)
    end
  end

  defp build_query!(queryable, filter) do
    {:ok, query} = Manole.build_query(queryable, filter)
    query
  end
end
