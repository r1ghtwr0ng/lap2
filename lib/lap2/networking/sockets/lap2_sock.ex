defmodule LAP2.Networking.Sockets.Lap2Socket do
  alias LAP2.Networking.Sockets.UdpServer
  alias LAP2.Utils.ProtoBuf.CloveHelper

  # ---- Public functions ----
  @doc """
  Parse a received datagram.
  """
  @spec parse_dgram({String.t, non_neg_integer}, binary, atom) :: :ok | :err
  def parse_dgram(source, dgram, router_name) do
    IO.puts("[+] Lap2Socket: Received datagram #{inspect dgram}")
    # DEBUG: Sleep for 1 second to simulate (unrealistically large) processing time
    # Process.sleep(1000)
    # Deserialise dgram
    with {:ok, clove} <- CloveHelper.deserialise(dgram) do
      CloveHelper.handle_deserialised_clove(source, clove, router_name)
    else
      {:error, reason} ->
        IO.puts("[!] Lap2Socket: Error deserialising datagram: #{inspect reason}")
        :err
    end
  end

  @doc """
  Send a clove to a destination address and port.
  """
  @spec send_clove({String.t, non_neg_integer}, binary, map, atom, atom) :: :ok | :err
  def send_clove({dest_addr, port}, data, headers, udp_name, clove_type \\ :regular_proxy) do
    data
    |> CloveHelper.create_clove(headers, clove_type)
    |> CloveHelper.serialise()
    |> case do
      {:ok, dgram} -> UdpServer.send_dgram(udp_name, dgram, {dest_addr, port}); :ok
      {:error, reason} -> IO.puts("[!] Lap2Socket: Error serialising clove: #{inspect reason}"); :err
    end
  end
end
