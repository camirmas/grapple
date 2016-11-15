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
      assert [ok: %{body: %{}, status_code: 200}] = responses
    end

    test "broadcasts a hook and gets a 404", %{topic: topic} do
      hook = Map.put(@hook, :url, "NOT_FOUND")
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      [%{hook: hook, responses: responses}] = Hook.broadcast(topic.name)

      assert [ok: %{status_code: 404}] = responses
      assert [{^pid, ^hook}] = Grapple.get_hooks(topic.name)
    end

    test "sends a hook with a body", %{topic: topic} do
      body = %{stuff: true}
      hook = Map.put(@hook, :body, body)
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      [%{hook: hook, responses: responses}] = Hook.broadcast(topic.name)

      assert responses == [ok: %{body: %{}, status_code: 200}]
      assert [{^pid, ^hook}] = Grapple.get_hooks(topic.name)
    end

    test "can broadcast lots of hooks", %{topic: topic} do
      n = 100
      for _ <- 1..n do
        Grapple.subscribe(topic.name, @hook)
      end

      responses = Grapple.broadcast(topic.name)
      assert length(responses) == n
    end
  end

  describe "defhook" do
    use Grapple

    test "hooks defined with the macro will broadcast to topics of the same name", 
      %{topic: topic} do
        {:ok, pid} = Grapple.subscribe(topic.name, @hook)

        defmodule Hookable do
          defhook pokemon do
          end
        end

        Hookable.pokemon()

        assert [{^pid, [ok: %{body: %{}, status_code: 200}]}] = Grapple.get_responses(topic.name)
    end

    test "hooks defined with the macro (with args) will broadcast
      to topics of the same name", %{topic: topic} do
        {:ok, pid} = Grapple.subscribe(topic.name, @hook)

        defmodule HookableArgs do
          defhook pokemon(name), do: name
        end

        res = HookableArgs.pokemon("dragonite")

        assert res == "dragonite"
        assert [{^pid, [ok: %{body: %{}, status_code: 200}]}] = Grapple.get_responses(topic.name)
    end
  end
end
