defmodule GrappleTest do
  use ExUnit.Case
  alias Grapple.Hook
  alias Hook.Webhook

  setup do
    Hook.clear_webhooks

    [hook: %Webhook{topic: "stuff", url: "elixir-lang.org"}]
  end

  test "can subscribe to webhooks", %{hook: hook} do
    assert {topic, ref} = Hook.subscribe hook
  end

  test "can get webhooks", %{hook: hook} do
    {topic, ref} = Hook.subscribe hook
    hooks = Hook.get_webhooks

    returned_hook = List.first(hooks)
    assert ref == returned_hook.ref
  end
end
