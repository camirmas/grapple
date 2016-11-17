defmodule Grapple.HookSupervisor do
  @moduledoc false

  use Supervisor
  import Supervisor.Spec

  def start_link(topic) do
    Supervisor.start_link(__MODULE__, [], name: :"#{topic}HookSupervisor")
  end

  def init(_) do
    opts = [restart: :permanent]
    children = [worker(Grapple.Hook, [], opts)]
    supervise children, strategy: :simple_one_for_one
  end
end
