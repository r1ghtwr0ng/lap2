defmodule LAP2.Networking.LAP2Socket do
  alias LAP2.Utils.CloveHelper
  alias LAP2.Networking.ProtoBuf
  alias LAP2.Networking.UdpServer

  # Client API
  @doc """
  Parse a received datagram.
  """
  @spec parse_dgram({binary, integer}, binary) :: :ok | :err
  def parse_dgram(source, dgram) do
    IO.puts("[+] Received datagram #{inspect dgram}")
    # DEBUG: Sleep for 1 second to simulate (unrealistically large) processing time
    # Process.sleep(1000)
    # Deserialise dgram
    with {:ok, clove} <- ProtoBuf.deserialise(dgram) do
      CloveHelper.handle_deserialised_clove(source, clove)
    else
      {:error, reason} ->
        IO.puts("Error deserialising datagram: #{inspect reason}")
        :err
    end
  end

  @doc """
  Send a clove to a destination address and port.
  """
  # TODO LAP2Socket should recalculate checksum before sending!
  @spec send_clove({binary, integer}, binary, map) :: :ok | :err
  def send_clove({dest_addr, port}, data, headers, clove_type \\ :regular_proxy_clove) do
    data
    |> CloveHelper.set_headers(headers)
    |> ProtoBuf.serialise(clove_type)
    |> case do
      {:ok, dgram} -> UdpServer.send_dgram(dgram, {dest_addr, port}); :ok
      {:error, reason} -> IO.puts("Error serialising clove: #{inspect reason}"); :err
    end
  end
end
