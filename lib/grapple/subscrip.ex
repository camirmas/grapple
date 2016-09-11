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

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def subscribe(webhook = %Webhook{}) do
    GenServer.call(__MODULE__, {:subscribe, webhook})
  end

  def get_webhooks do
    GenServer.call(__MODULE__, :get_webhooks)
  end

  def broadcast(topic) do
    GenServer.cast(__MODULE__, {:broadcast, topic})
  end

  # Callbacks

  @doc """
  Callback for subscribing a Webhook. Adds a unique
  ref and adds to the list if it is not already in the list,
  and returns the topic name and unique ref of that Webhook
  """
  def handle_call({:subscribe, webhook}, _from, webhooks) do
    if webhook in webhooks do
        Map.put(webhook, :ref, make_ref())
        {:reply, {webhook.topic, webhook.ref}, [webhook | webhooks]}
    else
        {:reply, webhooks, webhooks}
    end
  end

  @doc """
  Returns all webhooks.
  """
  def handle_call(:get_webhooks, _from, webhooks) do
    {:reply, webhooks, webhooks}
  end

  @doc """
  Executes an HTTP request for every Webhook of the
  specified topic
  """
  def handle_cast({:broadcast, topic}, webhooks) do
    webhooks
    |> Enum.filter(&(&1.topic == topic))
    |> Enum.map(&notify/1)
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

 end

