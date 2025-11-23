defmodule Manole do
  @external_resource "README.md"
  @moduledoc File.read!("README.md")
             |> String.split("<!-- MDOC -->")
             |> Enum.at(1)
             |> String.trim()

  alias Manole.Builder.Ecto, as: EctoBuilder
  alias Manole.Expr.Group, as: G
  alias Manole.Expr.Rule, as: R

  import Ecto.Query, only: [from: 2]

  @spec build_query(Ecto.Queryable.t(), map(), keyword()) ::
          {:ok, Ecto.Query.t()} | {:error, term()}

  def build_query(queryable, filter, opts \\ []) do
    with {:ok, tree} <- parse_filter(filter),
         :ok <- validate_allowlist(tree, opts) do
      query = EctoBuilder.prepare_joins(queryable, tree)
      dynamic = EctoBuilder.build_dynamic(tree, query) || true
      {:ok, from(query, where: ^dynamic)}
    end
  end

  defp validate_allowlist(tree, opts) do
    allowlist = Keyword.get(opts, :allowlist)

    if is_nil(allowlist) do
      :ok
    else
      validate_tree_against_allowlist(tree, allowlist)
    end
  end

  defp validate_tree_against_allowlist(_tree, []),
    do: {:error, "Field access denied (empty allowlist)"}

  defp validate_tree_against_allowlist(%G{children: children}, allowlist) do
    Enum.reduce_while(children, :ok, fn
      %G{} = group, :ok ->
        case validate_tree_against_allowlist(group, allowlist) do
          :ok -> {:cont, :ok}
          error -> {:halt, error}
        end

      %R{field: field}, :ok ->
        if field_allowed?(field, allowlist) do
          {:cont, :ok}
        else
          {:halt, {:error, "Field '#{field}' is not in allowlist"}}
        end
    end)
  end

  defp field_allowed?(field, allowlist) do
    parts = String.split(field, ".")
    check_field_path(parts, allowlist)
  end

  defp check_field_path([field], allowlist) do
    Enum.find(allowlist, fn item ->
      case item do
        {key, _} -> Atom.to_string(key) == field
        key when is_atom(key) -> Atom.to_string(key) == field
        _ -> false
      end
    end) != nil
  end

  defp check_field_path([assoc | rest], allowlist) do
    matching_entry =
      Enum.find(allowlist, fn
        {key, _} -> Atom.to_string(key) == assoc
        _ -> false
      end)

    case matching_entry do
      {_key, sub_allowlist} when is_list(sub_allowlist) ->
        check_field_path(rest, sub_allowlist)

      _ ->
        false
    end
  end

  def parse_filter(filter) when is_map(filter) do
    rules = Map.get(filter, :rules) || Map.get(filter, "rules")
    combinator = Map.get(filter, :combinator) || Map.get(filter, "combinator")

    case {rules, combinator} do
      {rules, combinator} when is_list(rules) and not is_nil(combinator) ->
        with {:ok, combinator_atom} <- validate_combinator(combinator),
             {:ok, children} <- parse_children(rules) do
          {:ok, %G{combinator: combinator_atom, children: children}}
        end

      _ ->
        {:error, "Filter must be a map with 'rules' list and 'combinator'"}
    end
  end

  def parse_filter(_), do: {:error, "Filter must be a map"}

  defp parse_children(rules) do
    parsed =
      Enum.reduce_while(rules, {:ok, []}, fn rule, {:ok, acc} ->
        case parse_child(rule) do
          {:ok, parsed} -> {:cont, {:ok, [parsed | acc]}}
          error -> {:halt, error}
        end
      end)

    with {:ok, list} <- parsed, do: {:ok, Enum.reverse(list)}
  end

  defp parse_child(%{} = group) do
    if Map.get(group, :rules) || Map.get(group, "rules") do
      parse_filter(group)
    else
      parse_rule(group)
    end
  end

  defp parse_rule(rule) do
    with {:ok, field} <- validate_required(rule, :field),
         {:ok, operator} <- validate_required(rule, :operator),
         {:ok, value} <- validate_required(rule, :value),
         :ok <- validate_operator(operator) do
      {:ok, %R{field: field, operator: operator, value: value}}
    end
  end

  defp validate_operator(op) do
    if R.lookup_operator(op) do
      :ok
    else
      {:error, "Invalid operator: #{inspect(op)}"}
    end
  end

  defp validate_combinator(val) when val in ["and", :and], do: {:ok, :and}
  defp validate_combinator(val) when val in ["or", :or], do: {:ok, :or}
  defp validate_combinator(val), do: {:error, "Invalid combinator: #{inspect(val)}"}

  defp validate_required(map, key) do
    case Map.get(map, key) || Map.get(map, Atom.to_string(key)) do
      nil -> {:error, "Missing required key: #{key}"}
      val -> {:ok, val}
    end
  end
end
