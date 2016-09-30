# Grapple
> :green_apple: Webhook magic in Elixir

[![CircleCI](https://circleci.com/gh/camirmas/grapple/tree/master.svg?style=shield)](https://circleci.com/gh/camirmas/grapple/tree/master)

Grapple defines a simple API for hookable actions that broadcast updates to subscribers over HTTP.

This API lends itself nicely to Webhooks, REST Hooks, Server Push, and more!

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

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
    ``
## Running

```bash
iex -S mix
```

## Documentation
https://hexdocs.pm/grapple/0.1.0

---

### Usage

## Direct

The default struct, `%Grapple.Hook{}`, has the following fields: `topic`, `url`, `owner`, `life`, `ref`, `method`, `headers`, `body`, and `query`. Note that `topic` and `url` are **required**. _TODO: make this configurable._

To subscribe to a webhook, pass a `Hook` to the `subscribe` function, which returns the topic name and the unique refernce to that particular hook:
```elixir
hook = %Grapple.Hook{topic: "pokemon", url: "http://pokeapi.co/api/v2/pokemon/149"}
{topic, ref} = Grapple.Hook.subscribe(hook)
```

To broadcast a webhook, pass a `topic`, and optionally arbitrary `data`.
This will trigger HTTP requests for any stored hooks (and their subscribers) whose `topic` values match the given `topic`, and return the parsed responses.
```elixir
# this will send hooks with their default `body`
[response] = Grapple.Hook.broadcast("pokemon")

# can also pass arbitrary data that will be sent instead
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

## Macro

Broadcasting can also be done via a macro, `defhook`.

It defines a method in the lexical module. When invoked, the method's name will be used in the topic (takes the form "#{__MODULE__}.#{name}").

The result will be broadcasted as the `body` to any hook requests on that topic, unless it returns `nil`, in which case hooks will be sent with default `body`.

The following example implements a hook that creates a game profile for Dragonite (Nature, Types, Stats, etc.), automatically sending updates to the `http://pokeapi.co` API:

```elixir
hook = %Grapple.Hook{topic: "Pokemon.dragonite", url: "http://pokeapi.co/api/v2/pokemon/149"}

defmodule Pokemon do
  use Grapple.Hook

  # in this case, no body needed
  defhook dragonite do
    # add some logic (like define Dragonite's profile) and return a body or return nil
    nil
  end
end
```

## Plug

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
