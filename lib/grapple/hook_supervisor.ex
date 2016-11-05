defmodule Grapple.HookSupervisor do
  @moduledoc false

  use Supervisor
  import Supervisor.Spec

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    opts = [restart: :temporary]
    children = [worker(Grapple.Hook, [], opts)]
    supervise children, strategy: :simple_one_for_one
  end
end
