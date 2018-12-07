# Manole

Manole is a query builder for Ecto.

__N.B. This project is in early/exploratory stages. Use with caution or not at all (for now).__

<!-- MDOC -->
Allows parsing of a filter and appending it to the given queryable.

A filter definition looks like this:

```elixir
filter = %{
  combinator: :and,
  rules: [
    %{field: "name", operator: "=", value: "Mihai"},
    %{
      combinator: :or,
      rules: [
        %{field: "name", operator: "=", value: "Paul"},
        %{field: "age", operator: ">", value: "30"},
        %{combinator: :and,
          rules: [
            %{field: "name", operator: "=", value: "Adriana"},
            %{field: "age", operator: "<", value: "27"},
            %{field: "income", operator: ">", value: "100000"},
          ]
        }
      ]
    }
  ]
}
```

Given a filter, we can build an Ecto query from it:

```elixir
iex(2)> Manole.build_query(Person, filter) |> Repo.all
...
SELECT p0."id", p0."name", p0."age", p0."income" FROM "people" AS p0 WHERE
((p0."name" = $1) AND (((p0."name" = $2) OR (p0."age" > $3)) AND ((((p0."name" = $4) AND (p0."age" < $5)) AND (p0."income" > $6)) OR $7))) ["Mihai", "Paul", 30, "Adriana", 27, 100000, false]
...
```

__What follows, is planned but not yet implemented__

If a rule contains a field with dots, it is interpreted as an association.
The queryable is inspected to check if it already has a named binding for that
join, and if it doesn't, it is added.

```elixir
%{
  combinator: :and,
  rules: [
    %{
      field: "comments.inserted_at",
      operator: ">",
      value: "2016-08-18T15:33:17"
    }
  ]
}
```
would result in something like this:

```sql
...inner join comments...where (comments.inserted_at > '2016-08-18T15:33:17')
```

A whitelist is a list of fields to allow on the input queryable and
the associations.

### Example:
Assuming the input queryable is a `Post`, a whitelist given as:
```elixir
[
  :title,
  comments: [:inserted_at, tags: [:name]]
]
```
this would allow filtering on `post.title`, `post.comments.inserted_at` and
`post.comments.tags.name`.

If a field in the filter is not found in the whitelist, an error is returned.
<!-- MDOC -->
# TODOs

- [ ] implement whitelisting
- [ ] add support for joins and querying on association
- [ ] remove dependency on libgraph
