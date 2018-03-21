defmodule Grapple.HookSupervisor do
  @moduledoc false

  use DynamicSupervisor

  alias Grapple.Hook

  def start_link(topic) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: :"#{topic}HookSupervisor")
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(sup, hook) do
    spec = %{id: Hook, start: {Hook, :start_link, [hook]}}
    DynamicSupervisor.start_child(sup, spec)
  end

  def terminate_child(sup, pid) do
    DynamicSupervisor.terminate_child(sup, pid)
  end

  def which_children(sup) do
    DynamicSupervisor.which_children(sup)
  end
end
