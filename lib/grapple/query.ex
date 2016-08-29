defmodule Grapple.Query do
  @moduledoc """
  This module is responsible for making queries to RethinkDB.
  """
  alias RethinkDB.Query
  alias Grapple.Store

  def get_queries do
    queries = Query.table("queries") |> Store.run
    queries.data
  end
end
