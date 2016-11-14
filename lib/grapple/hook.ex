defmodule Grapple.Hook do
  @moduledoc """
  This module provides a GenServer that is primarily responsible for 
  broadcasting Webhooks. It also defines a `Hook` struct, and macros
  for defining hooks.
  """
  use GenServer

  @http Application.get_env(:grapple, :http)

  # TODO: should probably make this configurable for users
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
  ]

  # API

  @doc false
  def start_link(hook) do
    GenServer.start_link __MODULE__, hook
  end

  @doc """
  Returns all webhooks.
  """
  def get_hook(pid) do
    GenServer.call pid, :get_hook
  end

  def get_responses(pid) do
    GenServer.call pid, :get_responses
  end

  @doc """
  Executes an HTTP request for every Webhook of the
  specified topic, and returns the current logs.
  """
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

  @doc false
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

  @doc """
  Messages a subscriber webhook with the latest updates via HTTP
  """
  defp notify(webhook, body) do
    _notify(webhook, body)
    |> handle_response
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

  defp handle_response(response) do
    case response do
      {:ok, %{status_code: 200, body: body}} ->
        {:success, body: body}
      {:ok, %{status_code: 404}} ->
        #delete subscrip
        :not_found
      {:error, %{reason: reason}} ->
        {:error, reason: reason}
      {:ok, resp} ->
        {:ok, resp}
    end
  end
end
