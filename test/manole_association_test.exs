defmodule ManoleAssociationTest do
  use ExUnit.Case, async: true
  alias Ecto.Adapters.SQL.Sandbox
  alias Manole.{Factory, Person, Repo}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  defp setup_data do
    {p1, _d1, _t1} =
      Factory.insert_person_with_dog_and_toy(
        %{name: "Alice", age: 30},
        %{name: "Gigi"},
        %{name: "Ball", color: "pink"}
      )

    {_p2, _d2, _t2} =
      Factory.insert_person_with_dog_and_toy(
        %{name: "Bob", age: 30},
        %{name: "Rex"},
        %{name: "Bone", color: "blue"}
      )

    p1
  end

  test "filtering by associated field" do
    p1 = setup_data()

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

  test "filtering by nested associated field (person -> dogs -> toys)" do
    p1 = setup_data()

    # Filter person by dog's toy color
    filter = %{
      combinator: :and,
      rules: [
        %{field: "dogs.toys.color", operator: "=", value: "pink"}
      ]
    }

    {:ok, query} = Manole.build_query(Person, filter)
    results = Repo.all(query)

    assert length(results) == 1
    assert hd(results).id == p1.id
  end
end
