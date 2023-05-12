defmodule LAP2.Networking.Sockets.Lap2Socket do
  @moduledoc """
  Module for serialising/deserialising ProtoBuf cloves and sending/receiving them over UDP.
  """

  require Logger
  alias LAP2.Networking.Sockets.TcpServer
  alias LAP2.Main.ServiceProviders
  alias LAP2.Utils.ProtoBuf.QueryHelper
  alias LAP2.Networking.Sockets.UdpServer
  alias LAP2.Utils.ProtoBuf.CloveHelper

  # ---- Public functions ----
  @doc """
  Parse a received datagram.
  """
  @spec parse_dgram({String.t(), non_neg_integer}, binary, atom) :: :ok | :error
  def parse_dgram(source, dgram, router_name) do
    # DEBUG: Sleep for 1 second to simulate (unrealistically large) processing time
    # Process.sleep(1000)
    # Deserialise dgram
    with {:ok, clove} <- CloveHelper.deserialise(dgram) do
      CloveHelper.handle_deserialised_clove(source, clove, router_name)
    else
      {:error, reason} ->
        Logger.error("[!] Lap2Socket: Error deserialising datagram: #{inspect(reason)}")
        :error
    end
  end

  @doc """
  Parse a received TCP segment.
  """
  @spec parse_segment(String.t(), binary, map) :: :ok | :error
  def parse_segment(conn_id, segment, registry_table) do
    # DEBUG: Sleep for 1 second to simulate (unrealistically large) processing time
    # Process.sleep(1000)
    # Deserialise segment
    with {:ok, query} <- QueryHelper.deserialise(segment) do
      ServiceProviders.route_tcp_query(query, conn_id, registry_table)
    else
      {:error, reason} ->
        Logger.error("[!] Lap2Socket: Error deserialising segment: #{inspect(reason)}")
        :error
    end
  end

  @doc """
  Send a clove to a destination address and port.
  """
  @spec send_clove({String.t(), non_neg_integer}, Clove.t(), atom) :: :ok | :error
  def send_clove({dest_addr, port}, clove, udp_name) do
    clove
    |> CloveHelper.serialise()
    |> case do
      {:ok, dgram} ->
        UdpServer.send_dgram(udp_name, dgram, {dest_addr, port})
        :ok

      {:error, reason} ->
        Logger.error("[!] Lap2Socket: Error serialising clove: #{inspect(reason)}")
        :error
    end
  end

  @doc """
  Reply to a TCP request with a response Query.
  """
  @spec respond_tcp(Query.t(), String.t(), atom) :: :ok | :error
  def respond_tcp(query, conn_id, tcp_name) do
    case QueryHelper.serialise(query) do
      {:ok, segment} ->
        Task.async(fn -> TcpServer.respond(conn_id, segment, tcp_name); end)
        :ok
      {:error, reason} ->
        Logger.error("[!] Lap2Socket: Error serialising query: #{inspect(reason)}")
        :error
    end
  end
  @doc """
  Send out a TCP request and wait for a response.
  """
  @spec send_tcp({String.t(), non_neg_integer}, Query.t(), map) :: :ok | :error
  def send_tcp({dest_addr, port}, query, registry_table) do
    case QueryHelper.serialise(query) do
      {:ok, segment} ->
        Task.async(fn -> TcpServer.send({dest_addr, port}, segment, registry_table); end)
        :ok
      {:error, reason} ->
        Logger.error("[!] Lap2Socket: Error serialising query: #{inspect(reason)}")
        :error
    end
  end
end
