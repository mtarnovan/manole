defmodule ManoleTest do
  use ExUnit.Case
  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.SQL.Sandbox
  alias Manole.{Dog, Person, Repo, Toy}

  setup do
    Sandbox.checkout(Repo)
    SQL.query(Repo, "TRUNCATE TABLE people RESTART IDENTITY CASCADE", [])
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

  @filter4 %{
    combinator: :and,
    rules: [
      %{field: "age", operator: ">", value: "40"},
      %{
        combinator: :or,
        rules: [
          %{field: "name", operator: "=", value: "Paul"},
          %{field: "name", operator: "=", value: "Adriana"}
        ]
      }
    ]
  }

  test "Ecto query builder integration" do
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
    filter4_results = Manole.build_query(Person, @filter4) |> Repo.all()

    assert [p1, p2] == filter1_results
    assert [p1, p4] == filter2_results
    assert [p1, p2, p4, p5] == filter3_results

    assert [p4, p6] == filter4_results
  end
end
