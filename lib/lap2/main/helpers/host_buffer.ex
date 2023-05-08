defmodule LAP2.Main.Helpers.HostBuffer do
  @moduledoc """
  Acts as a buffer abstraction for service hosts.
  Uses ShareHandler to reconstruct original service requests.
  Provides utility functions for deconstructing responses
  to the appropriate requests.
  """

  require Logger
  alias LAP2.Main.Master
  alias LAP2.Main.Helpers.ListenerHandler
  alias LAP2.Main.ConnectionSupervisor
  alias LAP2.Utils.ProtoBuf.CloveHelper
  alias LAP2.Utils.ProtoBuf.QueryHelper
  alias LAP2.Utils.ProtoBuf.ShareHelper
  alias LAP2.Main.StructHandlers.ShareHandler
  alias LAP2.Crypto.InformationDispersal.SecureIDA

  @doc """
  Attempt to reassemble a query from shares and send them to the appropriate service host.
  """
  @spec reassemble_query(Query.t(), non_neg_integer, map) :: :ok | :error
  def reassemble_query(%Query{ack: false,
      query_id: qid,
      data: data,
      headers: {:content_request, %ContentRequest{
        service_id: service_id
    }}} = query, proxy_seq, registry_table) do
    # TODO call the ShareHandler and attempt to reassemble the query
    # If reassembled, call ListenerHandler
    aux_data = %{
      query_id: qid,
      proxy_seq: proxy_seq
    }
    case ShareHandler.service_deliver(data, aux_data, registry_table.share_handler) do
      {:reconstructed, data, routing_data} ->
        case Master.service_lookup(service_id, registry_table.master) do
          {:ok, stream_id} ->
            query_ids = Enum.reduce(routing_data, [qid], fn %{query_id: q}, acc -> [q | acc]; end)
            Master.cache_query(query, aux_data, service_id, registry_table.master)
            ListenerHandler.deliver(stream_id, "query", data, query_ids, registry_table.master)

          {:error, reason} ->
            Logger.error("Service lookup failed: #{inspect reason}")
            :error
        end

      :cached -> Master.cache_query(query, aux_data, service_id, registry_table.master)

      :dropped -> :error
    end
  end
  # Matches query responses
  def reassemble_query(%Query{ack: true,
      query_id: qid,
      data: data,
      headers: {:remote_query, %RemoteQuery{
        service_id: service_id
    }}} = query, proxy_seq, registry_table) do
    # TODO call the ShareHandler and attempt to reassemble the response
    # If reassembled, call ListenerHandler
    aux_data = %{
      query_id: qid,
      proxy_seq: proxy_seq
    }
    case ShareHandler.service_deliver(data, aux_data, registry_table.share_handler) do
      {:reconstructed, data, routing_data} ->
        case Master.pop_return(qid, registry_table.master) do
          :error ->
            Logger.error("Service lookup failed: no return registered for QID #{qid}")
            :error

          service_id ->
            {:ok, stream_id} = Master.service_lookup(service_id, registry_table.master)
            query_ids = Enum.reduce(routing_data, [qid], fn %{query_id: q}, acc ->
              ret = Master.pop_return(q, registry_table.master) # Delete the query IDs from the map
              if ret == service_id, do: [ret | acc], else: Logger.error("Query ID not found in return values"); acc
            end)
            ListenerHandler.deliver(stream_id, "response", data, query_ids, registry_table.master)
        end

      :cached -> Master.cache_query(query, aux_data, service_id, registry_table.master)

      :dropped -> :error
    end
  end

  @doc """
  Disperse response data along the response list and send them back to the client.
  """
  @spec disperse_response(list(map), binary, map) :: :ok | :error
  def disperse_response(response_list, data, registry_table) do
    # TODO disperse into cloves, serialise and route via the response_list
    # Disperse the data into shares
    len = length(response_list)
    n = if len > 1, do: len, else: 2
    m = if n > 2, do: ceil(n / 2), else: 2
    shares = SecureIDA.disperse(data, n, m, CloveHelper.gen_seq_num())
    # Bind each share to a response
    Enum.zip(response_list, shares)
    |> Enum.map(fn {%{query: query} = resp, share} ->
      {:ok, serial} = ShareHelper.serialise(share)
      new_query = QueryHelper.build_response(query, serial)
      Map.put(resp, :query, new_query)
    end)
    |> ConnectionSupervisor.send_responses(registry_table)
  end

  @doc """
  Send out requests for remote service data.
  """
  @spec request_remote(list({String.t(), non_neg_integer}), binary, String.t(), map) :: :ok | :error
  def request_remote(intro_points, data, service_id, registry_table) do
    # Disperse the data into shares
    len = length(intro_points) * 2
    n = if len > 1, do: len, else: 2
    m = if n > 2, do: ceil(n / 2), else: 2
    shares = SecureIDA.disperse(data, n, m, CloveHelper.gen_seq_num())
    # Bind each share to an introduction point address, 2:1 ratio
    share_to_addr = List.duplicate(intro_points, 2)
    |> List.flatten()
    |> Enum.zip(shares)

    # Serialise the shares and build a list of Query structs, then send them
    Enum.map(share_to_addr, fn {{addr, port}, share} ->
      {:ok, serial} = ShareHelper.serialise(share)
      qid = CloveHelper.gen_seq_num()
      Master.register_return(qid, service_id, registry_table.master)
      QueryHelper.build_remote_query_header(addr, port, service_id)
      |> QueryHelper.build_query(qid, serial)
    end)
    |> ConnectionSupervisor.send_queries(registry_table)
    :ok
  end
end
