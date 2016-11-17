defmodule Grapple.TopicSupervisor do
  use Supervisor
  import Supervisor.Spec

  def start_link(topic) do
    Supervisor.start_link(__MODULE__, topic, name: :"#{topic}Supervisor")
  end

  def init(topic) do
    children = [
      supervisor(Grapple.HookSupervisor, [topic]),
      worker(Grapple.HookServer, [topic])
    ]
    supervise children, strategy: :one_for_all
  end
end
