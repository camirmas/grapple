defmodule Grapple.Supervisor do
  @moduledoc false

  use Supervisor

  alias Grapple.{Server, TopicsSupervisor}

  def start_link(_) do
    result = {:ok, sup} = Supervisor.start_link(__MODULE__, [])
    start_workers(sup)
    result
  end

  def start_workers(sup) do
    spec = %{id: TopicsSupervisor, start: {TopicsSupervisor, :start_link, []}}
    {:ok, _} = Supervisor.start_child(sup, spec)
    Supervisor.start_child(sup, %{id: Server, start: {Server, :start_link, []}})
  end

  def init(_) do
    supervise [], strategy: :one_for_all
  end
end
