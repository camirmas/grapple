defmodule Grapple do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Grapple.Supervisor.start_link []
  end

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

  def subscribe(topic, webhook = %Grapple.Hook{}) when is_atom(topic) do
    Grapple.Server.subscribe(topic, webhook)
  end
end
