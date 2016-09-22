defmodule GrappleTest do
  use ExUnit.Case
  alias Grapple.Hook

  setup do
    Hook.clear_webhooks

    [hook: %Hook{topic: "stuff", url: "elixir-lang.org"}]
  end

  describe "subscribe" do


    test "can subscribe to webhooks", %{hook: hook} do
      assert {_topic, _ref} = Hook.subscribe hook
    end

    test "can get webhooks", %{hook: hook} do
      {_topic, ref} = Hook.subscribe hook
      hooks = Hook.get_webhooks

      returned_hook = List.first(hooks)
      assert ref == returned_hook.ref
    end

    test "can remove a specified hook by ref", %{hook: hook} do
      {_topic, ref} = Hook.subscribe hook
      Hook.remove_webhook(ref)

      hook_refs = Hook.get_webhooks
        |> Enum.map(&(&1.ref))

      refute ref in hook_refs
    end

    test "can remove all hooks for a specific topic", %{hook: hook} do
      for _ <- 1..10, do: Hook.subscribe hook

      Hook.remove_topic "stuff"

      assert length(Hook.get_webhooks) == 0
    end

  end

  describe "broadcast" do

    test "sends a successful hook", %{hook: hook} do
      Hook.subscribe hook
      [resp] = Hook.broadcast hook.topic

      assert {:success, body: _body} = resp
    end

    test "sends a hook and gets a 404", %{hook: hook} do
      hook = Map.put(hook, :url, "NOT_FOUND")
      Hook.subscribe hook

      [resp] = Hook.broadcast hook.topic

      assert resp == :not_found
    end

    test "sends a hook and gets an error", %{hook: hook} do
      hook = Map.put(hook, :url, "ERROR")
      Hook.subscribe hook

      [resp] = Hook.broadcast hook.topic

      assert {:error, reason: _} = resp
    end
  end

end
