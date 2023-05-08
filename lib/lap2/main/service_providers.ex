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

  #alias LAP2.Main.Master
  alias LAP2.Main.Helpers.ListenerHandler
  alias LAP2.Utils.ProtoBuf.QueryHelper
  alias LAP2.Main.Helpers.HostBuffer
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
    headers: {:content_request, %ContentRequest{}}} = query, proxy_seq, registry_table) do
    # Handle received content request
    HostBuffer.reassemble_query(query, proxy_seq, registry_table)
  end
  def route_query(%Query{ack: false,
    query_id: _query_id,
    data: _data,
    headers: {:remote_query, %RemoteQuery{
      address: _address,
      port: _port,
      service_id: _service_id
  }}}, _proxy_seq, _registry_table) do
    # Handle received remote query
    # TODO relay to remote service provider via TCP
    # TODO record TCP conn to query_id mapping
  end

  # ---- Inbound Response Routing ----
  def route_query(%Query{ack: true,
    headers: {:establish_intro, %EstablishIntroductionPoint{
      service_ids: _service_ids
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
    query_id: _query_id,
    data: _data,
    headers: {:content_request, %ContentRequest{
      service_id: _service_id
  }}}, _proxy_seq, _registry_table) do
    # Handle acknowledgement for content request
    # TODO route back to anonymous proxy, construct a response for RemoteQuery
  end
  def route_query(%Query{ack: true,
    headers: {:remote_query, %RemoteQuery{}}}
    = query, proxy_seq, registry_table) do
    # Handle acknowledgement for remote query
    HostBuffer.reassemble_query(query, proxy_seq, registry_table)
  end
end
