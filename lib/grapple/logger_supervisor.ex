defmodule Grapple.LoggerSupervisor do
  @moduledoc false

  use Supervisor

  def start_link(server_pid) do
    Supervisor.start_link(__MODULE__, server_pid, name: __MODULE__)
  end

  def init(server_pid) do
    child_processes = [worker(Grapple.Logger, [server_pid])]
    supervise child_processes, strategy: :one_for_one
  end
end
