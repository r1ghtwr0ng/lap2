defmodule LAP2.Utils.CloveHelperTest do
  use ExUnit.Case

  alias LAP2.Utils.CloveHelper

  describe "verify_checksum/1" do
    test "Test valid checksum" do
      data = "TEST_DATA"
      checksum = CRC.crc_32(data)
      assert CloveHelper.verify_checksum(%{data: data, checksum: checksum}) == true
    end

    test "Test invalid checksum" do
      data = "TEST_DATA"
      checksum = CRC.crc_32(data)
      assert CloveHelper.verify_checksum(%{data: data, checksum: checksum + 1}) == false
    end
  end

  describe "create_clove/3" do
    test "Test proxy discovery clove creation" do
      data = "TEST_DATA"

      # Different types of headers
      hdr = %ProxyDiscoveryHeader{clove_seq: CloveHelper.gen_seq_num(), drop_probab: CloveHelper.gen_drop_probab(0.7, 1.0)}
      # How the clove should look like
      clove = %Clove{data: data, headers: {:proxy_discovery, hdr}, checksum: CRC.crc_32(data)}
      # Set headers
      result = CloveHelper.create_clove(data, hdr, :proxy_discovery)
      # Check if the clove is correct
      assert result == clove
    end

    test "Test proxy response clove creation" do
      data = "TEST_DATA"

      # Different types of headers
      hdr = %ProxyResponseHeader{clove_seq: CloveHelper.gen_seq_num(), proxy_seq: CloveHelper.gen_seq_num(), hop_count: 0}
      # How the clove should look like
      clove = %Clove{data: data, headers: {:proxy_response, hdr}, checksum: CRC.crc_32(data)}
      # Set headers
      result = CloveHelper.create_clove(data, hdr, :proxy_response)
      # Check if the clove is correct
      assert result == clove
    end

    test "Test regular proxy clove creation" do
      data = "TEST_DATA"

      # Different types of headers
      hdr = %RegularProxyHeader{proxy_seq: CloveHelper.gen_seq_num()}
      # How the clove should look like
      clove = %Clove{data: data, headers: {:regular_proxy, hdr}, checksum: CRC.crc_32(data)}
      # Set headers
      result = CloveHelper.create_clove(data, hdr, :regular_proxy)
      # Check if the clove is correct
      assert result == clove
    end
  end

  describe "handle_deserialised_clove/3" do
    test "Test valid clove" do
      data = "TEST DATA"
      valid_clove = %{
        data: data,
        headers: %{
          clove_seq: 1,
          drop_probab: 0.8
        },
        checksum: CRC.crc_32(data)
      }

      assert CloveHelper.handle_deserialised_clove({"127.0.0.1", 1234}, valid_clove, :router) == :ok
    end

    test "Test invalid clove" do
      data = "TEST DATA"
      invalid_clove = %{
        data: data,
        headers: %{
          clove_seq: 2,
          drop_probab: 1.5
        },
        checksum: CRC.crc_32(data)
      }

      assert CloveHelper.handle_deserialised_clove({"127.0.0.1", 1234}, invalid_clove, :router) == :err
    end
  end

  describe "verify_clove/1" do
    test "Test valid cloves" do
      data = "TEST_DATA"
      valid_clove = %{
        data: data,
        headers: %{
          drop_probab: 0.5,
          clove_seq: 1
        },
        checksum: CRC.crc_32(data)
      }

      assert CloveHelper.verify_clove(valid_clove)
    end

    test "Test invalid cloves" do
      data = "TEST DATA"
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

      assert CloveHelper.verify_clove(invalid_clove_probab) == false
      assert CloveHelper.verify_clove(invalid_clove_checksum) == false
      assert CloveHelper.verify_clove(invalid_clove) == false
    end
  end

  describe "verify_headers/1" do
    test "Valid headers" do
      valid_headers_1 = %{clove_seq: 1, drop_probab: 0.5}
      valid_headers_2 = %{clove_seq: 1, proxy_seq: 1, hop_count: 0}
      valid_headers_3 = %{proxy_seq: 1}

      assert CloveHelper.verify_headers(valid_headers_1)
      assert CloveHelper.verify_headers(valid_headers_2)
      assert CloveHelper.verify_headers(valid_headers_3)
    end

    test "Invalid headers" do
      invalid_headers_1 = %{clove_seq: 2, drop_probab: 1.5}
      invalid_headers_2 = %{random_value: 1.5}
      no_headers = %{}

      assert CloveHelper.verify_headers(invalid_headers_1) == false
      assert CloveHelper.verify_headers(invalid_headers_2) == false
      assert CloveHelper.verify_headers(no_headers) == false
    end
  end

  describe "gen_seq_num/0" do
    test "Test sequence number generation" do
      seq_num = CloveHelper.gen_seq_num()
      assert is_integer(seq_num)
    end
  end

  describe "gen_drop_probab/2" do
    test "Test drop probability generation" do
      min = 0.3
      max = 0.8
      drop_probab = CloveHelper.gen_drop_probab(min, max)
      assert is_float(drop_probab)
      assert drop_probab >= min
      assert drop_probab <= max
    end
  end
end
