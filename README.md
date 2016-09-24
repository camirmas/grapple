# Grapple
> Webhook magic in Elixir

[![CircleCI](https://circleci.com/gh/camirmas/grapple/tree/master.svg?style=shield)](https://circleci.com/gh/camirmas/grapple/tree/master)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `grapple` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:grapple, "~> 0.1.0"}]
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

<hr>

## Direct API Usage

The default struct, `%Grapple.Hook{}`, has the following fields: `topic`, `url`, `owner`, `life`, `ref`, `method`, `headers`, `body`, and `query`. Note that `topic` and `url` are **required**. _TODO: make this configurable.__

To subscribe to a webhook, pass a `Hook` to the `subscribe` function, which returns the topic name and the unique refernce to that particular hook:
```elixir
hook = %Grapple.Hook{topic: "pokemon", url: "http://pokeapi.co/api/v2/pokemon/149"}
{topic, ref} = Grapple.Hook.subscribe(hook)
```

To broadcast a webhook, pass a `topic` to `broadast`. This will trigger HTTP requests for any stored hooks whose `topic` values match the given `topic`, and return the parsed responses.
```elixir
Grapple.Hook.broadcast(topic)
```
