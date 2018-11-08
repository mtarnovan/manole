defmodule Manole.Expr do
  @moduledoc """
  Filter expressions, which can be either a `Rule` or a `Group`.
  A group has rules and other groups as children, and a combinator
  to join them with (one of `and`, `or`).

  Groups and rules are vertices in the filter's AST representation.
  """

  defmodule Rule do
    @moduledoc false
    @enforce_keys ~w(field operator value id)a
    defstruct @enforce_keys

    @operators %{
      ["=", "==", "eq", :eq] => "==",
      ["!=", "neq", :neq] => "!=",
      [">", "gt", :gt] => ">",
      [">=", "gte", :gte] => ">=",
      ["<", "lt", :lt] => "<",
      ["<=", "lte", :lte] => "<=",
      ["contains"] => "contains"
    }

    def lookup_operator(operator, operators \\ @operators) do
      with {_k, v} <-
             Enum.find(operators, fn {k, _v} ->
               operator in k
             end) do
        v
      else
        nil -> nil
      end
    end
  end

  defimpl Inspect, for: Rule do
    def inspect(rule, _opts) do
      "Rule##{rule.id}< #{rule.field} #{rule.operator} #{rule.value} >"
    end
  end

  defmodule Group do
    @moduledoc false
    @enforce_keys ~w(combinator id)a
    defstruct @enforce_keys
  end

  defimpl Inspect, for: Group do
    def inspect(group, _opts) do
      "Group##{group.id}<#{group.combinator}>"
    end
  end
end
