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

  defp build_rule_dynamic(rule, q) do
    field = get_field_atom(q, rule.field)
    op = R.lookup_operator(rule.operator)

    case op do
      "==" -> dynamic([q], field(q, ^field) == ^rule.value)
      "!=" -> dynamic([q], field(q, ^field) != ^rule.value)
      ">" -> dynamic([q], field(q, ^field) > ^rule.value)
      ">=" -> dynamic([q], field(q, ^field) >= ^rule.value)
      "<" -> dynamic([q], field(q, ^field) < ^rule.value)
      "<=" -> dynamic([q], field(q, ^field) <= ^rule.value)
      "contains" -> dynamic([q], ilike(field(q, ^field), ^"%#{rule.value}%"))
      # Ignore unknown operators or handle error
      _ -> nil
    end
  end

  defp get_field_atom(q, field_str) do
    schema = get_schema(q)

    if schema do
      fields = schema.__schema__(:fields)

      case Enum.find(fields, fn f -> Atom.to_string(f) == field_str end) do
        nil -> raise ArgumentError, "Field '#{field_str}' does not exist in schema #{inspect(schema)}"
        atom -> atom
      end
    else
      # Fallback for queries where schema cannot be determined
      String.to_existing_atom(field_str)
    end
  end

  defp get_schema(%Ecto.Query{from: %{source: {_table, schema}}}), do: schema
  defp get_schema(queryable) when is_atom(queryable), do: queryable
  defp get_schema(_), do: nil
end
