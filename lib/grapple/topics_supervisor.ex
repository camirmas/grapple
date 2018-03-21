defmodule Grapple.TopicsSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Grapple.TopicSupervisor

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(topic_name) do
    spec = %{id: TopicSupervisor, start: {TopicSupervisor, :start_link, [topic_name]}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def terminate_child(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
