defmodule Grapple.PlugTest do
  use ExUnit.Case
  use Phoenix.ConnTest
  alias Grapple.{Hook, Plug}

  @params [topic: "stuff"]

  setup do
    Hook.clear_webhooks
    hook = %Hook{topic: "stuff", url: "elixir-lang.org"}
    Hook.subscribe(hook)
    conn = build_conn()

    [hook: hook, conn: conn]
  end

  test "hook triggers on call", %{conn: conn} do
    assert Plug.call(conn, @params)
  end
end
