defmodule Grapple.Ets do
  use GenServer

  # API

  def start_link(name) when is_atom(name) do
    GenServer.start_link(__MODULE__, name)
  end

  def all(pid) do
    GenServer.call(pid, :all)
  end

  # Callbacks

  def init(name) do
    store = :ets.new(name, [:private])

    {:ok, store}
  end

  def handle_call(:all, _from, store) do
    {:reply, :ets.tab2list(store), store}
  end
end
