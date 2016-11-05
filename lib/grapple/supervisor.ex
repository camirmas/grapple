defmodule Grapple.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(_) do
    result = {:ok, sup} = Supervisor.start_link(__MODULE__, [])
    start_workers(sup)
    result
  end

  def start_workers(sup) do
    {:ok, topics_sup} =
      Supervisor.start_child(sup,
                             supervisor(Grapple.TopicsSupervisor, [[]]))
    Supervisor.start_child(sup, worker(Grapple.Server, [topics_sup]))
  end

  def init(_) do
    supervise [], strategy: :one_for_all
  end
end
