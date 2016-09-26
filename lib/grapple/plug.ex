defmodule Grapple.Plug do
  alias Grapple.Hook
  import Plug.Conn

  def init(opts) do
    topic = Keyword.fetch! opts, :topic
    body = Keyword.get(opts, :body)

    {topic, body}
  end

  def call(conn, {topic, body}) do
    resp = Hook.broadcast topic, body

    assign(conn, :hook_responses, resp)
  end
end
