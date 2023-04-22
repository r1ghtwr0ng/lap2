defmodule LAP2.Networking.Helpers.RelaySelector do
  @moduledoc """
  Contains functions for splitting up data into shares,
  then sending them via the appropriate relays.
  """

  require Logger

  @doc """
  Select several random neighbors via which to cast proxy discovery cloves.
  """
  @spec cast_proxy_discovery(binary, non_neg_integer, list, non_neg_integer) :: :ok | :error
  def cast_proxy_discovery(_data, _clove_seq, _random_neighbors, _clove_limit) do
    # TODO verify that there are enough random neighbors in the list
    # TODO select a number of random neighbors
    # TODO split data into 2 chunks via secure IDA
    # TODO serialise shares and wrap with Clove struct
    # TODO send outbound cloves (1:1 ratio of share_1 and share_2)
    :ok
  end

  @doc """
  Disperse the provided data and send it via the appropriate relays to the desired proxy.
  """
  @spec disperse_and_send(binary, non_neg_integer, non_neg_integer, list) :: :ok | :error
  def disperse_and_send(_data, _proxy_seq, _clove_seq, _relay_list) do
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
