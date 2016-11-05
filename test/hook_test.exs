defmodule HookTest do
  use ExUnit.Case, async: true

  #setup do
    #Grapple.clear_topics
    #[topic] = Grapple.add_topic :pokemon

    #[topic: topic]
  #end

  #describe "hooks" do
    #test "can subscribe hooks to topics", %{topic: topic} do
      #{:ok, pid} = Grapple.subscribe(topic, %Grapple.Hook{})
    #end
  #end
end
