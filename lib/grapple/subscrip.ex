defmodule Grapple.Subscription do
  defstruct [:url, :owner, :method, :life, :headers, :body, :query]

  table = :ets.new(:subscrips, [:set, :protected, :named_table])

  def create(subscription) do
    uuid = UUID.uuid4(:default)
    :ets.insert(:subscrips, {uuid, subscription, self})
  end

  def all(owner) do # TODO: probably want to scope/filter to module.method
    :ets.select(:subscrips, owner)
  end

  def matches(subscrip, data) do
    false # TODO: use GraphQL or JSON Schema
  end

  def start do
    spawn fn -> listen() end # TODO: use spawn_link instead.?
  end

  def delete(subscrip) do
    :ets.delete(:subscrips, subscrip)
  end

  def broadcast(pid, topic, data) do
    Enum.map(all(nil), fn subscrip -> send pid, {:cast, subscrip, data} end)
  end

  def notify(subscrip, data) do
    case HTTPoison.get subscrip.url, subscrip.body, subscrip.headers do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        IO.puts body # TODO: possibly track successful messages
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        delete subscrip
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  defp listen do
    receive do
      {:cast, subscrip, data} -> cond do
        matches subscrip, data -> notify subscrip, data
      end
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
