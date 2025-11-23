defmodule ManoleReadmeTest do
  use ExUnit.Case, async: true
  alias Ecto.Adapters.SQL.Sandbox
  alias Manole.{Person, Repo}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "README example: Basic filter works" do
    # Seed data as per user's updated README
    Repo.insert!(%Person{name: "Alice", age: 30, income: 50_000})
    Repo.insert!(%Person{name: "Bob", age: 35, income: 60_000})
    Repo.insert!(%Person{name: "Carol", age: 25, income: 40_000})

    # Filter from user's updated README
    filter = %{
      combinator: :or,
      rules: [
        %{field: "name", operator: "=", value: "Alice"},
        %{
          combinator: :or,
          rules: [
            %{field: "name", operator: "=", value: "Bob"},
            %{field: "age", operator: ">", value: "30"},
            %{combinator: :and,
              rules: [
                %{field: "name", operator: "=", value: "Carol"},
                %{field: "age", operator: "<", value: "27"},
                %{field: "income", operator: ">", value: "100000"},
              ]
            }
          ]
        }
      ]
    }

    # Ensure it builds without error
    assert {:ok, query} = Manole.build_query(Person, filter)

    # Inspect SQL for verification
    {sql, params} = Repo.to_sql(:all, query)
    IO.puts("\n--- SQL OUTPUT ---")
    IO.puts(sql)
    IO.inspect(params, label: "Params")
    IO.puts("------------------\n")

    # Execute it
    results = Repo.all(query)
    IO.inspect(results, label: "Results")

    # Verify results:
    # Logic: (Name="Alice") OR (
    #   (Name="Bob") OR (Age > 30) OR (
    #      (Name="Carol") AND (Age < 27) AND (Income > 100000)
    #   )
    # )
    #
    # 1. Alice: Matches Name="Alice" -> Included.
    # 2. Bob: Matches Name="Bob" (and Age > 30) -> Included.
    # 3. Carol:
    #    - Name="Alice"? No.
    #    - Inner OR group:
    #      - Name="Bob"? No.
    #      - Age > 30? No (25).
    #      - Inner AND group:
    #        - Name="Carol"? Yes.
    #        - Age < 27? Yes (25).
    #        - Income > 100000? No (40000).
    #    -> Carol fails all OR conditions -> Excluded.

    assert length(results) == 2
    names = Enum.map(results, & &1.name) |> Enum.sort()
    assert names == ["Alice", "Bob"]
  end
end
