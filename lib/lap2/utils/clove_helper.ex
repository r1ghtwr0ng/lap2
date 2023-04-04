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
  def verify_checksum(%{checksum: chksum, data: data}) do
    # Verify the checksum
    chksum == CRC.crc_32(data)
  end

  @doc """
  Build the clove from the headers and data.
  """
  @spec set_headers(binary, map) :: map()
  def set_headers(data, headers) do
    # Set the headers for the clove
    %{data: data, headers: headers, checksum: CRC.crc_32(data)}
  end

  # ---- Clove handling functions ----
  @doc """
  Send out the deserialised clove for routing.
  """
  @spec handle_deserialised_clove({binary, integer}, map, atom) :: :ok | :err
  def handle_deserialised_clove(source, clove, router_name) do
    # Verify clove validity
    cond do
      verify_clove(clove) ->
        IO.puts("[+] CloveHelper: Valid clove") # DEBUG
        IO.inspect(clove, label: "Clove: ") # DEBUG
        # MAJOR TODO: Fix routing
        #Task.async(fn -> Router.route_inbound(source, clove, router_name); end)
        :ok

      true ->
        IO.puts("[-] CloveHelper: Invalid clove") # DEBUG
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
  @spec gen_seq_num() :: integer
  def gen_seq_num(), do: :crypto.strong_rand_bytes(8) |> :binary.decode_unsigned()
  @spec gen_drop_probab(float, float) :: float
  def gen_drop_probab(min, max), do: :rand.uniform() * (max - min) + min
end
