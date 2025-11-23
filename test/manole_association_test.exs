defmodule ManoleAssociationTest do
  use ExUnit.Case, async: true
  alias Ecto.Adapters.SQL.Sandbox
  alias Manole.{Dog, Person, Repo, Toy}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "filtering by associated field" do
    # Setup data
    p1 = Repo.insert!(%Person{name: "Alice", age: 30})
    d1 = Repo.insert!(%Dog{name: "Gigi", person_id: p1.id})
    _t1 = Repo.insert!(%Toy{name: "Ball", color: "pink", dog_id: d1.id})

    p2 = Repo.insert!(%Person{name: "Bob", age: 30})
    d2 = Repo.insert!(%Dog{name: "Rex", person_id: p2.id})
    _t2 = Repo.insert!(%Toy{name: "Bone", color: "white", dog_id: d2.id})

    # Filter person by dog name
    filter = %{
      combinator: :and,
      rules: [
        %{field: "dogs.name", operator: "=", value: "Gigi"}
      ]
    }

    {:ok, query} = Manole.build_query(Person, filter)
    results = Repo.all(query)

    assert length(results) == 1
    assert hd(results).id == p1.id
  end
end
