defmodule Grapple.Hook do
  @moduledoc false
  use GenServer

  @http Application.get_env(:grapple, :http, HTTPoison)

  @enforce_keys [:url]
  defstruct [
    :url,
    :owner,
    :life,
    :ref,
    :interval,
    method: "GET",
    body: %{},
    headers: [],
    options: [],
    query: %{},
  ]

  # API

  def start_link(hook) do
    GenServer.start_link __MODULE__, hook
  end

  def get_responses(pid) do
    GenServer.call pid, :get_responses
  end

  def start_polling(pid) do
    GenServer.call pid, :start_polling
  end

  def start_polling(pid, interval) when is_integer(interval) do
    GenServer.call pid, {:start_polling, interval}
  end

  def broadcast(pid) do
    GenServer.cast pid, :broadcast
  end

  def broadcast(pid, body) when is_nil(body) do
    GenServer.cast pid, :broadcast
  end

  def broadcast(pid, body) do
    GenServer.cast pid, {:broadcast, body}
  end

  def stop_polling(pid) do
    GenServer.cast pid, :stop_polling
  end

  # Callbacks

  def init(%{interval: interval} = hook) when is_integer(interval) do
    {:ok, tref} = start_timer(interval)

    {:ok, %{responses: [], hook: hook, tref: tref}}
  end

  def init(hook) do
    {:ok, %{responses: [], hook: hook, tref: nil}}
  end

  def handle_call(:get_responses, _from, %{responses: responses} = state) do
    {:reply, responses, state}
  end

  def handle_call(:start_polling, _from, %{hook: %{interval: interval}} = state) do
    case interval do
      nil ->
        {:reply, {:error, "No interval specified, use `start_polling/2`."}, state}
      _ ->
        {:ok, tref} = start_timer(interval)

        {:reply, :ok, %{state | tref: tref}}
    end
  end

  def handle_call({:start_polling, interval}, _from, %{hook: hook} = state) do
    {:ok, tref} = start_timer(interval)
    new_hook = Map.put(hook, :interval, interval)

    {:reply, :ok, %{state | tref: tref, hook: new_hook}}
  end

  def handle_cast(:broadcast, %{hook: hook, responses: responses} = state) do
      response = notify(hook, hook.body)
      new_state = %{state | responses: [response | responses]}
      send_to_owner(hook, response)

      {:noreply, new_state}
  end

  def handle_cast({:broadcast, body}, %{hook: hook, responses: responses} = state) do
      response = notify(hook, body)
      new_state = %{state | responses: [response | responses]}
      send_to_owner(hook, response)

      {:noreply, new_state}
  end

  def handle_cast(:stop_polling, %{tref: tref} = state) do
    {:ok, _cancel} = stop_timer(tref)

    {:noreply, %{state | tref: nil}}
  end

  # Helpers

  defp notify(hook = %Grapple.Hook{method: "GET"}, _body) do
    @http.get(hook.url, hook.headers, hook.options)
  end

  defp notify(hook = %Grapple.Hook{method: "POST"}, body) do
    @http.post(hook.url, body, hook.headers, hook.options)
  end

  defp notify(hook = %Grapple.Hook{method: "PUT"}, body) do
    @http.put(hook.url, body, hook.headers, hook.options)
  end

  defp notify(hook = %Grapple.Hook{method: "DELETE"}, _body) do
    @http.delete(hook.url, hook.headers, hook.options)
  end

  defp send_to_owner(%{owner: owner}, response) when is_pid(owner) do
    if Process.alive?(owner) do
      send(owner, {:hook_response, self, response})
    end
  end

  defp send_to_owner(_, _), do: nil

  defp start_timer(interval) do
    # Uses Erlang :timer to `broadcast` at the given interval
    :timer.apply_interval(interval,
                          __MODULE__,
                          :broadcast,
                          [self])
  end

  defp stop_timer(tref) when is_nil(tref) do
    # if :timer ref is nil then nothing needs to be done
    {:ok, "No timer"}
  end

  defp stop_timer(tref) do
    # Stops the :timer with the given ref
    :timer.cancel(tref)
  end
end
