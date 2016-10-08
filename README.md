# Grapple
> :green_apple: Webhook magic in Elixir

[![CircleCI](https://circleci.com/gh/camirmas/grapple/tree/master.svg?style=shield)](https://circleci.com/gh/camirmas/grapple/tree/master)

Grapple defines a simple API for hookable actions that broadcast updates to subscribers over HTTP.

This API lends itself nicely to Webhooks, REST Hooks, Server Push, and more!

## Installation

1. Add `grapple` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:grapple, "~> 0.2.0"}]
  end
  ```

2. Ensure `grapple` is started before your application:

  ```elixir
  def application do
    [applications: [:grapple]]
  end
  ```

## Running

```bash
iex -S mix
```

## Documentation
https://hexdocs.pm/grapple/0.2.0

---

## Usage

### Direct

The default struct, `%Grapple.Hook{}`, has the following fields:

- `topic`
- `url`,
- `owner`
- `life`
- `ref`
- `method`
- `headers`
- `body`
- `query`

Note that `topic` and `url` are **required**. _TODO: make this configurable._

**Subscribing**

To subscribe to a webhook, pass a `Hook` to the `subscribe` function, which returns the topic name and the unique refernce to that particular hook:
```elixir
hook = %Grapple.Hook{topic: "pokemon", url: "http://pokeapi.co/api/v2/pokemon/149"}
{topic, ref} = Grapple.Hook.subscribe(hook)
```
It's important that topics are unique across your application's modules (and `topicof` ensures this) because it makes implementing higher-level features, such as [REST Hooks](http://resthooks.org), much easier.

**Publishing**

To broadcast a webhook, pass a `topic`, and optionally arbitrary `data`.
This will trigger HTTP requests for any stored hooks (and their subscribers) whose `topic` values match the given `topic`, and return the parsed responses.
```elixir
# this will send hooks with their default `body`
[response] = Grapple.Hook.broadcast("pokemon")

# you can also pass arbitrary data that will be sent instead
[response] = Grapple.Hook.broadcast("pokemon", data)
```

Responses will take one of the following forms:
```elixir
# on success
{:success, body: body} = response

# on 404
:not_found = response

# on error
{:error, reason: reason} = response
```

### Macro

Broadcasting can also be done via a macro, `defhook`.

The macro defines a named method in the lexical module. When invoked, the method's name will be used in the topic (takes the form "#{__MODULE__}.#{name}").

The result will be broadcasted as the `body` to any hook requests on that topic, unless it returns `nil`, in which case hooks will be sent with default `body`.

The following example implements a hook that determines the game profile for Dragonite, automatically sending updates to the `http://pokeapi.co` API:

```elixir
hook = %Grapple.Hook{topic: "Pokemon.dragonite", url: "http://pokeapi.co/api/v2/pokemon/149"}

defmodule Pokemon do
  use Grapple.Hook

  # add some logic (like define Dragonite's profile) and return a body or return nil
  defhook dragonite do
    %{name: :dragonite, nature: :adamant, ivs: %{health: 32, speed: 32, attack: 32, defense: 32, speca: 32, specd: 32}}
  end
end
```

You should try to ensure that your hook method doesn't get called excessively since it's highly unlikely that subscribers will want to be repeatedly hit. This certainly depends on your own unique needs, but it's good to keep this fact in mind.

Work is currently being done to ensure that redundant broadcasts are not sent and that the individual subscription broadcasts are parallelized.

### Plug

Finally, broadcasting can be done with `Grapple.Plug`. Here's an example from a Phoenix Controller:

```elixir
defmodule Pokedex.PokemonController do
  use Pokedex.Web, :controller

  plug Grapple.Plug, [topic: "pokemon"] when action in [:get]

  def get(conn, _opts) do
    conn
  end
end
```

## License

MIT
