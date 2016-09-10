defmodule Grapple.Subscription do
  defstruct [:url, :owner, :method, :life, :headers, :body, :query]

  table = :ets.new(:subscrips, [:set, :protected, :named_table])

  def create(subscription) do
    uuid = UUID.uuid4(:default)
    :ets.insert(:subscrips, {uuid, subscription, self})
  end

  def all(owner) do
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

  def broadcast(pid, data) do
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
end
