defmodule Grapple.HookServer do
  @moduledoc false
  use GenServer
  alias Grapple.Hook
  #alias Experimental.Flow

  # API

  def start_link(topic) do
    GenServer.start_link(__MODULE__, topic, name: topic)
  end

  def subscribe(topic, hook) do
    GenServer.call(topic, {:subscribe, hook})
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

  def broadcast(topic) do
    GenServer.cast(topic, :broadcast)
  end

  def broadcast(topic, body) do
    GenServer.cast(topic, {:broadcast, body})
  end

  # Callbacks

  def init(topic) do
    hook_sup = :"#{topic}HookSupervisor"
    hooks = :ets.new(:hooks, [:private])
    state = %{hooks: hooks, hook_sup: hook_sup, monitors: []}
    {:ok, state}
  end

  def handle_call({:subscribe, hook}, _from, %{hooks: hooks,
    hook_sup: hook_sup, monitors: monitors} = state) do
      monitor = {_ref, pid} =
        add_hook(hooks, hook, hook_sup)
        |> monitor_hook

      new_monitors = [monitor | monitors]
      {:reply, {:ok, pid},
        %{state | monitors: new_monitors}}
  end

  def handle_call(:get_hooks, _from, %{hooks: hooks} = state) do
    hooks =
      hooks
      |> :ets.tab2list

    {:reply, hooks, state}
  end

  def handle_call(:get_responses, _from, %{hooks: hooks} = state) do
    responses =
      hooks
      |> :ets.tab2list
      |> Enum.map(fn {pid, _hook} -> {pid, Hook.get_responses(pid)} end)

    {:reply, responses, state}
  end

  def handle_cast({:remove_hook, hook_pid}, %{hooks: hooks,
    hook_sup: hook_sup} = state) do
      Supervisor.terminate_child(hook_sup, hook_pid)
      :ets.delete(hooks, hook_pid)

      {:noreply, state}
  end

  def handle_cast(:broadcast, %{hooks: hooks} = state) do
    hooks
    |> :ets.tab2list
    |> Enum.each(fn {pid, _hook} -> Hook.broadcast(pid) end)

    {:noreply, state}
  end

  def handle_cast({:broadcast, body}, %{hooks: hooks} = state) do
    hooks
    |> :ets.tab2list
    |> Enum.each(fn {pid, _hook} -> Hook.broadcast(pid, body) end)

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, _, pid, _}, %{hooks: hooks,
    monitors: monitors, hook_sup: hook_sup} = state) do
      case {ref, pid} in monitors do
        true ->
          true = Process.demonitor(ref)
          true = :ets.delete(hooks, pid)
          new_monitors = List.delete(monitors, {ref, pid})
          new_state = %{state | monitors: new_monitors}

          {:noreply, new_state}
        _ ->
          {:noreply, state}
      end
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private

  defp monitor_hook(pid) do
    ref = Process.monitor(pid)

    {ref, pid}
  end

  defp add_hook(hooks, hook, hook_sup) do
    # Creates a new supervised hook and inserts it into the :ets table.
    {:ok, pid} = Supervisor.start_child(hook_sup, [hook])
    :ets.insert(hooks, {pid, hook})

    pid
  end
end
