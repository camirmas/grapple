defmodule Grapple.Server do
  @moduledoc false
  use GenServer

  defmodule Topic do
    defstruct [:sup, :name,]
  end

  alias Grapple.TopicsSupervisor

  # API

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def add_topic(topic) do
    GenServer.call(__MODULE__, {:add_topic, topic})
  end

  def remove_topic(topic) do
    GenServer.cast(__MODULE__, {:remove_topic, topic})
  end

  def clear_topics do
    GenServer.call(__MODULE__, :clear_topics)
  end

  def get_topics do
    GenServer.call(__MODULE__, :get_topics)
  end

  def subscribe(topic, hook) do
    Grapple.HookServer.subscribe(topic, hook)
  end

  def start_polling(hook_pid) do
    Grapple.Hook.start_polling(hook_pid)
  end

  def start_polling(hook_pid, interval) do
    Grapple.Hook.start_polling(hook_pid, interval)
  end

  def stop_polling(hook_pid) do
    Grapple.Hook.stop_polling(hook_pid)
  end

  def broadcast(topic) do
    Grapple.HookServer.broadcast(topic)
  end

  def broadcast(topic, body) do
    Grapple.HookServer.broadcast(topic, body)
  end

  def get_hooks(topic) do
    Grapple.HookServer.get_hooks(topic)
  end

  def get_responses(topic) do
    Grapple.HookServer.get_responses(topic)
  end

  def remove_hook(hook_pid) do
    if Process.alive?(hook_pid) do
      Process.exit(hook_pid, :kill)
    end
  end

  # Callbacks

  def init(:ok) do
    state = %{topics: []}
    {:ok, state}
  end

  def handle_call({:add_topic, topic_name}, _from, %{topics: topics} = state) do
      topic = Enum.find(topics, fn topic -> topic.name == topic_name end)

      case topic do
        nil ->
          {:ok, sup} = TopicsSupervisor.start_child(topic_name)
          new_topic = %Topic{sup: sup, name: topic_name}
          {:reply, {:ok, new_topic}, %{state | topics: [new_topic | topics]}}
        topic ->
          {:reply, {:ok, topic}, state}
      end
  end

  def handle_call(:get_topics, _from, %{topics: topics} = state) do
    {:reply, topics, state}
  end

  def handle_call(:clear_topics, _from, %{topics: topics} = state) do
      Enum.each(topics, &(TopicsSupervisor.terminate_child(&1.sup)))

      {:reply, :ok, %{state | topics: []}}
  end

  def handle_cast({:remove_topic, topic_name}, %{topics: topics} = state) do
      topic = Enum.find(topics, fn topic -> topic.name == topic_name end)

      case topic do
        nil ->
          {:noreply, state}
        %Topic{} ->
          TopicsSupervisor.terminate_child(topic.sup)
          new_topics = List.delete(topics, topic)
          {:noreply, %{state | topics: new_topics}}
      end
  end
end

