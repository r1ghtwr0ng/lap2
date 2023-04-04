defmodule LAP2.Networking.LAP2Socket do
  alias LAP2.Utils.CloveHelper
  alias LAP2.Networking.ProtoBuf
  alias LAP2.Networking.UdpServer

  # ---- Public functions ----
  @doc """
  Parse a received datagram.
  """
  @spec parse_dgram({binary, integer}, binary, atom) :: :ok | :err
  def parse_dgram(source, dgram, router_name) do
    IO.puts("[+] LAP2Socket: Received datagram #{inspect dgram}")
    # DEBUG: Sleep for 1 second to simulate (unrealistically large) processing time
    # Process.sleep(1000)
    # Deserialise dgram
    with {:ok, clove} <- ProtoBuf.deserialise(dgram) do
      CloveHelper.handle_deserialised_clove(source, clove, router_name)
    else
      {:error, reason} ->
        IO.puts("[!] LAP2Socket: Error deserialising datagram: #{inspect reason}")
        :err
    end
  end

  @doc """
  Send a clove to a destination address and port.
  """
  @spec send_clove({binary, integer}, binary, map, atom, atom) :: :ok | :err
  def send_clove({dest_addr, port}, data, headers, udp_name, clove_type \\ :regular_proxy) do
    data
    |> CloveHelper.set_headers(headers)
    |> ProtoBuf.serialise(clove_type)
    |> IO.inspect(label: "Serialised clove: ")
    |> case do
      {:ok, dgram} -> UdpServer.send_dgram(udp_name, IO.iodata_to_binary(dgram), {dest_addr, port}); :ok # TODO fix errors
      {:error, reason} -> IO.puts("[!] LAP2Socket: Error serialising clove: #{inspect reason}"); :err
    end
  end
end
