defmodule TopicTest do
  use ExUnit.Case

  describe "topics" do
    setup do
      Grapple.clear_topics()
    end

    test "can get topics" do
      assert [] = Grapple.get_topics()
    end

    test "can add topics" do
      {:ok, pokemon} = Grapple.add_topic(:pokemon)
      {:ok, gyms} = Grapple.add_topic(:gyms)
      topics = Grapple.get_topics()

      assert gyms in topics
      assert pokemon in topics
    end

    test "can remove topics" do
      {:ok, pokemon} = Grapple.add_topic(:pokemon)
      ref = Process.monitor(pokemon.name)
      Grapple.remove_topic(:pokemon)
      assert_receive {:DOWN, ^ref, _, _, :shutdown}
    end

    test "can get all topics" do
      {:ok, gyms} = Grapple.add_topic(:gyms)
      topics = Grapple.get_topics()

      assert gyms in topics
    end
  end
end
