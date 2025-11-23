# Manole

Manole is a query builder for Ecto.

**N.B. This is a toy project, if you're looking for something viable take a
look at [Flop](https://github.com/woylie/flop).**

<!-- MDOC -->

Allows parsing of a filter and appending it to the given queryable.

A filter definition looks like this:

```elixir
filter = %{
  combinator: :or,
  rules: [
    %{field: "name", operator: "=", value: "Alice"},
    %{
      combinator: :or,
      rules: [
        %{field: "name", operator: "=", value: "Bob"},
        %{field: "age", operator: ">", value: "30"},
        %{combinator: :and,
          rules: [
            %{field: "name", operator: "=", value: "Carol"},
            %{field: "age", operator: "<", value: "27"},
            %{field: "income", operator: ">", value: "100000"},
          ]
        }
      ]
    }
  ]
}
```

Given this filter and the following data:

- Name: Alice, Age: 30, Income: 50000
- Name: Bob, Age: 35, Income: 60000
- Name: Carol, Age: 25, Income: 40000

```elixir
alias Manole.{Repo, Person}
Repo.insert!(%Person{name: "Alice", age: 30, income: 50000})
Repo.insert!(%Person{name: "Bob", age: 35, income: 60000})
Repo.insert!(%Manole.Person{name: "Carol", age: 25, income: 40000})
```

We can build an Ecto query from it:

```elixir
iex> {:ok, query} = Manole.build_query(Person, filter)
{:ok,
 #Ecto.Query<from p0 in Manole.Person,
  where: p0.name == ^"Alice" and
  (p0.name == ^"Bob" or p0.age > ^"30" or
     (p0.name == ^"Carol" and p0.age < ^"27" and p0.income > ^"100000"))>}
iex> Repo.all(query) |> Enum.map( &&1.name)
["Alice", "Bob"]
```

`Carol` is excluded because she does not match "Alice", "Bob", or "Age > 30",
and fails the income requirement (> 100000) of the nested AND block.

### Association Support

If a rule contains a field with dots, it is interpreted as an association. The
queryable is inspected to check if it already has a named binding for that join,
and if it doesn't, it is added automatically.

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

An allowlist is a list of fields to allow on the input queryable and the
associations. By default (if no allowlist is provided), all fields are allowed.
If an allowlist is provided, only fields in the list are accessible.

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

If a field in the filter is not found in the allowlist, `{:error, "Field '...'
is not in allowlist"}` is returned.

### Supported Operators

- `=`: Equal (`==`, `eq`)
- `!=`: Not Equal (`neq`)
- `>`: Greater Than (`gt`)
- `>=`: Greater Than or Equal (`gte`)
- `<`: Less Than (`lt`)
- `<=`: Less Than or Equal (`lte`)
- `contains`: Case-insensitive substring match (`ilike %value%`). Wildcards `%`
  and `_` in the value are escaped.

<!-- MDOC -->

# TODOs

- [x] implement allowlisting
- [x] add support for joins and querying on association
- [x] remove dependency on libgraph
- [ ] CI/CD Pipeline (GitHub Actions)
- [ ] Expanded Operator Support (`in`, `is_nil`)
- [ ] Test Coverage & Docs (`mix coveralls`, `ExDoc`)
