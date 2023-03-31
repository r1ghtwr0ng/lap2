defmodule LAP2.Utils.CloveHelper do
  @moduledoc """
  Helper functions for generating clove information, checksums, splitting and reconstructing cloves, padding, etc.
  """
  require CRC
  alias LAP2.Networking.Router

  # ---- Checksum functions ----
  @doc """
  Verify the checksum of the clove.
  """
  @spec verify_checksum(map) :: boolean
  def verify_checksum(%{checksum: chksum, seq_num: seq_num, drop_probab: drop_probab, data: data}) do
    # Verify the checksum
    chksum == CRC.crc_32(seq_num <> drop_probab <> data)
  end

  @doc """
  Calculate and add the checksum to the clove.
  """
  @spec set_checksum(map) :: map()
  def set_checksum(%{seq_num: seq_num, drop_probab: drop_probab, data: data} = clove) do
    # Compute and prepend checksum to clove
    Map.put(clove, :checksum, CRC.crc_32(seq_num <> drop_probab <> data))
  end

  @doc """
  Build the clove from the headers and data.
  """
  @spec set_headers(binary, map) :: map()
  def set_headers(data, headers) do
    # Set the headers for the clove
    Map.put(headers, :data, data)
  end

  # ---- Clove handling functions ----
  @doc """
  Send out the deserialised clove for routing.
  """
  @spec handle_deserialised_clove({binary, integer}, map) :: :ok | :err
  def handle_deserialised_clove(source, clove) do
    # Verify clove validity
    cond do
      verify_clove(clove) ->
        IO.puts("[+] Valid clove") # DEBUG
        Task.async(fn -> Router.route_inbound(source, clove); end)
        :ok

      true ->
        IO.puts("Invalid clove") # DEBUG
        :err
    end
  end

  @doc """
  Verify the clove's validity.
  """
  @spec verify_clove(map) :: boolean
  def verify_clove(clove) do
    # Verify the checksum
    # TODO verify the data length
    verify_checksum(clove) && verify_headers(clove)
  end

  @doc """
  Verify the clove's headers.
  """
  @spec verify_headers(map) :: boolean
  def verify_headers(%{drop_probab: drop_probab}) do
    drop_probab > 0.0 && drop_probab <= 1.0
  end
  def verify_headers(_), do: true

  # ---- Header field generation functions ----
  @spec gen_seq_num(integer) :: binary
  def gen_seq_num(len), do: :crypto.strong_rand_bytes(len)
  @spec gen_drop_probab(float, float) :: float
  def gen_drop_probab(min, max), do: :rand.uniform() * (max - min) + min
end
