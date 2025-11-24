defmodule ManoleParsingTest do
  use Manole.DataCase, async: true
  alias Manole.Builder.Ecto, as: EctoBuilder
  alias Manole.Expr.{Group, Rule}

  @filter1 %{
    combinator: :or,
    rules: [
      %{field: "name", operator: "=", value: "Alice"},
      %{
        combinator: :and,
        rules: [
          %{field: "name", operator: "=", value: "Bob"},
          %{field: "age", operator: ">", value: "30"},
          %{
            combinator: :and,
            rules: [
              %{field: "name", operator: "=", value: "Carol"},
              %{field: "age", operator: ">=", value: "30"}
            ]
          }
        ]
      }
    ]
  }

  test "parsing filter structure" do
    assert {:ok, tree} = Manole.parse_filter(@filter1)
    assert %Group{combinator: :or, children: children} = tree
    assert length(children) == 2

    # Check for rule
    assert Enum.any?(children, fn
             %Rule{field: "name", value: "Alice"} -> true
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
             %Rule{field: "name", value: "Bob"} -> true
             _ -> false
           end)
  end

  test "building dynamic query does not crash" do
    # We pass a dummy queryable because we just want to ensure the builder runs
    # In a real scenario Ecto would inspect the bindings
    assert {:ok, tree} = Manole.parse_filter(@filter1)
    dynamic = EctoBuilder.build_dynamic(tree, "people")
    assert %Ecto.Query.DynamicExpr{} = dynamic
  end
end
