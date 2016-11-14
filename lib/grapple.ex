defmodule Grapple do
  @moduledoc """
  This is the main module for Grapple. It defines the functions and macros that
  are available for adding, removing, and viewing topics and hooks, and
  broadcasting hooks.
  """

  use Application

  def start(_type, _args) do
    Grapple.Supervisor.start_link []
  end

  # Topics

  @doc """
  Adds a new topic. Topic must be an atom.

    ## Examples:
        iex> Grapple.add_topic(:pokemon)
        {:ok, %Grapple.Server.Topic{name: :pokemon, sup: #PID<0.242.0>}
  """
  def add_topic(topic) when is_atom(topic) do
    Grapple.Server.add_topic(topic)
  end

  @doc """
  Removes a topic.

  Returns `:ok`.
  """
  def remove_topic(topic) when is_atom(topic) do
    Grapple.Server.remove_topic(topic)
  end

  @doc """
  Lists all topics.

    ## Examples:
        iex> Grapple.add_topic(:pokemon)
        {:ok, %Grapple.Server.Topic{name: :pokemon, sup: #PID<0.242.0>}
        iex> Grapple.add_topic(:gyms)
        {:ok, %Grapple.Server.Topic{name: :gyms, sup: #PID<0.258.0>}
        iex> Grapple.get_topics
        [%Grapple.Server.Topic{name: :gyms, sup: #PID<0.258.0>,
        %Grapple.Server.Topic{name: :pokemon, sup: #PID<0.242.0>]
  """
  def get_topics do
    Grapple.Server.get_topics
  end

  @doc """
  Clears all topics.

  Returns `:ok`.
  """
  def clear_topics do
    Grapple.Server.clear_topics
  end

  # Hooks

  @doc """
  Subscribes a hook to a topic. The first argument must be an atom
  representing an existing topic and the second must be a valid `Hook`
  struct.

  Returns the `pid` of the Hook process that was created.

    ## Examples:
        iex> Grapple.subscribe(:pokemon, %Grapple.Hook{url: "my-api-endpoint"})
        {:ok, #PID<0.277.0>}
  """
  def subscribe(topic, %Grapple.Hook{} = webhook) when is_atom(topic) do
    Grapple.Server.subscribe(topic, webhook)
  end

  @doc """
  Sends HTTP requests for all hooks subscribed to the given topic.

  Returns a list of hooks and their responses.

    ## Examples:
        iex> Grapple.broadcast(:pokemon)
        [%{hook: %Grapple.Hook{body: %{}, headers: [], life: nil, method: "GET",
            owner: nil, query: %{}, ref: nil, url: "my-api"},
           responses: [error: [reason: :nxdomain]]}]
  """
  def broadcast(topic) when is_atom(topic) do
    Grapple.Server.broadcast(topic)
  end

  @doc """
  Like broadcast/1, but will send all hooks for a topic with the given `body`
  instead of what was originally defined as the `body` on the `Hook`.
  """
  def broadcast(topic, body) when is_atom(topic) do
    Grapple.Server.broadcast(topic, body)
  end

  @doc """
  Returns a list of all hooks subscribed to a topic.

    ## Examples:
        iex> Grapple.get_hooks(:pokemon)
        [{#PID<0.277.0>,
          %Grapple.Hook{body: %{}, headers: [], life: nil, method: "GET", owner: nil,
           query: %{}, ref: nil, url: "my-api"}}]
  """
  def get_hooks(topic) when is_atom(topic) do
    Grapple.Server.get_hooks(topic)
  end

  @doc """
  Returns a list of responses for each hook on the given topic.

    ## Examples
        iex> Grapple.get_responses(:pokemon)
        [{#PID<0.277.0>,
          [success: [body: %{}]]}]
  """
  def get_responses(topic) when is_atom(topic) do
    Grapple.Server.get_responses(topic)
  end

  @doc """
  Removes a subscribed hook given a topic and the hook `pid`.

  Returns `:ok`.
  """
  def remove_hook(topic, hook) when is_pid(hook) do
    Grapple.Server.remove_hook(topic, hook)
  end

  # Macros

  @doc """
  Allows modules to `use` Grapple.Hook in them
  """
  defmacro __using__(_opts) do
    quote do
      import Grapple
    end
  end

  @doc """
  Allows users to define hookable functions that automatically publish
  to subscribers whenever they are invoked.
  """
  defmacro defhook({name, _, _} = func, do: block) do
    quote do
      def unquote(func) do
        topic  = unquote name
        result = unquote block

        broadcast topic, result

        result
      end
    end
  end
end
