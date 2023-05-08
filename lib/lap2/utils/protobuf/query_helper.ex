defmodule LAP2.Utils.ProtoBuf.QueryHelper do
  @moduledoc """
  Contains helper functions for generating and parsing ProtoBuf Query structs
  """

  alias LAP2.Networking.ProtoBuf

  @doc """
  Serialise a Query struct
  """
  @spec serialise(Query.t()) :: {:ok, binary} | {:error, :invalid_query}
  def serialise(query) do
    case ProtoBuf.serialise(query) do
      {:ok, data} ->
        {:ok, data}

      _ ->
        {:error, :invalid_query}
    end
  end

  @doc """
  Deserialise a Query struct
  """
  @spec deserialise(binary) :: {:ok, Query.t()} | {:error, :invalid_query}
  def deserialise(data) do
    case ProtoBuf.deserialise(data, Query) do
      {:ok, query} ->
        {:ok, query}

      _ ->
        {:error, :invalid_query}
    end
  end

  # ---- Struct Building ----
  @doc """
  Build an outgoing query struct
  """
  @spec build_query(tuple, non_neg_integer, binary) :: Query.t()
  def build_query(header, query_id, data) do
    %Query{
      query_id: query_id,
      data: data,
      ack: false,
      headers: header
    }
  end

  @doc """
  Set the ACK flag and replace the data with the response
  """
  @spec build_response(Query.t(), binary) :: Query.t()
  def build_response(query, data) do
    Map.put(query, :ack, true)
    |> Map.put(:data, data)
  end

  @doc """
  Build an introduction point establishment header
  """
  @spec build_establish_header(list(String.t())) ::
    {:establish_intro, EstablishIntroductionPoint.t()}
  def build_establish_header(service_ids) do
    {:establish_intro, %EstablishIntroductionPoint{
      service_ids: service_ids
    }}
  end

  @doc """
  Build an introduction point teardown header
  """
  @spec build_teardown_header() ::
    {:teardown_intro, TeardownIntroductionPoint.t()}
  def build_teardown_header() do
    {:teardown_intro, %TeardownIntroductionPoint{}}
  end

  @doc """
  Build a content request header
  """
  @spec build_content_request_header(String.t()) ::
    {:content_request, ContentRequest.t()}
  def build_content_request_header(service_id) do
    {:content_request, %ContentRequest{
      service_id: service_id
    }}
  end

  @doc """
  Build a remote query header
  """
  @spec build_remote_query_header(String.t(), non_neg_integer, String.t()) ::
    {:remote_query, RemoteQuery.t()} | {:error, :invalid_remote_query_header}
  def build_remote_query_header(address, port, service_id) do
    {:remote_query, %RemoteQuery{
      address: address,
      port: port,
      service_id: service_id
    }}
  end
end
