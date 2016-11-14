defmodule Grapple do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Grapple.Supervisor.start_link []
  end

  # Topics

  def add_topic(topic) when is_atom(topic) do
    Grapple.Server.add_topic(topic)
  end

  def remove_topic(topic) when is_atom(topic) do
    Grapple.Server.remove_topic(topic)
  end

  def get_topics do
    Grapple.Server.get_topics
  end

  def clear_topics do
    Grapple.Server.clear_topics
  end

  # Hooks

  def subscribe(topic, %Grapple.Hook{} = webhook) when is_atom(topic) do
    Grapple.Server.subscribe(topic, webhook)
  end

  def broadcast(topic) when is_atom(topic) do
    Grapple.Server.broadcast(topic)
  end

  def broadcast(topic, body) when is_atom(topic) do
    Grapple.Server.broadcast(topic, body)
  end

  def get_hooks(topic) when is_atom(topic) do
    Grapple.Server.get_hooks(topic)
  end

  def get_responses(topic) when is_atom(topic) do
    Grapple.Server.get_responses(topic)
  end

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
  to subscribers whenever they are invoked
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
