defmodule Grapple.Stash do
  use GenServer

  # API

  def start_link(webhooks) do
    GenServer.start_link __MODULE__, webhooks
  end

  def get_hooks(pid) do
    GenServer.call pid, :get_hooks
  end

  def save_hooks(pid, webhooks) do
    GenServer.cast pid, {:save_hooks, webhooks}
  end

  # Callbacks

  def handle_call(:get_hooks, _from, webhooks) do
    {:reply, webhooks, webhooks}
  end

  def handle_cast({:save_hooks, webhooks}, _current_webhooks) do
    {:noreply, webhooks}
  end
end
