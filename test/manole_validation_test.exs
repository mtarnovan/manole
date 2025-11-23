defmodule ManoleValidationTest do
  use ExUnit.Case, async: true
  alias Manole.Person

  test "validates missing keys" do
    # missing rules
    filter = %{combinator: :and}

    assert {:error, "Filter must be a map with 'rules' list and 'combinator'"} =
             Manole.build_query(Person, filter)
  end

  test "validates invalid combinator" do
    filter = %{combinator: :xor, rules: []}
    assert {:error, "Invalid combinator: :xor"} = Manole.build_query(Person, filter)
  end

  test "validates malformed rule" do
    filter = %{
      combinator: :and,
      rules: [
        # missing value
        %{field: "name", operator: "="}
      ]
    }

    assert {:error, "Missing required key: value"} = Manole.build_query(Person, filter)
  end

  test "validates malformed nested group" do
    filter = %{
      combinator: :and,
      rules: [
        %{
          # invalid nested combinator
          combinator: :bad,
          rules: []
        }
      ]
    }

    assert {:error, "Invalid combinator: :bad"} = Manole.build_query(Person, filter)
  end

  test "valid filter returns ok query" do
    filter = %{
      combinator: :and,
      rules: [
        %{field: "name", operator: "=", value: "Mihai"}
      ]
    }

    assert {:ok, %Ecto.Query{}} = Manole.build_query(Person, filter)
  end

  test "handles string keys in rules" do
    filter = %{
      combinator: :and,
      rules: [
        %{"field" => "name", "operator" => "=", "value" => "Mihai"}
      ]
    }

    assert {:ok, %Ecto.Query{}} = Manole.build_query(Person, filter)
  end
end
