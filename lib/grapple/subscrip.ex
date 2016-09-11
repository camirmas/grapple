defmodule Grapple.Hook do
  @moduledoc """

  """
  use GenServer

  defmodule Webhook do
    @enforce_keys [:topic, :url]
    defstruct [
      :topic,
      :url,
      :owner,
      :life,
      :ref,
      method: "GET",
      headers: %{},
      body: %{},
      query: %{},
    ]
  end

  # API

  def start_link(stash_pid) do
    GenServer.start_link __MODULE__, stash_pid, name: __MODULE__
  end

  def subscribe(webhook = %Webhook{}) do
    GenServer.call __MODULE__, {:subscribe, webhook}
  end

  def get_webhooks do
    GenServer.call __MODULE__, :get_webhooks
  end

  def broadcast(topic) do
    GenServer.cast __MODULE__, {:broadcast, topic}
  end

  def clear_webhooks do
    GenServer.cast __MODULE__, :clear_webhooks
  end

  # Callbacks

  def init(stash_pid) do
    webhooks = Grapple.Stash.get_hooks stash_pid
    {:ok, {webhooks, stash_pid}}
  end

  @doc """
  Callback for subscribing a Webhook. Adds a unique
  ref and adds to the list if it is not already in the list,
  and returns the topic name and unique ref of that Webhook
  """
  def handle_call({:subscribe, webhook}, _from, state = {webhooks, stash_pid}) do
    if webhook in webhooks do
      {:reply, {webhook.topic, webhook.ref}, state}
    else
      webhook = Map.put(webhook, :ref, make_ref())
      {:reply, {webhook.topic, webhook.ref}, {[webhook | webhooks], stash_pid}}
    end
  end

  @doc """
  Returns all webhooks.
  """
  def handle_call(:get_webhooks, _from, state = {webhooks, _stash_pid}) do
    {:reply, webhooks, state}
  end

  @doc """
  Executes an HTTP request for every Webhook of the
  specified topic
  """
  def handle_cast({:broadcast, topic}, {webhooks, stash_pid}) do
    webhooks
      |> Enum.filter(&(&1.topic == topic))
      |> Enum.each(&notify/1)

    {:noreply, {webhooks, stash_pid}}
  end

  def handle_cast(:clear_webhooks, {_webhooks, stash_pid}) do
    {:noreply, {[], stash_pid}}
  end

  def terminate(_reason, {webhooks, stash_pid}) do
    Grapple.Stash.save_hooks stash_pid, webhooks
  end

  # Helpers

  defp notify(webhook) do
    case HTTPoison.get webhook.url, webhook.body, webhook.headers do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts body # TODO: possibly track successful messages
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        #delete subscrip
        IO.puts "404"
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  defmacro topicof(name) do
    quote do: "#{__MODULE__}.#{name}"
  end

  # TODO: generate a unique identifier based on module.method
  # TODO: support arguments somehow, might be tricky
  defmacro defhook(name, do: block) do
    quote do
      def unquote(name) do
        topic  = topicof name
        result = unquote block

        broadcast self(), topic, result # TODO: replace self with Supervisor PID
      end
    end
  end
end
