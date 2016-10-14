defmodule Grapple.Logger do
  @moduledoc """
  This module is responsible for keeping track of webhook
  responses.
  """
  use GenServer
  use Timex

  alias Grapple.Hook

  # GenServer API

  def start_link(responses) do
    GenServer.start_link __MODULE__, responses, name: __MODULE__
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

  def handle_call(:get_logs, _from, logs) do
    {:reply, logs, logs}
  end

  def handle_call({:get_logs, {key, val}}, _from, logs) do
    filtered_logs = logs
      |> Enum.filter(&(Map.get(&1.hook, key) == val))

    {:reply, filtered_logs, logs}
  end

  def handle_call({:add_log, {response, hook}}, _from, logs) do
    log = [%{hook: hook, response: response, timestamp: Timex.now}]

    {:reply, response, logs ++ log}
  end

  def handle_call(:clear_logs, _from, _logs) do
    {:reply, :ok, []}
  end

end
