defmodule Grapple.HookServer do
  @moduledoc false
  use GenServer
  alias Grapple.Hook
  alias Experimental.Flow

  # API

  def start_link(topic, hook_sup) do
    GenServer.start_link(__MODULE__, hook_sup, name: topic)
  end

  def subscribe(topic, webhook) do
    GenServer.call(topic, {:subscribe, webhook})
  end

  def broadcast(topic) do
    GenServer.call(topic, :broadcast, :infinity)
  end

  def broadcast(topic, body) do
    GenServer.call(topic, {:broadcast, body}, :infinity)
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

  def init(hook_sup) do
    state = %{hook_pids: [], hook_sup: hook_sup, monitors: []}
    {:ok, state}
  end

  def handle_call({:subscribe, webhook}, _from, %{hook_pids: hook_pids,
    hook_sup: hook_sup, monitors: monitors} = state) do
      {:ok, pid} = Supervisor.start_child(hook_sup, [webhook])
      ref = Process.monitor(pid)
      new_monitors = [{ref, pid} | monitors]
      new_hook_pids = [pid | hook_pids]
      {:reply, {:ok, pid},
        %{state | hook_pids: new_hook_pids, monitors: new_monitors}}
  end

  # TODO: make async or not depending on hook config
  def handle_call(:broadcast, _from, %{hook_pids: hook_pids} = state) do
    hooks = hook_pids
      |> Flow.from_enumerable()
      |> Flow.map(fn hook_pid -> Hook.broadcast(hook_pid) end)
      |> Enum.to_list()

    {:reply, hooks, state}
  end

  def handle_call({:broadcast, body}, _from, %{hook_pids: hook_pids} = state) do
    hooks = hook_pids
      |> Flow.from_enumerable()
      |> Flow.map(fn hook_pid -> Hook.broadcast(hook_pid, body) end)
      |> Enum.to_list()

    {:reply, hooks, state}
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
