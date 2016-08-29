defmodule Grapple do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Grapple.Store, []),
      worker(:poolboy, [[name: {:local, :rethinkdb_pool},
                         worker_module: RethinkDB.Connection,
                         size: 10,
                         max_overflow: 0], []]),
    ]

    opts = [strategy: :one_for_one, name: Grapple.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
