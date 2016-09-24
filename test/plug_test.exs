defmodule Grapple.PlugTest do
  use ExUnit.Case, async: true
  import Plug.Conn
  alias Grapple.Hook

  @params [topic: "stuff"]

  setup do
    Hook.clear_webhooks
    hook = %Hook{topic: "stuff", url: "elixir-lang.org"}
    Hook.subscribe(hook)
    conn = %Plug.Conn{}

    [hook: hook, conn: conn]
  end

  test "hook triggers on call", %{conn: conn} do
    assert Grapple.Plug.call(conn, @params, nil)
  end
end
