defmodule Grapple.Hook do
  @moduledoc false
  use GenServer

  @http Application.get_env(:grapple, :http)

  @enforce_keys [:url]
  defstruct [
    :url,
    :owner,
    :life,
    :ref,
    method: "GET",
    headers: [],
    body: %{},
    query: %{},
    timeout: 5000,
    async: false,
  ]

  # API

  def start_link(hook) do
    GenServer.start_link __MODULE__, hook
  end

  def get_hook(pid) do
    GenServer.call pid, :get_hook
  end

  def get_responses(pid) do
    GenServer.call pid, :get_responses
  end

  def broadcast(pid) do
    GenServer.call pid, :broadcast
  end

  def broadcast(pid, body) when is_nil(body) do
    GenServer.call pid, :broadcast
  end

  def broadcast(pid, body) do
    GenServer.call pid, {:broadcast, body}
  end

  # Callbacks

  def init(hook) do
    {:ok, %{responses: [], hook: hook}}
  end

  def handle_call(:get_hook, _from, %{hook: hook} = state) do
    {:reply, hook, state}
  end

  def handle_call(:get_responses, _from, %{responses: responses} = state) do
    {:reply, responses, state}
  end

  def handle_call(:broadcast, _from, %{hook: hook, responses: responses} = state) do
    response = notify(hook, hook.body)
    new_state = %{state | responses: [response | responses]}

    {:reply, new_state, new_state}
  end

  def handle_call({:broadcast, body}, _from, %{hook: hook, responses: responses} = state) do
    response = notify(hook, body)
    new_state = %{state | responses: [response | responses]}

    {:reply, new_state, new_state}
  end

  # Helpers

  defp notify(webhook, body) do
    # Messages a subscriber webhook with the latest updates via HTTP
    _notify(webhook, body)
  end

  defp _notify(webhook = %Grapple.Hook{method: "GET"}, _body) do
    @http.get(webhook.url, webhook.headers)
  end

  defp _notify(webhook = %Grapple.Hook{method: "POST"}, body) do
    @http.post(webhook.url, webhook.headers, body)
  end

  defp _notify(webhook = %Grapple.Hook{method: "PUT"}, body) do
    @http.put(webhook.url, webhook.headers, body)
  end

  defp _notify(webhook = %Grapple.Hook{method: "DELETE"}, _body) do
    @http.delete(webhook.url, webhook.headers)
  end
end
