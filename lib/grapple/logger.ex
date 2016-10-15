defmodule Grapple.Logger do
  @moduledoc """
  This module is responsible for keeping track of webhook
  responses.
  """
  use GenServer
  use Timex

  alias Grapple.Hook

  # API

  def start_link(server_pid) do
    GenServer.start_link __MODULE__, server_pid, name: __MODULE__
  end

  @doc """
  Retrieves all current logs.
  """
  def get_logs do
    GenServer.call __MODULE__, :get_logs
  end

  @doc """
  Retrieves logs by hook key, val.
  """
  def get_logs(key, val) do
    GenServer.call __MODULE__, {:get_logs, {key, val}}
  end

  @doc """
  Adds a response to logs and returns response.
  """
  # TODO: Response struct
  def add_log(response, hook = %Hook{}) do
    GenServer.call __MODULE__, {:add_log, {response, hook}}
  end

  @doc """
  Clears logs.
  """
  def clear_logs do
    GenServer.call __MODULE__, :clear_logs
  end

  # Callbacks
  
  def init(server_pid) do
    logs = Grapple.LoggerServer.get_logs server_pid
    {:ok, {logs, server_pid}}
  end

  def handle_call(:get_logs, _from, state = {logs, _server_pid}) do
    {:reply, logs, state}
  end

  def handle_call({:get_logs, {key, val}}, _from, state = {logs, _server_pid}) do
    filtered_logs = logs
      |> Enum.filter(&(Map.get(&1.hook, key) == val))

    {:reply, filtered_logs, state}
  end

  def handle_call({:add_log, {response, hook}}, _from, {logs, server_pid}) do
    log = [%{hook: hook, response: response, timestamp: Timex.now}]

    {:reply, response, {logs ++ log, server_pid}}
  end

  def handle_call(:clear_logs, _from, {_logs, server_pid}) do
    {:reply, :ok, {[], server_pid}}
  end

end
