defmodule HookTest do
  use ExUnit.Case

  setup do
    Grapple.clear_topics
    {:ok, topic} = Grapple.add_topic :pokemon

    [topic: topic]
  end

  describe "hooks" do
    test "can subscribe hooks to topics", %{topic: topic} do
      {:ok, _pid} = Grapple.subscribe(topic.name, %Grapple.Hook{})
    end

    test "can get hooks on topics", %{topic: topic} do
      {:ok, pid} = Grapple.subscribe(topic.name, %Grapple.Hook{})

      assert [{^pid, %Grapple.Hook{}}] = Grapple.get_hooks(topic.name)
    end

    test "can remove hooks from topics", %{topic: topic} do
      {:ok, pid} = Grapple.subscribe(topic.name, %Grapple.Hook{})
      ref = Process.monitor(pid)
      Grapple.remove_hook(topic.name, pid)

      assert_receive {:DOWN, ^ref, _, _, _}
    end

    test "can get responses on hooks by topic", %{topic: topic} do
      {:ok, pid} = Grapple.subscribe(topic.name, %Grapple.Hook{})
      assert [{^pid, []}] = Grapple.get_responses(topic.name)
    end
  end
end
