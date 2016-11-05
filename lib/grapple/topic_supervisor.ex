defmodule Grapple.TopicSupervisor do
  use Supervisor
  import Supervisor.Spec

  def start_link(topic) do
    result = {:ok, sup} = Supervisor.start_link(__MODULE__, topic, name: :"#{topic}Supervisor")
    start_workers(topic, sup)
    result
  end

  def start_workers(topic, sup) do
    {:ok, hook_sup} = Supervisor.start_child(sup,
                                             supervisor(Grapple.HookSupervisor, [[]]))
    Supervisor.start_child(sup, worker(Grapple.HookServer, [topic, hook_sup]))
  end

  def init(_) do
    supervise [], strategy: :one_for_all
  end
end
