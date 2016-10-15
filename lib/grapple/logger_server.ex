defmodule Grapple.LoggerServer do
  @moduledoc false

  use GenServer

  # API

  def start_link(logs) do
    GenServer.start_link __MODULE__, logs
  end

  def get_logs(pid) do
    GenServer.call pid, :get_logs
  end

  def save_logs(pid, logs) do
    GenServer.cast pid, {:save_logs, logs}
  end

  # Callbacks
  
  def handle_call(:get_logs, _from, logs) do
    {:reply, logs, logs}
  end

  def handle_cast({:save_logs, logs}, _current_logs) do
    {:noreply, logs}
  end
end
