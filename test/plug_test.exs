defmodule Grapple.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  alias Grapple.Hook

  @opts Grapple.Plug.init([topic: "stuff"])

  #setup do
    #Hook.clear_webhooks
    #hook = %Hook{topic: "stuff", url: "elixir-lang.org"}
    #Hook.subscribe(hook)
    #conn = conn(:get, "/hello")

    #[hook: hook, conn: conn]
  #end

  #test "hook triggers on call", %{conn: conn} do
    #conn = Grapple.Plug.call(conn, @opts)

    #assert conn.assigns.hook_responses
    #assert length(conn.assigns.hook_responses) > 0
  #end
end
