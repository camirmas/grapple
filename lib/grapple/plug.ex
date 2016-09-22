defmodule Grapple.Plug do
  alias Grapple.Hook

  def init(opts) do
    Keyword.fetch! opts, :topic
  end

  def call(conn, topic) do
    resp = Hook.broadcast topic
    conn
  end
end
