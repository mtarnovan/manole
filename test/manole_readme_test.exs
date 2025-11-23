defmodule ManoleReadmeTest do
  use Manole.DataCase, async: true
  alias Manole.Person

  test "README example: Basic filter works" do
    Repo.insert!(%Person{name: "Alice", age: 30, income: 50_000})
    Repo.insert!(%Person{name: "Bob", age: 35, income: 60_000})
    Repo.insert!(%Person{name: "Carol", age: 25, income: 40_000})

    filter = %{
      combinator: :or,
      rules: [
        %{field: "name", operator: "=", value: "Alice"},
        %{
          combinator: :or,
          rules: [
            %{field: "name", operator: "=", value: "Bob"},
            %{field: "age", operator: ">", value: "30"},
            %{
              combinator: :and,
              rules: [
                %{field: "name", operator: "=", value: "Carol"},
                %{field: "age", operator: "<", value: "27"},
                %{field: "income", operator: ">", value: "100000"}
              ]
            }
          ]
        }
      ]
    }

    assert {:ok, query} = Manole.build_query(Person, filter)

    {sql, params} = Repo.to_sql(:all, query)

    results = Repo.all(query)

    assert length(results) == 2
    names = Enum.map(results, & &1.name) |> Enum.sort()
    assert names == ["Alice", "Bob"]
  end
end
