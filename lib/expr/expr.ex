defmodule Manole.Expr do
  @moduledoc """
  Filter expressions, which can be either a `Rule` or a `Group`.
  A group has rules and other groups as children, and a combinator
  to join them with (one of `and`, `or`).

  Groups and rules are vertices in the filter's AST representation.
  """

  defmodule Rule do
    @moduledoc false
    @enforce_keys ~w(field operator value)a
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            field: String.t(),
            operator: String.t(),
            value: any()
          }

    @operators %{
      "=" => "==",
      "==" => "==",
      "eq" => "==",
      :eq => "==",
      "!=" => "!=",
      "neq" => "!=",
      :neq => "!=",
      ">" => ">",
      "gt" => ">",
      :gt => ">",
      ">=" => ">=",
      "gte" => ">=",
      :gte => ">=",
      "<" => "<",
      "lt" => "<",
      :lt => "<",
      "<=" => "<=",
      "lte" => "<=",
      :lte => "<=",
      "contains" => "contains"
    }

    def lookup_operator(operator, operators \\ @operators) do
      Map.get(operators, operator)
    end
  end

  defimpl Inspect, for: Rule do
    def inspect(rule, _opts) do
      "Rule <#{rule.field}#{rule.operator}#{rule.value}>"
    end
  end

  defmodule Group do
    @moduledoc false
    @enforce_keys ~w(combinator children)a
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            combinator: atom(),
            children: [Manole.Expr.Rule.t() | t()]
          }
  end

  defimpl Inspect, for: Group do
    def inspect(group, _opts) do
      "Group <#{group.combinator}, children: #{length(group.children)}>"
    end
  end
end
