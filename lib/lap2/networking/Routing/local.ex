defmodule LAP2.Networking.Routing.Local do
  @moduledoc """
  Helper functions for routing packets.
  """
  require Logger

  # ---- Public functions ----
  # MAJOR TODO: Update timestamps whenever accessed to prevent deletion
  # Deliver the clove to the appropriate receiver, either local or remote
  @spec route_clove(pid, list, map, atom) :: :ok
  def route_clove(_receiver, [], _headers, _req_type), do: :ok
  def route_clove(dest, [data | tail], headers, req_type) do
    IO.puts("[+] Delivering to data processor")
    IO.inspect(data, label: "RECEIVED:")
    # TODO lookup global process naming rather than PID (in case of crash)
    # TODO implement DataProcessor.deliver
    # DataProcessor.deliver(dest, req_type, data, headers)
    route_clove(dest, tail, headers, req_type)
  end
end
