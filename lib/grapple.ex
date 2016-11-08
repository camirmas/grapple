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

  def get_hooks(topic) when is_atom(topic) do
    Grapple.Server.get_hooks(topic)
  end

  def get_responses(topic) when is_atom(topic) do
    Grapple.Server.get_responses(topic)
  end

  def remove_hook(topic, hook) when is_pid(hook) do
    Grapple.Server.remove_hook(topic, hook)
  end
end
