defmodule Grapple.LoggerTest do
  use ExUnit.Case, async: true
  alias Grapple.{Hook, Logger}

  setup do
    Hook.clear_webhooks
    Logger.clear_logs
    hook = %Hook{topic: "stuff", url: "elixir-lang.org"}
    {_topic, ref} = Hook.subscribe hook

    [hook: hook, ref: ref]
  end

  describe "logger" do

    test "can get logs" do
      assert [] = Logger.get_logs
    end

    test "can add a log", %{hook: hook} do
      Logger.add_log(%{}, hook)

      assert [_log] = Logger.get_logs
    end

    test "broadcasting should add responses to the log", %{ref: ref} do
      Hook.broadcast "stuff"

      assert [%{hook: returned_hook}] = Logger.get_logs
      assert ref == returned_hook.ref
    end

    test "filtering on logs", %{ref: ref} do
      Hook.broadcast "stuff"

      assert [%{hook: returned_hook}] = Logger.get_logs
      assert ref == returned_hook.ref
    end

  end

end
