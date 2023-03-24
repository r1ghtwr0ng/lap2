defmodule LAP2.Networking.LAP2Socket do
  require CRC
  alias LAP2.Networking.Router
  alias LAP2.Networking.ProtoBuf
  alias LAP2.Networking.UdpServer

  # Client API
  def parse_packet(pkt) do
    IO.puts("[+] Received packet #{inspect pkt}")
    # DEBUG: Sleep for 1 second to simulate (unrealistically large) processing time
    # Process.sleep(1000)
    # Deserialise packet
    with {:ok, pkt} <- ProtoBuf.deserialise(pkt) do
      handle_deserialised_pkt(pkt)
    else
      {:error, reason} ->
        IO.puts("Error deserialising packet: #{inspect reason}")
        :err
    end
  end

  @doc """
  Send a packet to a destination address and port.
  """
  def send_packet({dest_addr, port}, opts, data) do
    data
    |> set_headers(opts)
    |> set_checksum()
    |> ProtoBuf.serialise()
    |> UdpServer.send_packet({dest_addr, port})
  end

  # ---- Helper functions ----
  defp handle_deserialised_pkt(pkt) do
    # Verify packet validity
    cond do
      verify_packet(pkt) ->
        IO.puts("[+] Valid packet") # DEBUG
        Task.async(fn -> Router.route_packet(pkt); end)
        :ok

      true ->
        IO.puts("Invalid packet") # DEBUG
        :err
    end
  end

  defp verify_packet(pkt) do
    # Verify the checksum
    verify_checksum(pkt) && verify_headers(pkt)
  end

  # Verify if the headers are valid
  defp verify_headers(%{seq_num: seq_num, drop_probab: drop_probab, data: data}) do
    # TODO check sequence number range
    # TODO check drop probability range
    # TODO check data length (must be padded to fixed size)
    true
  end

  defp set_headers(pkt, opts) do
    # Set sequence number
    # TODO
    headers = opts
    %{headers: headers, data: pkt}
  end

  # ---- Packet checksum ----
  defp verify_checksum(%{checksum: chksum, seq_num: seq_num, drop_probab: drop_probab, data: data}) do
    # Verify the checksum
    chksum == CRC.crc_32(seq_num <> drop_probab <> data)
  end

  defp set_checksum(%{seq_num: seq_num, drop_probab: drop_probab, data: data} = pkt) do
    # Compute and prepend checksum to packet
    Map.put(pkt, :checksum, CRC.crc_32(seq_num <> drop_probab <> data))
  end
end
