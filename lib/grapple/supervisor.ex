defmodule Grapple.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(webhooks) do
    result = {:ok, sup} = Supervisor.start_link(__MODULE__, [webhooks])
    start_workers(sup, webhooks)
    result
  end

  def start_workers(sup, webhooks) do
    {:ok, stash} = Supervisor.start_child(sup, worker(Grapple.Stash, [webhooks]))
    Supervisor.start_child(sup, worker(Grapple.Logger, [[]]))
    Supervisor.start_child(sup, supervisor(Grapple.HookSupervisor, [stash]))
  end

  def init(_) do
    supervise [], strategy: :one_for_one
  end
end
