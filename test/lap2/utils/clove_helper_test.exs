defmodule LAP2.Utils.CloveHelperTest do
  use ExUnit.Case

  alias LAP2.Utils.CloveHelper

  test "verify_checksum" do
    data = "TEST_DATA"
    checksum = CRC.crc_32(data)
    assert CloveHelper.verify_checksum(%{data: data, checksum: checksum}) == true
    assert CloveHelper.verify_checksum(%{data: data, checksum: checksum + 1}) == false
  end

  test "set_headers" do
    data = "TEST_DATA"

    # Different types of headers
    hdr_1 = %{clove_seq: CloveHelper.gen_seq_num(), drop_probab: CloveHelper.gen_drop_probab(0.7, 1.0)}
    hdr_2 = %{clove_seq: CloveHelper.gen_seq_num(), proxy_seq: CloveHelper.gen_seq_num(), hop_count: 0}
    hdr_3 = %{proxy_seq: CloveHelper.gen_seq_num()}
    # How the cloves should look like
    clove_1 = %{data: data, headers: hdr_1, checksum: CRC.crc_32(data)}
    clove_2 = %{data: data, headers: hdr_2, checksum: CRC.crc_32(data)}
    clove_3 = %{data: data, headers: hdr_3, checksum: CRC.crc_32(data)}
    # Set headers
    result_1 = CloveHelper.set_headers(data, hdr_1)
    result_2 = CloveHelper.set_headers(data, hdr_2)
    result_3 = CloveHelper.set_headers(data, hdr_3)
    # Check if the cloves are correct
    assert result_1 == clove_1
    assert result_2 == clove_2
    assert result_3 == clove_3
  end

  test "handle_deserialised_clove" do
    data = "TEST DATA"
    valid_clove = %{
      data: data,
      headers: %{
        clove_seq: 1,
        drop_probab: 0.8
      },
      checksum: CRC.crc_32(data)
    }

    invalid_clove = %{
      data: data,
      headers: %{
        clove_seq: 2,
        drop_probab: 1.5
      },
      checksum: CRC.crc_32(data)
    }

    assert CloveHelper.handle_deserialised_clove({"127.0.0.1", 1234}, valid_clove, :router) == :ok
    assert CloveHelper.handle_deserialised_clove({"127.0.0.1", 1234}, invalid_clove, :router) == :err
  end

  test "verify_clove" do
    data = "TEST_DATA"
    valid_clove = %{
      data: data,
      headers: %{
        drop_probab: 0.5,
        clove_seq: 1
      },
      checksum: CRC.crc_32(data)
    }

    invalid_clove_probab = %{
      data: data,
      headers: %{
        drop_probab: 1.5,
        clove_seq: 1
      },
      checksum: CRC.crc_32(data)
    }

    invalid_clove_checksum = %{
      data: data,
      headers: %{
        drop_probab: 0.5,
        clove_seq: 1
      },
      checksum: CRC.crc_32(data) + 1
    }

    invalid_clove = %{
      data: data,
      headers: %{
        drop_probab: 1.5,
        clove_seq: 1
      },
      checksum: CRC.crc_32(data) + 1
    }

    assert CloveHelper.verify_clove(valid_clove)
    assert CloveHelper.verify_clove(invalid_clove_probab) == false
    assert CloveHelper.verify_clove(invalid_clove_checksum) == false
    assert CloveHelper.verify_clove(invalid_clove) == false
  end

  test "verify_headers" do
    valid_headers_1 = %{clove_seq: 1, drop_probab: 0.5}
    valid_headers_2 = %{clove_seq: 1, proxy_seq: 1, hop_count: 0}
    valid_headers_3 = %{proxy_seq: 1}
    invalid_headers_1 = %{clove_seq: 2, drop_probab: 1.5}
    invalid_headers_2 = %{random_value: 1.5}
    no_headers = %{}

    assert CloveHelper.verify_headers(valid_headers_1)
    assert CloveHelper.verify_headers(valid_headers_2)
    assert CloveHelper.verify_headers(valid_headers_3)
    assert CloveHelper.verify_headers(invalid_headers_1) == false
    assert CloveHelper.verify_headers(invalid_headers_2) == false
    assert CloveHelper.verify_headers(no_headers) == false
  end

  test "gen_seq_num" do
    seq_num = CloveHelper.gen_seq_num()
    assert is_integer(seq_num)
  end

  test "gen_drop_probab" do
    min = 0.3
    max = 0.8
    drop_probab = CloveHelper.gen_drop_probab(min, max)
    assert is_float(drop_probab)
    assert drop_probab >= min
    assert drop_probab <= max
  end
end
