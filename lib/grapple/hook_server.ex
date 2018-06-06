defmodule Grapple.HookServer do
  @moduledoc false
  use GenServer
  alias Grapple.{Hook, HookSupervisor}

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
    state = %{hook_sup: hook_sup}
    {:ok, state}
  end

  def handle_call({:subscribe, hook}, _from, %{hook_sup: hook_sup} = state) do
    pid = add_hook(hook, hook_sup)

    {:reply, {:ok, pid}, state}
  end

  def handle_call(:get_hooks, _from, %{hook_sup: hook_sup} = state) do
    hooks =
      hook_sup
      |> DynamicSupervisor.which_children()
      |> Enum.map(fn {_, pid, _, _} -> {pid, Hook.get_info(pid)} end)

    {:reply, hooks, state}
  end

  def handle_call(:get_responses, _from, %{hook_sup: hook_sup} = state) do
    responses =
      hook_sup
      |> DynamicSupervisor.which_children()
      |> Enum.map(fn {_, pid, _, _} -> {pid, Hook.get_responses(pid)} end)

    {:reply, responses, state}
  end

  def handle_cast({:remove_hook, hook_pid}, %{hook_sup: hook_sup} = state) do
    HookSupervisor.terminate_child(hook_sup, hook_pid)

    {:noreply, state}
  end

  def handle_cast(:broadcast, %{hook_sup: hook_sup} = state) do
    hook_sup
    |> HookSupervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} -> Hook.broadcast(pid) end)

    {:noreply, state}
  end

  def handle_cast({:broadcast, body}, %{hook_sup: hook_sup} = state) do
    hook_sup
    |> HookSupervisor.which_children()
    |> Enum.each(fn {_, pid, _, _} -> Hook.broadcast(pid, body) end)

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private

  defp add_hook(hook, hook_sup) do
    # Creates a new supervised hook and inserts it into the :ets table.
    {:ok, pid} = HookSupervisor.start_child(hook_sup, hook)

    pid
  end
end
