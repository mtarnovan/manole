defmodule ManoleParsingTest do
  use ExUnit.Case
  alias Ecto.Query.DynamicExpr
  alias Manole.Expr.{Group, Rule}

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

  test "parsing filter structure" do
    tree = Manole.parse_filter(@filter1)
    assert %Group{combinator: :or, children: children} = tree
    assert length(children) == 2

    # Check for rule
    assert Enum.any?(children, fn
             %Rule{field: "name", value: "Mihai"} -> true
             _ -> false
           end)

    # Check for nested group
    nested_group =
      Enum.find(children, fn
        %Group{} -> true
        _ -> false
      end)

    assert nested_group
    assert nested_group.combinator == :and
    assert length(nested_group.children) == 3

    # Check nested group children
    assert Enum.any?(nested_group.children, fn
             %Rule{field: "name", value: "Paul"} -> true
             _ -> false
           end)
  end

  test "building dynamic query does not crash" do
    alias Manole.Builder.Ecto
    # We pass a dummy queryable because we just want to ensure the builder runs
    # In a real scenario Ecto would inspect the bindings
    dynamic = Ecto.build_dynamic(Manole.parse_filter(@filter1), "people")
    assert %DynamicExpr{} = dynamic
  end
end
