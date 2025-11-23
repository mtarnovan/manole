defmodule Manole.Builder.Ecto do
  @moduledoc ~S"""
  Appends the filter structure to an `Ecto.Queryable`
  """

  alias Ecto.Queryable
  alias Manole.Expr.Group, as: G
  alias Manole.Expr.Rule, as: R
  import Ecto.Query

  @spec prepare_joins(Queryable.t(), G.t()) :: Ecto.Query.t()
  def prepare_joins(queryable, tree) do
    # 1. Extract all unique association paths from rules (e.g. ["comments", "comments.tags"])
    paths = extract_association_paths(tree)

    # 2. Iteratively join them if not present
    Enum.reduce(paths, Queryable.to_query(queryable), fn path_list, query ->
      join_association_path(query, path_list)
    end)
  end

  @spec build_dynamic(G.t(), Ecto.Query.t()) :: boolean() | Ecto.Query.dynamic_expr() | nil
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
    {binding_name, field_atom} = resolve_binding_and_field(q, rule.field)
    op = R.lookup_operator(rule.operator)

    if binding_name == :root do
      build_root_dynamic(q, field_atom, op, rule.value)
    else
      build_binding_dynamic(binding_name, field_atom, op, rule.value)
    end
  end

  defp build_root_dynamic(_q, field, op, value) do
    case op do
      "==" -> dynamic([q], field(q, ^field) == ^value)
      "!=" -> dynamic([q], field(q, ^field) != ^value)
      ">" -> dynamic([q], field(q, ^field) > ^value)
      ">=" -> dynamic([q], field(q, ^field) >= ^value)
      "<" -> dynamic([q], field(q, ^field) < ^value)
      "<=" -> dynamic([q], field(q, ^field) <= ^value)
      "contains" -> dynamic([q], ilike(field(q, ^field), ^"%#{escape_like(value)}%"))
      _ -> nil
    end
  end

  defp build_binding_dynamic(binding_name, field, op, value) do
    case op do
      "==" ->
        dynamic([], field(as(^binding_name), ^field) == ^value)

      "!=" ->
        dynamic([], field(as(^binding_name), ^field) != ^value)

      ">" ->
        dynamic([], field(as(^binding_name), ^field) > ^value)

      ">=" ->
        dynamic([], field(as(^binding_name), ^field) >= ^value)

      "<" ->
        dynamic([], field(as(^binding_name), ^field) < ^value)

      "<=" ->
        dynamic([], field(as(^binding_name), ^field) <= ^value)

      "contains" ->
        dynamic([], ilike(field(as(^binding_name), ^field), ^"%#{escape_like(value)}%"))

      _ ->
        nil
    end
  end

  defp escape_like(value) do
    value
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end

  defp extract_association_paths(%G{children: children}) do
    Enum.flat_map(children, fn
      %G{} = group ->
        extract_association_paths(group)

      %R{field: field} ->
        case String.split(field, ".") do
          # Root field
          [_] -> []
          # Return path components excluding field name
          parts -> [List.delete_at(parts, length(parts) - 1)]
        end
    end)
    |> Enum.uniq()
    # Sort by length so we join parent associations before children (e.g. "comments" before "comments.tags")
    |> Enum.sort_by(&length/1)
  end

  defp join_association_path(query, path_list) do
    # path_list: ["comments", "tags"]
    path_list
    |> Enum.reduce({[], query}, &join_part/2)
    |> elem(1)
  end

  defp join_part(part, {path_so_far, q}) do
    current_path = path_so_far ++ [part]
    binding_name = path_to_binding(current_path)

    if has_named_binding?(q, binding_name) do
      {current_path, q}
    else
      q_new = perform_join(q, path_so_far, part, binding_name)
      {current_path, q_new}
    end
  end

  defp perform_join(q, [], part, binding_name) do
    schema = get_schema(q)
    assoc_atom = validate_association!(schema, part)
    join(q, :inner, [root], assoc(root, ^assoc_atom), as: ^binding_name)
  end

  defp perform_join(q, path_so_far, part, binding_name) do
    parent_binding_name = path_to_binding(path_so_far)
    schema = get_schema_for_binding(q, parent_binding_name)
    assoc_atom = validate_association!(schema, part)
    ix = find_binding_index!(q, parent_binding_name)
    join(q, :inner, [{parent, ix}], assoc(parent, ^assoc_atom), as: ^binding_name)
  end

  defp validate_association!(nil, assoc_str) do
    String.to_existing_atom(assoc_str)
  end

  defp validate_association!(schema, assoc_str) do
    case Enum.find(schema.__schema__(:associations), fn a -> Atom.to_string(a) == assoc_str end) do
      nil ->
        raise ArgumentError,
              "Association '#{assoc_str}' does not exist in schema #{inspect(schema)}"

      atom ->
        atom
    end
  end

  defp path_to_binding(path_list) do
    # Join with underscore to create unique binding name
    # e.g. ["comments", "tags"] -> :comments_tags
    Enum.join(path_list, "_") |> String.to_atom()
  end

  defp resolve_binding_and_field(q, field_path) do
    parts = String.split(field_path, ".")

    case parts do
      [field] ->
        # Root schema
        schema = get_schema(q)
        field_atom = validate_field!(schema, field)
        {:root, field_atom}

      _ ->
        {path_parts, [field]} = Enum.split(parts, length(parts) - 1)
        binding_name = path_to_binding(path_parts)

        # We need the schema for this binding to validate the field
        # This is tricky. Ecto.Query doesn't easily expose schema of named bindings without digging.
        # But `field` macro allows generic atom.
        # For improved validation, we should ideally inspect the joined schema.
        # But `q` has the structure.

        # Let's trust Ecto's runtime check for the field on the binding?
        # The user wanted schema reflection.
        # We can find the schema from the named binding in the query?
        # `q.aliases` maps alias to index. `q.joins` has the joins.
        # This is getting complex for reflection.

        # Strategy:
        # 1. Use `to_existing_atom` for field name (safe-ish if it's a known field).
        # 2. Or try to resolve schema.

        # Let's resolve schema from query joins if possible.
        schema = get_schema_for_binding(q, binding_name)
        field_atom = validate_field!(schema, field)

        {binding_name, field_atom}
    end
  end

  defp validate_field!(nil, field_str) do
    String.to_existing_atom(field_str)
  end

  defp validate_field!(schema, field_str) do
    case Enum.find(schema.__schema__(:fields), fn f -> Atom.to_string(f) == field_str end) do
      nil ->
        raise ArgumentError, "Field '#{field_str}' does not exist in schema #{inspect(schema)}"

      atom ->
        atom
    end
  end

  defp get_schema(%Ecto.Query{from: %{source: {_table, schema}}}), do: schema
  defp get_schema(queryable) when is_atom(queryable), do: queryable
  defp get_schema(_), do: nil

  defp get_schema_for_binding(query, binding_name) do
    # Reverse lookup binding -> schema is hard in pure Ecto public API without traversing joins.
    # However, since we JUST built the query, we know the joins.
    # But we are inside build_rule_dynamic which takes `q`.

    # Iterating joins to find the one with `as: binding_name`
    # query.joins is a list of Ecto.Query.JoinExpr

    Enum.find_value(query.joins, fn
      %{as: ^binding_name, source: {_table, schema}} -> schema
      _ -> nil
    end)
  end

  defp find_binding_index!(query, binding_name) do
    case Map.get(query.aliases, binding_name) do
      nil ->
        raise "Binding #{inspect(binding_name)} not found in aliases: #{inspect(query.aliases)}"

      ix ->
        ix
    end
  end
end
