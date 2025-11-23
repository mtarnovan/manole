defmodule Manole.Builder.Ecto do
  @moduledoc ~S"""
  Appends the filter structure to an `Ecto.Queryable`
  """

  alias Manole.Expr.Group, as: G
  alias Manole.Expr.Rule, as: R
  import Ecto.Query

  @spec build_dynamic(G.t(), Ecto.Queryable.t()) :: Ecto.Query.DynamicExpr.t() | nil
  def build_dynamic(%G{combinator: combinator, children: children}, q) do
    conditions =
      children
      |> Enum.map(fn
        %G{} = group -> build_dynamic(group, q)
        %R{} = rule -> build_rule_dynamic(rule, q)
      end)
      |> Enum.reject(&is_nil/1)

    case conditions do
      [] -> nil
      _ -> combine_conditions(combinator, conditions)
    end
  end

  defp combine_conditions(:and, conditions) do
    Enum.reduce(conditions, fn condition, acc ->
      dynamic(^acc and ^condition)
    end)
  end

  defp combine_conditions(:or, conditions) do
    Enum.reduce(conditions, fn condition, acc ->
      dynamic(^acc or ^condition)
    end)
  end

  defp build_rule_dynamic(rule, _q) do
    field = String.to_existing_atom(rule.field)
    op = R.lookup_operator(rule.operator)

    case op do
      "==" -> dynamic([q], field(q, ^field) == ^rule.value)
      "!=" -> dynamic([q], field(q, ^field) != ^rule.value)
      ">" -> dynamic([q], field(q, ^field) > ^rule.value)
      ">=" -> dynamic([q], field(q, ^field) >= ^rule.value)
      "<" -> dynamic([q], field(q, ^field) < ^rule.value)
      "<=" -> dynamic([q], field(q, ^field) <= ^rule.value)
      # Ignore unknown operators or handle error
      _ -> nil
    end
  rescue
    # Handle atom not existing or other errors gracefully
    _ -> nil
  end
end
