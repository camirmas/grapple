defmodule Grapple do
  use Application

  def start(_type, _args) do
    Grapple.Supervisor.start_link []
  end
end
