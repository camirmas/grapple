defmodule Grapple do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Phoenix.PubSub.PG2, [Grapple.PubSub, []])
    ]

    opts = [strategy: :one_for_one, name: Grapple.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
