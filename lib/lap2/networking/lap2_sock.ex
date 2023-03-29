defmodule LAP2.Networking.LAP2Socket do
  alias LAP2.Utils.PacketHelper
  alias LAP2.Networking.Router
  alias LAP2.Networking.ProtoBuf
  alias LAP2.Networking.UdpServer

  # Client API
  def parse_packet(source, pkt) do
    IO.puts("[+] Received packet #{inspect pkt}")
    # DEBUG: Sleep for 1 second to simulate (unrealistically large) processing time
    # Process.sleep(1000)
    # Deserialise packet
    with {:ok, pkt} <- ProtoBuf.deserialise(pkt) do
      PacketHelper.handle_deserialised_pkt(source, pkt)
    else
      {:error, reason} ->
        IO.puts("Error deserialising packet: #{inspect reason}")
        :err
    end
  end

  @doc """
  Send a packet to a destination address and port.
  """
  # TODO LAP2Socket should recalculate checksum before sending!
  def send_packet({dest_addr, port}, data, headers) do
    data
    |> PacketHelper.set_headers(headers)
    |> PacketHelper.set_checksum()
    |> ProtoBuf.serialise()
    |> UdpServer.send_packet({dest_addr, port})
  end
end
