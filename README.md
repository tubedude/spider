# Spider

Is a GraphQL client for Elixir largely dependent ton HTTPoison and Poison.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `spider` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:spider, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
query = """
{
  allCinemaDetails(before: "2017-10-04", after: "2010-01-01") {
    edges {
      node {
        slug
        hallName
      }
    }
  }
}
"""
request = %Spider.request{url:"https://etmdb.com/graphql", query: %{query: query}}
Spider.request(request)
{:ok, %{"allCinameDetails" => {"edges" => [...]}}}
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/spider](https://hexdocs.pm/spider).

