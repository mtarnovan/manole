defmodule Manole.Builder.Ecto do
  @moduledoc ~S"""
  Appends the graph represenation of a filter to an `Ecto.Queryable`
  """

  alias Manole.Expr.Group, as: G
  alias Manole.Expr.Rule, as: R

  import Manole.GraphHelpers, only: [reversed_groups: 1, parent: 2, rules: 2]
  import Ecto.Query

  @spec append_filter(Graph.t(), Ecto.Queryable.t()) :: String.t()
  def append_filter(g = %Graph{}, q) do
    g
    |> reversed_groups()
    |> Enum.reduce(nil, fn
      %G{} = group, dynamic ->
        combinator =
          case parent(g, group) do
            nil -> group.combinator
            parent_group -> parent_group.combinator
          end

        rules = rules(g, group)

        dynamic = dynamic || if combinator == :and, do: true, else: false

        case combinator do
          :and ->
            dynamic([q], ^combine_rules(q, group.combinator, rules) and ^dynamic)

          :or ->
            dynamic([q], ^combine_rules(q, group.combinator, rules) or ^dynamic)
        end
    end)
  end

  # credo:disable-for-lines:150 Credo.Check.Refactor.CyclomaticComplexity
  # credo:disable-for-lines:150 Credo.Check.Refactor.Nesting
  defp combine_rules(q, combinator, rules) do
    Enum.reduce(rules, nil, fn rule, dynamic ->
      field = String.to_existing_atom(rule.field)

      case combinator do
        :and ->
          case R.lookup_operator(rule.operator) do
            "==" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) == ^rule.value)
              else
                dynamic([q], ^dynamic and field(q, ^field) == ^rule.value)
              end

            "!=" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) != ^rule.value)
              else
                dynamic([q], ^dynamic and field(q, ^field) != ^rule.value)
              end

            ">" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) > ^rule.value)
              else
                dynamic([q], ^dynamic and field(q, ^field) > ^rule.value)
              end

            ">=" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) >= ^rule.value)
              else
                dynamic([q], ^dynamic and field(q, ^field) >= ^rule.value)
              end

            "<" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) < ^rule.value)
              else
                dynamic([q], ^dynamic and field(q, ^field) < ^rule.value)
              end

            "<=" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) <= ^rule.value)
              else
                dynamic([q], ^dynamic and field(q, ^field) <= ^rule.value)
              end
          end

        :or ->
          case R.lookup_operator(rule.operator) do
            "==" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) == ^rule.value)
              else
                dynamic([q], ^dynamic or field(q, ^field) == ^rule.value)
              end

            "!=" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) != ^rule.value)
              else
                dynamic([q], ^dynamic or field(q, ^field) != ^rule.value)
              end

            ">" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) > ^rule.value)
              else
                dynamic([q], ^dynamic or field(q, ^field) > ^rule.value)
              end

            ">=" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) >= ^rule.value)
              else
                dynamic([q], ^dynamic or field(q, ^field) >= ^rule.value)
              end

            "<" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) < ^rule.value)
              else
                dynamic([q], ^dynamic or field(q, ^field) < ^rule.value)
              end

            "<=" ->
              if is_nil(dynamic) do
                dynamic([q], field(q, ^field) <= ^rule.value)
              else
                dynamic([q], ^dynamic or field(q, ^field) <= ^rule.value)
              end
          end
      end
    end)
  end

  defp maybe_join(queryable, field) do
    if is_map(queryable) && Enum.any?(queryable.joins, &(&1.assoc |> elem(1) == field)) do
      queryable
    else
      queryable
      |> join(:inner, [q], assoc in assoc(q, ^field))
    end
  end
end
