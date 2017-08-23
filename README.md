# Grapple
> :green_apple: Webhook magic in Elixir

[![Build Status](https://travis-ci.org/camirmas/grapple.svg?branch=master)](https://travis-ci.org/camirmas/grapple)

Grapple defines a simple API for hookable actions that broadcast updates to subscribers over HTTP.

This API lends itself nicely to Webhooks, REST Hooks, Server Push, and more!

## Installation

1. Add `grapple` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:grapple, "~> 1.2.1"}]
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
https://hexdocs.pm/grapple/1.2.1

---

## Usage

### Direct

The default struct, `%Grapple.Hook{}`, has the following fields:

- `url`
- `owner`
- `life`
- `ref`
- `method`
- `body`
- `headers`
- `options`
- `query`

Note that `url` is **required**. Additionally, the fields `body`, `headers`, and
`options` all correspond to those used in `HTTPoison` requests. See [HTTPoison](https://github.com/edgurgel/httpoiso://github.com/edgurgel/httpoison)
for more info.

**Topics**

To create a new topic, pass an atom to the `add_topic` function, which returns
a `Topic` struct.

```elixir
{:ok, topic = %Grapple.Server.Topic{}} = Grapple.add_topic(:pokemon)
```

**Subscribing**

To subscribe to a webhook, pass the topic name and a `Hook` to the `subscribe` function, which returns the topic name and the unique refernce to that particular hook:
```elixir
{:ok, pid} = Grapple.subscribe(:pokemon, %Grapple.Hook{url: "my-api"})
```

It's important that topics are unique across your application's modules (and `topicof` ensures this) because it makes implementing higher-level features, such as [REST Hooks](http://resthooks.org), much easier.

**Broadcasting**

To broadcast all webhooks for a given topic, pass a `topic` name, and optionally arbitrary `data`.
This will trigger HTTP requests for any stored hooks (and their subscribers) whose `topic` values match the given `topic`, and return the parsed responses.

```elixir
# this will send hooks with their default `body`
Grapple.broadcast(:pokemon)

# you can also pass arbitrary data that will be sent instead
Grapple.Hook.broadcast("pokemon", data)
```

Note that the call to `broadcast` does not actually return the responses. This is because
hooks run asynchronously. In order to retrieve responses, you can either ask for them explicitly:
```elixir
[{_pid, responses}] = Grapple.get_responses(:pokemon)
```

Or you can, when subscribing a `Hook`, set `:owner` to the pid of an existing
process that can receive a message when that `Hook` completes its `broadcast`.
The format of the message is `{:hook_response, hook_pid, response}`, with
`response` being a response from an `HTTPoison` request. See [HTTPoison](https://github.com/edgurgel/httpoiso://github.com/edgurgel/httpoison)
for more info. As an example, if your `:owner` process is a `GenServer`,
you would define a `handle_info` function like so:
```elixir
def handle_info({:hook_response, pid, response}, state) do
  # some logic
  {:noreply, state}
end
```

**Polling**

You can have individual hooks `broadcast` on an interval in two different ways.
The first is to include an `interval` field with an integer (in milliseconds)
when defining a `Hook`:
```elixir
Grapple.subscribe(:pokemon, %Grapple.Hook{url: "my-api", interval: 3000}
```

You can also take an existing hook that does not yet have an interval, and tell
it to start polling:
```elixir
{:ok, pid} = Grapple.subscribe(:pokemon, %Grapple.Hook{url: "my-api", interval: 3000}
Grapple.start_polling(pid, 3000)
```

To turn off polling for a particular hook:
```elixir
Grapple.stop_polling(pid)
```

To start polling for a particular hook, if it already has an `interval`:
```elixir
Grapple.start_polling(pid)
```

### Macro

Broadcasting can also be done via a macro, `defhook`. The macro defines a named
method in the lexical module. When invoked, the method's name will be used as the
topic, and if the method name matches an existing topic, all `Hook`s on that topic
will be `broadcast`. The result will be broadcast as the `body` to any hook requests
on that topic, unless it returns `nil`, in which case hooks will be sent with the
default `body`.

The following example implements a hook that determines the game profile for Dragonite,
automatically sending requests to the `http://pokeapi.co`:

```elixir
Grapple.subscribe(:pokemon, %Grapple.Hook{url: "http://pokeapi.co/api/v2/pokemon/149"})

defmodule Pokemon do
  use Grapple.Hook

  defhook dragonite do
    # add some logic and return a body or return nil
    # In this case, sends "GET" request to the `Hook` URL.
  end
end
```

You should try to ensure that your hook method doesn't get called excessively
since it's highly unlikely that subscribers will want to be repeatedly hit.
This certainly depends on your own unique needs, but it's good to keep this fact in mind.

## License

MIT
