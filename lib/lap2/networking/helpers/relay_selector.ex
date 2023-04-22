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
    when length(random_neighbors) < clove_limit or clove_limit < 2 do
    # Validate that there is enough random neighbors to cast cloves
    :error
  end
  def cast_proxy_discovery(data, clove_seq, random_neighbors, clove_limit, router_name) do
    # Split data into shares, then create cloves
    proxy_discovery_hdr = %{clove_seq: clove_seq, drop_probab: CloveHelper.gen_drop_probab(0.7, 1.0)}
    target_neighbors = Enum.take_random(random_neighbors, clove_limit)
    cloves = SecureIDA.disperse(data, 2, 2, CloveHelper.gen_seq_num())
    |> Enum.map(fn share ->
      {:ok, share_data} = ShareHelper.serialise(share)
      CloveHelper.create_clove(share_data, proxy_discovery_hdr, :proxy_discovery) # TODO
    end)

    # Send cloves to neighbors
    Enum.with_index(target_neighbors, fn neighbor, idx ->
      clove = Enum.at(cloves, Integer.mod(idx, length(cloves)))
      Router.route_outbound(neighbor, clove, router_name)
    end)
    :ok
  end

  @doc """
  Disperse the provided data and send it via the appropriate relays to the desired proxy.
  """
  @spec disperse_and_send(binary, non_neg_integer, non_neg_integer, list, atom) :: :ok | :error
  def disperse_and_send(_data, _proxy_seq, _clove_seq, _relay_list, _router_name) do
    # TODO verify that there are enough relays in the list
    # TODO select an appropriate number of relays
    # TODO split data into the appropriate number of chunks (depends on how many relays will be used)
    # Note that currently, only 2 relays are used per path
    # Another note: 1/2 threshold reconstruction can be used in case packets are dropped on one path
    # TODO Serialise shares, wrap with Clove struct (while setting proxy_seq)
    # TODO send outbound cloves
    :ok
  end
end
