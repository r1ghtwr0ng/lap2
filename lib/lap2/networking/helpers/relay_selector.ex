defmodule LAP2.Networking.Helpers.RelaySelector do
  @moduledoc """
  Contains functions for splitting up data into shares,
  then sending them via the appropriate relays.
  """

  alias LAP2.Networking.Router
  alias LAP2.Utils.ProtoBuf.ShareHelper
  alias LAP2.Utils.ProtoBuf.CloveHelper
  alias LAP2.Crypto.InformationDispersal.SecureIDA

  require Logger

  @doc """
  Select several random neighbors via which to cast proxy discovery cloves.
  """
  @spec cast_proxy_discovery(binary, non_neg_integer, list, non_neg_integer, atom) :: :ok | :error
  def cast_proxy_discovery(_data, _clove_seq, random_neighbors, clove_limit, _router_name)
    when length(random_neighbors) < clove_limit or clove_limit < 2, do: :error

  def cast_proxy_discovery(data, clove_seq, random_neighbors, clove_limit, router_name) do
    # Split data into shares, then create cloves
    proxy_discovery_hdr = %{clove_seq: clove_seq, drop_probab: CloveHelper.gen_drop_probab(0.7, 1.0)}
    target_neighbors = Enum.take_random(random_neighbors, clove_limit)
    cloves = split_into_cloves(data, proxy_discovery_hdr, :proxy_discovery)

    # Send cloves to neighbors
    Enum.with_index(target_neighbors, fn neighbor, idx ->
      clove = Enum.at(cloves, Integer.mod(idx, length(cloves)))
      #Logger.info("CAST PROXY DISCOVERY OUTBOUND CLOVE (#{router_name})")
      Router.route_outbound_discovery(neighbor, clove, router_name)
    end)
    :ok
  end

  @doc """
  Disperse the provided data and send it via the appropriate relays to the desired proxy.
  """
  @spec disperse_and_send(binary, map, list, atom) :: :ok | :error
  def disperse_and_send(_data, _clove_header, relay_list, _router_name) when length(relay_list) < 2 do
    # Validate that there are enough relays in the list
    Logger.error("Not enough relays in list to send cloves")
    :error
  end
  def disperse_and_send(data, clove_header, relay_list, router_name) do
    # Split data into shares, then create cloves
    outbound = Enum.zip(Enum.take_random(relay_list, 2), split_into_cloves(data, clove_header, :proxy_response))

    # Send cloves via relays
    Enum.each(outbound, fn {relay, clove} ->
      #IO.inspect(clove, label: "DISPERSE AND SEND OUTBOUND CLOVE (#{router_name})")
      Router.route_outbound(relay, clove, router_name)
    end)
    :ok
  end

  # Split data into two shares and create cloves from them
  @spec split_into_cloves(binary, map, :proxy_discovery | :regular_proxy | :proxy_response) :: list
  defp split_into_cloves(data, clove_hdr, clove_type) do
    SecureIDA.disperse(data, 2, 2, CloveHelper.gen_seq_num())
    |> Enum.map(fn share ->
      {:ok, share_data} = ShareHelper.serialise(share)
      CloveHelper.create_clove(share_data, clove_hdr, clove_type)
    end)
  end
end
