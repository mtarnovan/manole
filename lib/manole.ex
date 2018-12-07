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

  @spec build_query(Ecto.Queryable.t(), map(), [atom()]) ::
          Ecto.Queryable.t() | {:error, :not_allowed} | {:error, :invalid_filter}

  def build_query(queryable, filter, _whitelist \\ []) do
    dynamic =
      filter
      |> build_graph()
      |> EctoBuilder.append_filter(queryable)

    from(queryable, where: ^dynamic)
  end

  def build_graph(filter) do
    parse_filter(Graph.new(type: :directed), filter)
  end

  defp parse_filter(g, group = %{rules: rules}) do
    group = struct(G, Map.put(group, :id, next_id(g)))
    g = Graph.add_vertex(g, group)
    parse_rules(g, rules, group)
  end

  defp parse_rules(g, [h | t], parent = %G{}) do
    g = add_vertex(g, h, parent)
    parse_rules(g, t, parent)
  end

  defp parse_rules(g, [], _), do: g

  defp add_vertex(g, rule = %{field: _, operator: _, value: _}, parent) do
    rule = struct(R, Map.put(rule, :id, next_id(g)))

    g
    |> Graph.add_vertex(rule)
    |> Graph.add_edge(rule, parent)
  end

  defp add_vertex(g, group = %{rules: rules}, parent) do
    group = struct(G, Map.put(group, :id, next_id(g)))

    g
    |> Graph.add_vertex(group)
    |> Graph.add_edge(group, parent)
    |> parse_rules(rules, group)
  end

  defp next_id(g) do
    length(Graph.vertices(g)) + 1
  end
end
