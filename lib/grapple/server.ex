defmodule Grapple.Server do
  use GenServer

  @backend Application.get_env(:grapple, :backend) || Grapple.Ets

  defmodule Topic do
    defstruct [:sup, :name,]
  end

  # API

  def start_link(topics_sup) do
    GenServer.start_link(__MODULE__, topics_sup, name: __MODULE__)
  end

  @doc """
  Adds a Topic, and returns the current list of topics.
  """
  def add_topic(topic) do
    GenServer.call(__MODULE__, {:add_topic, topic})
  end

  def remove_topic(topic) do
    GenServer.cast(__MODULE__, {:remove_topic, topic})
  end

  def clear_topics do
    GenServer.call(__MODULE__, :clear_topics)
  end

  @doc """
  Returns all topics.
  """
  def get_topics do
    GenServer.call(__MODULE__, :get_topics)
  end

  def subscribe(topic, webhook) do
    Grapple.HookServer.subscribe(topic, webhook)
  end

  # Callbacks

  def init(topics_sup) do
    {:ok, store_pid} = @backend.start_link(:topics)
    topics = @backend.all(store_pid)
    state = %{store_pid: store_pid, topics: topics, topics_sup: topics_sup}
    {:ok, state}
  end

  def handle_call({:add_topic, topic_name}, _from, %{topics_sup: topics_sup,
    topics: topics} = state) do
      topic = Enum.find(topics, fn topic -> topic.name == topic_name end)

      case topic do
        nil ->
          {:ok, sup} = Supervisor.start_child(topics_sup, [topic_name])
          new_topic = %Topic{sup: sup, name: topic_name}
          {:reply, new_topic, %{state | topics: [new_topic | topics]}}
        _ ->
          {:reply, topics, state}
      end
  end

  def handle_call(:get_topics, _from, %{topics: topics} = state) do
    {:reply, topics, state}
  end

  def handle_call(:clear_topics, _from, %{topics: topics,
    topics_sup: topics_sup} = state) do
      Enum.each(topics, &(Supervisor.terminate_child(topics_sup, &1.sup)))

      {:reply, :ok, %{state | topics: []}}
  end

  def handle_cast({:remove_topic, topic_name}, %{topics: topics,
    topics_sup: topics_sup} = state) do
      topic = Enum.find(topics, fn topic -> topic.name == topic_name end)

      case topic do
        nil ->
          {:noreply, state}
        %Topic{} ->
          Supervisor.terminate_child(topics_sup, topic.sup)
          new_topics = List.delete(topics, topic)
          {:noreply, %{state | topics: new_topics}}
      end
  end
end

