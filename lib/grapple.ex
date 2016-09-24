defmodule Grapple do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Grapple.Supervisor.start_link []
  end
end
