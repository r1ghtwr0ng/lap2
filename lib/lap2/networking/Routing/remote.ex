defmodule LAP2.Networking.Routing.Remote do
  @moduledoc """
  Helper functions for routing packets.
  """
  require Logger
  alias LAP2.Networking.LAP2Socket

  # ---- Public functions ----
  # MAJOR TODO: Update timestamps whenever accessed to prevent deletion
  # Deliver the clove to the appropriate receiver, either local or remote
  @spec route_clove({binary, integer}, list, map) :: :ok
  def route_clove( _receiver, [], _headers), do: :ok
  def route_clove(dest, [data | tail], headers) do
    IO.puts("[+] Delivering to remote")
    LAP2Socket.send_packet(dest, data, headers)
    route_clove(dest, tail, headers)
  end
end
