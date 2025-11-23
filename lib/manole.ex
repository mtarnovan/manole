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
      |> parse_filter()
      |> EctoBuilder.build_dynamic(queryable) || true

    from(queryable, where: ^dynamic)
  end

  def parse_filter(%{rules: rules, combinator: combinator}) do
    children = Enum.map(rules, &parse_child/1)
    %G{combinator: combinator, children: children}
  end

  defp parse_child(%{rules: _} = group), do: parse_filter(group)
  defp parse_child(rule), do: struct(R, rule)
end
