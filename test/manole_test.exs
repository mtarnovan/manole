defmodule ManoleTest do
  use ExUnit.Case
  alias Manole.{Dog, Person, Toy, Repo}
  alias Manole.Expr.{Group, Rule}

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Manole.Repo)
    Ecto.Adapters.SQL.query(Repo, "TRUNCATE TABLE people RESTART IDENTITY CASCADE", [])
    :ok
  end

  @filter1 %{
    combinator: :or,
    rules: [
      %{field: "name", operator: "=", value: "Mihai"},
      %{
        combinator: :and,
        rules: [
          %{field: "name", operator: "=", value: "Paul"},
          %{field: "age", operator: ">", value: "30"},
          %{
            combinator: :and,
            rules: [
              %{field: "name", operator: "=", value: "Adriana"},
              %{field: "age", operator: ">=", value: "30"}
            ]
          }
        ]
      }
    ]
  }

  @filter2 %{
    combinator: :or,
    rules: [
      %{
        combinator: :and,
        rules: [
          %{field: "age", operator: ">", value: "35"},
          %{field: "name", operator: "=", value: "Paul"}
        ]
      },
      %{
        combinator: :and,
        rules: [
          %{field: "age", operator: "<", value: "30"},
          %{field: "name", operator: "=", value: "Mihai"}
        ]
      }
    ]
  }

  @filter3 %{
    combinator: :or,
    rules: [
      %{field: "name", operator: "=", value: "Mihai"},
      %{
        combinator: :and,
        rules: [
          %{field: "name", operator: "=", value: "Paul"},
          %{field: "age", operator: ">", value: "30"}
        ]
      },
      %{
        combinator: :and,
        rules: [
          %{field: "name", operator: "=", value: "Adriana"},
          %{field: "age", operator: "<", value: "30"}
        ]
      }
    ]
  }

  test "graph traversal helpers" do
    import Manole.GraphHelpers

    g = Manole.build_graph(@filter1)
    group1 = %Group{id: 1, combinator: :or}
    group3 = %Group{id: 3, combinator: :and}
    rule4 = %Rule{id: 4, field: "name", operator: "=", value: "Paul"}
    rule5 = %Rule{id: 5, field: "age", operator: ">", value: "30"}
    rule7 = %Rule{id: 7, field: "name", operator: "=", value: "Adriana"}
    rule8 = %Rule{id: 8, field: "age", operator: ">=", value: "30"}
    root = root(g)

    assert root == group1
    assert inspect(group1) == "Group#1 <or>"
    assert groups(g, group1) == [group3]
    assert children(g, root) |> Enum.map(& &1.id) == [2, 3]
    assert sibling_rules(g, rule7) == [rule8]
    assert children(g, children(g, root) |> List.first()) == []
    assert parent(g, root) == nil
    assert parent(g, rule4) == group3
    assert inspect(rule4) == "Rule#4 <name=Paul>"
    assert parent(g, rule5) == group3
    assert parent(g, group3) == root
    assert rules(g, group3) == [rule4, rule5]
  end

  test "Ecto query builder" do
    p1 = Repo.insert!(%Person{name: "Mihai", age: 10})
    p2 = Repo.insert!(%Person{name: "Mihai", age: 50})
    _p3 = Repo.insert!(%Person{name: "Paul", age: 10})
    p4 = Repo.insert!(%Person{name: "Paul", age: 50})
    p5 = Repo.insert!(%Person{name: "Adriana", age: 10})
    p6 = Repo.insert!(%Person{name: "Adriana", age: 50})

    d1 = Repo.insert!(%Dog{name: "Gigi", person_id: p1.id})
    _t1 = Repo.insert!(%Toy{name: "Ball", color: "pink", dog_id: d1.id})

    filter1_results = Manole.build_query(Person, @filter1) |> Repo.all()
    filter2_results = Manole.build_query(Person, @filter2) |> Repo.all()
    filter3_results = Manole.build_query(Person, @filter3) |> Repo.all()

    assert [p1, p2, p4, p6] == filter1_results
    assert [p1, p4] == filter2_results
    assert [p1, p2, p4, p5] == filter3_results
  end
end
