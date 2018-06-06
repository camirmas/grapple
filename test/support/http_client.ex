defmodule Grapple.Test.HttpClient do
  def get("NOT_FOUND", _headers, _options) do
    {:ok, %{status_code: 404}}
  end

  def get("ERROR", _headers, _options) do
    {:error, %{reason: ""}}
  end

  def get(_url, _headers, _options) do
    {:ok, %{status_code: 200, body: %{}}}
  end

  def post(_url, body, _headers, _options) do
    {:ok, %{status_code: 200, body: body}}
  end

  def put(_url, body, _headers, _options) do
    {:ok, %{status_code: 200, body: body}}
  end

  def delete(_url, _headers, _options) do
    {:ok, %{status_code: 200, body: %{}}}
  end
end
