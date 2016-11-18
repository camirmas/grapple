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
    state = %{hook_pids: [], hook_sup: hook_sup, monitors: []}
    {:ok, state}
  end

  def handle_call({:subscribe, hook}, _from, %{hook_pids: hook_pids,
    hook_sup: hook_sup, monitors: monitors} = state) do
      {:ok, pid} = Supervisor.start_child(hook_sup, [hook])
      ref = Process.monitor(pid)
      new_monitors = [{ref, pid} | monitors]
      new_hook_pids = [pid | hook_pids]
      {:reply, {:ok, pid},
        %{state | hook_pids: new_hook_pids, monitors: new_monitors}}
  end

  def handle_call(:get_hooks, _from, %{hook_pids: hook_pids} = state) do
    hooks = Enum.map(hook_pids, fn pid ->
      {pid, Hook.get_hook(pid)}
    end)

    {:reply, hooks, state}
  end

  def handle_call(:get_responses, _from, %{hook_pids: hook_pids} = state) do
    responses = Enum.map(hook_pids, fn pid ->
      {pid, Hook.get_responses(pid)}
    end)

    {:reply, responses, state}
  end

  def handle_cast({:remove_hook, hook_pid}, %{hook_pids: hook_pids,
    hook_sup: hook_sup} = state) do
      Supervisor.terminate_child(hook_sup, hook_pid)
      new_hooks = List.delete(hook_pids, hook_pid)

      {:noreply, %{state | hook_pids: new_hooks}}
  end

  def handle_cast(:broadcast, %{hook_pids: hook_pids} = state) do
    hook_pids
    |> Enum.each(fn hook_pid -> Hook.broadcast(hook_pid) end)

    {:noreply, state}
  end

  def handle_cast({:broadcast, body}, %{hook_pids: hook_pids} = state) do
    hook_pids
    |> Enum.each(fn hook_pid -> Hook.broadcast(hook_pid, body) end)

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, _, pid, _}, %{hook_pids: hook_pids,
    monitors: monitors} = state) do
      case {ref, pid} in monitors do
        true ->
          new_monitors = List.delete(monitors, {ref, pid})
          new_hooks = List.delete(hook_pids, pid)
          new_state = %{state | hook_pids: new_hooks, monitors: new_monitors}
          {:noreply, new_state}
        _ ->
          {:noreply, state}
      end
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
