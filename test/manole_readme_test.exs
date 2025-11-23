defmodule ManoleReadmeTest do
  use ExUnit.Case, async: true
  alias Ecto.Adapters.SQL.Sandbox
  alias Manole.{Person, Repo}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "README example: Basic filter works" do
    # Seed data
    Repo.insert!(%Person{name: "Alice", age: 30, income: 50_000})
    Repo.insert!(%Person{name: "Bob", age: 35, income: 60_000})
    Repo.insert!(%Person{name: "Carol", age: 25, income: 40_000})

    filter = %{
      combinator: :and,
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

    # Ensure it builds without error
    assert {:ok, query} = Manole.build_query(Person, filter)

    # Inspect SQL for README
    # {sql, params} = Repo.to_sql(:all, query)
    # IO.puts("\n--- SQL OUTPUT ---")
    # IO.puts(sql)
    # IO.inspect(params, label: "Params")
    # IO.puts("------------------\n")

    # Execute it
    # results = Repo.all(query)
    # IO.inspect(results, label: "Results")
    assert Repo.all(query) |> is_list()
  end
end
