defmodule LAP2.Main.RequestHandler do
  @moduledoc """
  Module for handling reconstructed requests from the Share Handler.
  Route to Proxy or Master module.
  """
  require Logger
  # alias LAP2.Utils.ProtoBuf.CloveHelper

  @doc """
  Handle a request from the Share Handler.
  """
  @spec handle_request() :: {:noreply, map}
  def handle_request() do
    IO.inspect("")
  end
end
