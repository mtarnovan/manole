defmodule ManoleJsonInputTest do
  use ExUnit.Case, async: true
  alias Manole.Person

  test "handles string keys in top level filter" do
    filter = %{
      "combinator" => "and",
      "rules" => [
        %{"field" => "name", "operator" => "=", "value" => "Mihai"}
      ]
    }

    assert {:ok, %Ecto.Query{}} = Manole.build_query(Person, filter)
  end

  test "handles recursive string keys in nested groups" do
    filter = %{
      "combinator" => "or",
      "rules" => [
        %{
          "combinator" => "and",
          "rules" => [
            %{"field" => "name", "operator" => "=", "value" => "Paul"},
            %{"field" => "age", "operator" => ">", "value" => "30"}
          ]
        }
      ]
    }

    assert {:ok, %Ecto.Query{}} = Manole.build_query(Person, filter)
  end

  test "validates required keys in string-keyed maps" do
    filter = %{
      "combinator" => "and",
      "rules" => [
        %{"field" => "name", "operator" => "="} # missing value
      ]
    }

    assert {:error, "Missing required key: value"} = Manole.build_query(Person, filter)
  end

  test "handles mixed atom and string keys" do
    filter = %{
      combinator: :and,
      rules: [
        %{"field" => "name", "operator" => "=", value: "Mihai"},
        %{"value" => "20", field: "age", operator: ">"}
      ]
    }

    assert {:ok, %Ecto.Query{}} = Manole.build_query(Person, filter)
  end
end
