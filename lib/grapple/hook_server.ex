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

  def broadcast(topic) do
    GenServer.call(topic, :broadcast)
  end

  def get_hooks(topic) do
    GenServer.call(topic, :get_hooks)
  end

  def get_responses(topic) do
    GenServer.call(topic, :get_responses)
  end

  def remove_hook(topic, hook_pid) do
    GenServer.cast(topic, {:remove_hook, hook_pid})
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
      {:reply, {:ok, pid}, %{state | hook_pids: [pid | hook_pids]}}
  end

  def handle_call(:get_hooks, _from, %{hook_pids: hook_pids} = state) do
    hooks = Enum.map(hook_pids, fn pid ->
      {pid, Grapple.Hook.get_hook(pid)}
    end)

    {:reply, hooks, state}
  end

  def handle_call(:get_responses, _from, %{hook_pids: hook_pids} = state) do
    responses = Enum.map(hook_pids, fn pid ->
      {pid, Grapple.Hook.get_responses(pid)}
    end)

    {:reply, responses, state}
  end

  def handle_cast({:remove_hook, hook_pid}, %{hook_pids: hook_pids,
    hook_sup: hook_sup} = state) do
      Supervisor.terminate_child(hook_sup, hook_pid)
      new_hooks = List.delete(hook_pids, hook_pid)

      {:noreply, %{state | hook_pids: new_hooks}}
  end
end
