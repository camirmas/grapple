defmodule Grapple.Test.HttpClient do

  def get("NOT_FOUND", _headers) do
    {:ok, %{status_code: 404}}
  end
  def get("ERROR", _headers) do
    {:error, %{reason: ""}}
  end
  def get(_url, _headers) do
    {:ok, %{status_code: 200, body: %{}}}
  end

  def post(_url, _headers, body) do
    {:ok, %{status_code: 200, body: body}}
  end

  def put(_url, _headers, body) do
    {:ok, %{status_code: 200, body: body}}
  end

  def delete(_url, _headers) do
    {:ok, %{status_code: 200, body: %{}}}
  end

end
