defmodule Grapple.HookServer do
  use GenServer

  @backend Application.get_env(:grapple, :backend) || Grapple.Ets

  # API

  def start_link(topic, hook_sup) do
    GenServer.start_link(__MODULE__, [topic, hook_sup], name: topic)
  end

  @doc """
  Subscribes a Webhook on the given topic. Adds to the list, and returns the
  pid of that Webhook.
  """
  def subscribe(topic, webhook) do
    GenServer.call(topic, {:subscribe, webhook})
  end

  # Callbacks

  def init([topic, hook_sup]) do
    {:ok, store_pid} = @backend.start_link(topic)
    hook_pids = @backend.all(store_pid)
    state = %{store_pid: store_pid, hook_pids: hook_pids, hook_sup: hook_sup}
    {:ok, state}
  end

  def handle_call({:subscribe, webhook}, _from, %{hook_pids: hook_pids,
    hook_sup: hook_sup} = state) do
      {:ok, pid} = Supervisor.start_child(hook_sup, [webhook])
      {:reply, pid, %{state | hook_pids: [pid | hook_pids]}}
  end
end
