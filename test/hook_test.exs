defmodule HookTest do
  use ExUnit.Case
  doctest Grapple
  alias Grapple.Hook

  @hook %Hook{url: "/stuff"}

  setup do
    Grapple.clear_topics()
    {:ok, topic} = Grapple.add_topic(:pokemon)
    hook = Map.put(@hook, :owner, self())

    [topic: topic, hook: hook]
  end

  describe "hooks subscriptions" do
    test "can subscribe hooks to topics", %{topic: topic, hook: hook} do
      {:ok, _pid} = Grapple.subscribe(topic.name, hook)
    end

    test "can get hooks on topics", %{topic: topic, hook: hook} do
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      assert [{^pid, ^hook}] = Grapple.get_hooks(topic.name)
    end

    test "can remove hooks from topics", %{topic: topic, hook: hook} do
      {:ok, pid} = Grapple.subscribe(topic.name, hook)
      ref = Process.monitor(pid)
      Grapple.remove_hook(pid)

      assert_receive {:DOWN, ^ref, _, _, _}
    end

    test "can get responses on hooks by topic", %{topic: topic, hook: hook} do
      {:ok, pid} = Grapple.subscribe(topic.name, hook)
      assert [{^pid, []}] = Grapple.get_responses(topic.name)
    end

    test "if a hook goes down in an abnormal way, it should be restarted", %{
      topic: topic,
      hook: hook
    } do
      {:ok, pid} = Grapple.subscribe(topic.name, hook)
      ref = Process.monitor(pid)
      Process.exit(pid, :kill)
      assert_receive {:DOWN, ^ref, _, _, _}

      assert [{new_pid, %Hook{}}] = Grapple.get_hooks(topic.name)
      refute new_pid == pid
    end
  end

  describe "hook broadcasts" do
    test "can broadcast hooks", %{topic: topic, hook: hook} do
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      assert Grapple.broadcast(topic.name)

      assert_receive {:hook_response, ^pid, response}
      assert response == {:ok, %{body: %{}, status_code: 200}}
    end

    test "broadcasts a hook and gets a 404", %{topic: topic, hook: hook} do
      hook = Map.put(hook, :url, "NOT_FOUND")
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      Hook.broadcast(topic.name)

      assert_receive {:hook_response, ^pid, response}
      assert response == {:ok, %{status_code: 404}}
    end

    test "sends a hook with a body", %{topic: topic, hook: hook} do
      body = %{stuff: true}
      hook = Map.put(hook, :body, body)
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      Hook.broadcast(topic.name)

      assert_receive {:hook_response, ^pid, response}
      assert response == {:ok, %{body: %{}, status_code: 200}}
    end
  end

  describe "hook polling" do
    test "can subscribe a hook with immediate polling", %{topic: topic, hook: hook} do
      hook = Map.put(hook, :interval, 1)
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      assert_receive {:hook_response, ^pid, response}
      assert response == {:ok, %{body: %{}, status_code: 200}}
    end

    test "can subscribe a hook without polling, but can start it later", %{
      topic: topic,
      hook: hook
    } do
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      assert Grapple.start_polling(pid, 1) == :ok
      assert_receive {:hook_response, ^pid, response}
      assert response == {:ok, %{body: %{}, status_code: 200}}
    end

    test "cannot start polling without an interval", %{topic: topic, hook: hook} do
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      resp = Grapple.start_polling(pid)

      assert resp == {:error, "No interval specified, use `start_polling/2`."}
    end

    test "can stop polling", %{topic: topic, hook: hook} do
      hook = Map.put(hook, :interval, 1)
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      assert Grapple.stop_polling(pid) == :ok
    end

    test "can restart polling", %{topic: topic, hook: hook} do
      hook = Map.put(hook, :interval, 1)
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      assert Grapple.stop_polling(pid) == :ok
      assert Grapple.start_polling(pid) == :ok
      assert_receive {:hook_response, ^pid, response}
      assert response == {:ok, %{body: %{}, status_code: 200}}
    end
  end

  describe "defhook" do
    use Grapple

    test "hooks defined with the macro will broadcast to topics of the same name", %{
      topic: topic,
      hook: hook
    } do
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      defmodule Hookable do
        defhook pokemon do
        end
      end

      Hookable.pokemon()

      assert_receive {:hook_response, ^pid, response}
      assert response == {:ok, %{body: %{}, status_code: 200}}
    end

    test "hooks defined with the macro (with args) will broadcast
      to topics of the same name", %{topic: topic, hook: hook} do
      {:ok, pid} = Grapple.subscribe(topic.name, hook)

      defmodule HookableArgs do
        defhook(pokemon(name), do: name)
      end

      HookableArgs.pokemon("dragonite")

      assert_receive {:hook_response, ^pid, response}
      assert response == {:ok, %{body: %{}, status_code: 200}}
    end
  end
end
