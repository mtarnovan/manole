defmodule Manole.GraphHelpers do
  @moduledoc """
  Helpers for AST traversal.
  """

  alias Manole.Expr.{Group, Rule}

  @doc """
  Returns groups in reverse order of insertion.
  """
  def reversed_groups(g) do
    g
    |> Graph.vertices()
    |> Enum.filter(&match?(%Group{}, &1))
    |> Enum.sort(&(&1.id >= &2.id))
  end

  @doc """
  Returns the child groups of the given group.
  """
  def groups(g, group = %Group{}) do
    children(g, group)
    |> Enum.filter(&match?(%Group{}, &1))
  end

  @doc """
  Returns the child rules of the given group.
  """
  def rules(g, group = %Group{}) do
    children(g, group)
    |> Enum.filter(&match?(%Rule{}, &1))
  end

  @doc """
  Returns the parent of this vertex.
  """
  def parent(g, vertex) do
    Graph.out_edges(g, vertex)
    |> Enum.map(& &1.v2)
    |> Enum.filter(&match?(%Group{}, &1))
    |> List.first()
  end

  @doc """
  Returns the children of this vertex.
  """
  def children(g, vertex) do
    Graph.in_edges(g, vertex)
    |> Enum.map(& &1.v1)
    |> Enum.sort(&(&1.id <= &2.id))
  end

  @doc """
  Returns the sibling rules of this rule.
  """
  def sibling_rules(g, rule = %Rule{}) do
    List.delete(rules(g, parent(g, rule)), rule)
  end

  @doc """
  Returns the root of the AST
  """
  def root(g) do
    g
    |> Graph.vertices()
    |> Enum.find(&(&1.id === 1))
  end
end
