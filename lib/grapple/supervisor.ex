defmodule Grapple.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(webhooks) do
    result = {:ok, sup} = Supervisor.start_link(__MODULE__, [webhooks])
    start_workers(sup, webhooks)
    result
  end

  def start_workers(sup, webhooks) do
    {:ok, hook_server} = Supervisor.start_child(sup, worker(Grapple.Hook.HookServer, [webhooks]))
    {:ok, logger_server} = Supervisor.start_child(sup, worker(Grapple.Logger.LogServer, [[]]))
    Supervisor.start_child(sup, supervisor(Grapple.Logger.LogSupervisor, [logger_server]))
    Supervisor.start_child(sup, supervisor(Grapple.Hook.HookSupervisor, [hook_server]))
  end

  def init(_) do
    supervise [], strategy: :one_for_one
  end
end
