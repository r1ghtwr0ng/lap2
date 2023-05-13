defmodule LAP2.Main.ServiceProviders do
  @moduledoc """
  Module for registering and routing various services over the network.
  Anonymous proxies and introduction points perform:
    - Remote resource access
    - Remote resource response
  Hidden hosts these provide:
    - File transfer (upload/download)
    - Any other request/response based service
  """

  require Logger
  alias LAP2.Main.Master
  alias LAP2.Networking.Router
  alias LAP2.Networking.Resolver
  alias LAP2.Networking.Sockets.Lap2Socket
  alias LAP2.Utils.Generator
  alias LAP2.Utils.ProtoBuf.QueryHelper
  alias LAP2.Main.Helpers.HostBuffer
  alias LAP2.Main.Helpers.ListenerHandler
  alias LAP2.Main.ConnectionSupervisor

  @doc """
  Route a query to the appropriate service provider.
  """
  # ---- Inbound Request Routing ----
  @spec route_query(Query.t(), non_neg_integer, map) :: :ok | :error
  def route_query(%Query{ack: false,
    headers: {:establish_intro, %EstablishIntroductionPoint{
      service_ids: service_ids
  }}} = query, proxy_seq, registry_table) do
    # Handle received introduction point establishment request
    ConnectionSupervisor.modify_connection(proxy_seq, :intro_point, service_ids, registry_table.conn_supervisor)
    resp = [%{query: QueryHelper.build_response(query, <<>>), routing_info: %{proxy_seq: proxy_seq}}]
    ConnectionSupervisor.send_responses(resp, registry_table)
  end
  def route_query(%Query{ack: false,
    headers: {:teardown_intro, %TeardownIntroductionPoint{}}},
    proxy_seq, registry_table) do
    # Handle received introduction point teardown request
    ConnectionSupervisor.teardown_introduction_point(proxy_seq, registry_table)
  end
  def route_query(%Query{ack: false,
    headers: {:content_request, %ContentRequest{service_id: service_id}}} = query, proxy_seq, registry_table) do
    # Handle received content request
    Logger.info("[DEBUG] HOST (#{registry_table.master}): Received content request for Service ID: #{service_id}")
    HostBuffer.reassemble_query(query, proxy_seq, registry_table)
  end
  def route_query(%Query{ack: false,
    headers: {:remote_query, %RemoteQuery{
      address: ip,
      port: port,
      service_id: service_id # TODO: Remove this after debugging
  }}} = query, proxy_seq, registry_table) do
    Logger.info("[DEBUG] Anonymous Proxy (#{registry_table.master}): Sending remote request via TCP. Service ID: #{service_id}")
    # Handle received remote query request by anon proxy
    Router.save_query_relay(query.query_id, proxy_seq, registry_table.router)
    Lap2Socket.send_tcp({ip, port}, query, registry_table)
  end

  # ---- Inbound Response Routing ----
  def route_query(%Query{ack: true,
    headers: {:establish_intro, %EstablishIntroductionPoint{
  }}}, _proxy_seq, _registry_table) do
    # Handle acknowledgement for introduction point establishment request
    ListenerHandler.broadcast("Introduction point established", :kura_mi_qnko)
  end
  def route_query(%Query{ack: true,
    headers: {:teardown_intro, %TeardownIntroductionPoint{}}},
    _proxy_seq, _registry_table) do
    # Handle acknowledgement for introduction point teardown request
    ListenerHandler.broadcast("Introduction point torn down", :kura_mi_qnko)
  end
  def route_query(%Query{ack: true,
    query_id: query_id,
    data: data,
    headers: {:content_request, %ContentRequest{}}}, _proxy_seq, registry_table) do
    # Handle acknowledgement for content request
    # TODO route back to anonymous proxy, construct a response for RemoteQuery
    case Router.get_cached_query(query_id, registry_table.router) do
      {:ok, cached_query} ->
        Logger.info("[DEBUG] Introduction Point (#{registry_table.master}): Received query response from the host. Relaying to anonymous proxy via TCP.")
        return_query = QueryHelper.build_response(cached_query, data)
        Router.route_tcp(return_query, registry_table.router) # TODO implement this, looks up query_id => tcp_conn

      {:error, _} ->
        Logger.error("[DEBUG] Introduction Point (#{registry_table.master}): No cached query found for query_id: #{query_id}")
    end
  end
  def route_query(%Query{ack: true,
    headers: {:remote_query, %RemoteQuery{}}}
    = query, proxy_seq, registry_table) do
    # Handle acknowledgement for remote query
    Logger.info("[DEBUG] Client (#{registry_table.master}): Received remote query response from the proxy.")
    HostBuffer.reassemble_query(query, proxy_seq, registry_table)
  end

  # ---- TCP Routing ----
  @spec route_tcp_query(Query.t(), String.t(), map) :: :ok | :error
  def route_tcp_query(%Query{ack: false,
    data: data,
    headers: {:remote_query, %RemoteQuery{
      service_id: service_id
  }}} = query, conn_id, registry_table) do
    # Handle received remote query
    # TODO relay to remote service provider via TCP
    # TODO record TCP conn to query_id mapping
    new_qid = Generator.generate_integer(8)
    Router.cache_query(query, new_qid, conn_id, registry_table.router)
    conn_supervisor = registry_table.conn_supervisor
    case ConnectionSupervisor.service_lookup(service_id, conn_supervisor) do
      {:ok, proxy_seq} ->
        Logger.info("[DEBUG] Introduction Point (#{registry_table.master}): Sending query to host. Service ID: #{service_id}")
        QueryHelper.build_content_request_header(service_id)
        |> QueryHelper.build_query(new_qid, data)
        |> ConnectionSupervisor.send_query(proxy_seq, registry_table)

      {:error, _} ->
        Logger.error("[DEBUG] Introduction Point (#{registry_table.master}): Service not found. Service ID: #{service_id}")
        response = Jason.encode!(%{error: "Service not found"})
        |> String.to_charlist()
        |> :binary.list_to_bin()
        error_response = QueryHelper.build_response(query, response)
        _ = Router.get_cached_query(new_qid, registry_table.router) # Pop query from cache
        Lap2Socket.respond_tcp(error_response, conn_id, registry_table.tcp_server)
    end
  end
  def route_tcp_query(%Query{ack: true,
    headers: {:remote_query, %RemoteQuery{}}} = query, _conn_id, registry_table) do
    # Handle received remote query
    # TODO relay to remote service provider via TCP
    # TODO record TCP conn to query_id mapping
    case Router.get_query_relay(query.query_id, registry_table.router) do
      {:ok, proxy_seq} ->
        Logger.info("[DEBUG] Introduction Point (#{registry_table.master}): Routing response for Query ID: #{query.query_id}")
        ConnectionSupervisor.send_query(query, proxy_seq, registry_table)

      {:error, _} ->
        Logger.error("[DEBUG] Introduction Point (#{registry_table.master}): No cached query found for Query ID: #{query.query_id}")
        :error
    end
  end
  def route_tcp_query(%Query{ack: false,
    headers: {:dht_request, %DhtRequest{}}} = query, conn_id, registry_table) do
    # DHT request handling
    case Resolver.distribute_dht(query, registry_table.router) do
      {:ok, response_query} ->
        Lap2Socket.respond_tcp(response_query, conn_id, registry_table.tcp_server)
        :ok

      {:error, _} ->
        Logger.error("[DEBUG] Introduction Point (#{registry_table.master}): DHT request failed")
        :error
    end
  end
  def route_tcp_query(%Query{ack: true,
    query_id: qid,
    data: dht_data,
    headers: {:dht_request, %DhtRequest{}}}, _conn_id, registry_table) do
    # DHT response handling
    cond do
      Master.valid_dht_request?(qid, registry_table.master) ->
        Logger.info("[DEBUG] Host (#{registry_table.master}): Received DHT update request from master")
        Resolver.update_dht(dht_data, registry_table.router)
        :ok

      true ->
        Logger.error("[ERROR] Host (#{registry_table.master}): DHT update not requested")
        :error
    end
  end
end
