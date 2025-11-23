# Manole

Manole is a query builder for Ecto.

__N.B. This project is in early/exploratory stages. Use with caution or not at all (for now).__

<!-- MDOC -->
Allows parsing of a filter and appending it to the given queryable.

A filter definition looks like this:

```elixir
filter = %{
  combinator: :or,
  rules: [
    %{field: "name", operator: "=", value: "Alice"},
    %{
      combinator: :and,
      rules: [
        %{field: "age", operator: ">", value: "20"},
        %{field: "income", operator: "<", value: "50000"}
      ]
    }
  ]
}
```

Given this filter and the following data:

* Name: Alice, Age: 30, Income: 50000
* Name: Bob, Age: 35, Income: 60000
* Name: Carol, Age: 25, Income: 40000

We can build an Ecto query from it:

```elixir
iex> Manole.build_query(Person, filter) |> Repo.all
...
SELECT p0."id", p0."name", p0."age", p0."income" FROM "people" AS p0 WHERE ((p0."name" = $1) OR ((p0."age" > $2) AND (p0."income" < $3))) ["Alice", 20, 50000]
...
```

### Association Support

If a rule contains a field with dots, it is interpreted as an association.
The queryable is inspected to check if it already has a named binding for that
join, and if it doesn't, it is added automatically.

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

### Allowlisting (Security)

An allowlist is a list of fields to allow on the input queryable and
the associations. By default (if no allowlist is provided), all fields are allowed. If an allowlist is provided, only fields in the list are accessible.

#### Example:
Assuming the input queryable is a `Post`, an allowlist given as:
```elixir
opts = [
  allowlist: [
    :title,
    comments: [:inserted_at, tags: [:name]]
  ]
]
Manole.build_query(Post, filter, opts)
```
this would allow filtering on `post.title`, `post.comments.inserted_at` and
`post.comments.tags.name`.

If a field in the filter is not found in the allowlist, `{:error, "Field '...' is not in allowlist"}` is returned.

### Supported Operators

- `=`: Equal (`==`, `eq`)
- `!=`: Not Equal (`neq`)
- `>`: Greater Than (`gt`)
- `>=`: Greater Than or Equal (`gte`)
- `<`: Less Than (`lt`)
- `<=`: Less Than or Equal (`lte`)
- `contains`: Case-insensitive substring match (`ilike %value%`). Wildcards `%` and `_` in the value are escaped.

<!-- MDOC -->
# TODOs

- [x] implement allowlisting
- [x] add support for joins and querying on association
- [x] remove dependency on libgraph

