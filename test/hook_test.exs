defmodule HookTest do
  use ExUnit.Case
  alias Grapple.Hook

  @hook %Hook{url: "/stuff"}

  setup do
    Grapple.clear_topics
    {:ok, topic} = Grapple.add_topic :pokemon

    [topic: topic]
  end

  describe "hooks" do
    test "can subscribe hooks to topics", %{topic: topic} do
      {:ok, _pid} = Grapple.subscribe(topic.name, @hook)
    end

    test "can get hooks on topics", %{topic: topic} do
      {:ok, pid} = Grapple.subscribe(topic.name, @hook)

      assert [{^pid, @hook}] = Grapple.get_hooks(topic.name)
    end

    test "can remove hooks from topics", %{topic: topic} do
      {:ok, pid} = Grapple.subscribe(topic.name, @hook)
      ref = Process.monitor(pid)
      Grapple.remove_hook(topic.name, pid)

      assert_receive {:DOWN, ^ref, _, _, _}
    end

    test "can get responses on hooks by topic", %{topic: topic} do
      {:ok, pid} = Grapple.subscribe(topic.name, @hook)
      assert [{^pid, []}] = Grapple.get_responses(topic.name)
    end

    test "if a hook goes down in an abnormal way, it should be removed", %{topic: topic} do
      {:ok, pid} = Grapple.subscribe(topic.name, @hook)
      ref = Process.monitor(pid)
      Process.exit(pid, :kill)
      assert_receive {:DOWN, ^ref, _, _, _}

      assert [] = Grapple.get_hooks(topic.name)
    end

    test "can broadcast hooks", %{topic: topic} do
      {:ok, pid} = Grapple.subscribe(topic.name, @hook)

      [%{hook: hook, responses: responses}] = Grapple.broadcast(topic.name)

      assert [{^pid, ^hook}] = Grapple.get_hooks(topic.name)
      assert [{:success, [body: %{}]}] = responses
    end
  end
end
