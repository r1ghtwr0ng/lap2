defmodule LAP2.Crypto.InformationDispersal.RabinIDATest do
  use ExUnit.Case
  alias LAP2.Crypto.InformationDispersal.RabinIDA
  doctest LAP2.Crypto.InformationDispersal.RabinIDA

  describe "split/3" do
    test "Test with regular ASCII data" do
      data = "Testing simple string data, not too short, not too long"
      n = 4
      m = 3
      shares = [
        %{
          data: <<43, 74, 250, 69, 241, 88, 61, 229, 0, 253, 7, 254, 73, 17, 253, 7,
            254, 72, 107>>,
          share_id: 1
        },
        %{
          data: <<232, 252, 113, 0, 181, 32, 223, 106, 229, 182, 130, 204, 253, 8,
            182, 130, 204, 255, 1, 115>>,
          share_id: 2
        },
        %{
          data: <<137, 136, 206, 155, 185, 204, 77, 177, 32, 76, 228, 218, 141, 87,
            76, 228, 218, 146, 127>>,
          share_id: 3
        },
        %{
          data: <<15, 240, 15, 20, 253, 90, 137, 185, 180, 192, 44, 39, 251, 254, 192,
            44, 39, 255, 1, 143>>,
          share_id: 4
        }
      ]
      assert shares == RabinIDA.split(data, n, m)
    end

    test "Test with non-printable binary data" do
      data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 255, 255, 255, 255, 0, 0, 0, 0>>
      n = 8
      m = 4
      shares = [
        %{data: "\x06\x16\r\xFD\x04", share_id: 1},
        %{data: "\"^\x02\xFB\x18", share_id: 2},
        %{data: "f\x05\xDC\xF9H", share_id: 3},
        %{data: "\xE46\x8D\xF7\xA0", share_id: 4},
        %{data: "\xAD\x1A\n\xF5+", share_id: 5},
        %{data: "\xD4\xDCH\xF3\xF7", share_id: 6},
        %{data: "j\xA4:\xF1\r", share_id: 7},
        %{data: "\x82\x9D\xD5\xEF|", share_id: 8}
      ]
      assert shares == RabinIDA.split(data, n, m)
    end

    test "Test with short data, more shares" do
      data = "Short data"
      n = 12
      m = 12
      shares = [
        %{data: "\xCB", share_id: 1},
        %{data: "\x88", share_id: 2},
        %{data: "\xCD", share_id: 3},
        %{data: "\d", share_id: 4},
        %{data: "\xD9", share_id: 5},
        %{data: "\x15", share_id: 6},
        %{data: "\x02", share_id: 7},
        %{data: "\xD7", share_id: 8},
        %{data: "c", share_id: 9},
        %{data: "\t", share_id: 10},
        %{data: <<25>>, share_id: 11},
        %{data: <<255, 1>>, share_id: 12}
      ]
      assert shares == RabinIDA.split(data, n, m)
    end
  end

  describe "reconstruct/1" do
    test "Test random 3/4 threshold reconstruction" do
      shares = Enum.take_random([
        %{
          data: <<43, 74, 250, 69, 241, 88, 61, 229, 0, 253, 7, 254, 73, 17, 253, 7,
            254, 72, 107>>,
          share_id: 1
        },
        %{
          data: <<232, 252, 113, 0, 181, 32, 223, 106, 229, 182, 130, 204, 253, 8,
            182, 130, 204, 255, 1, 115>>,
          share_id: 2
        },
        %{
          data: <<137, 136, 206, 155, 185, 204, 77, 177, 32, 76, 228, 218, 141, 87,
            76, 228, 218, 146, 127>>,
          share_id: 3
        },
        %{
          data: <<15, 240, 15, 20, 253, 90, 137, 185, 180, 192, 44, 39, 251, 254, 192,
            44, 39, 255, 1, 143>>,
          share_id: 4
        }
      ], 3)
      data = "Testing simple string data, not too short, not too long"
      assert {:ok, data} == RabinIDA.reconstruct(shares)
    end

    test "Test random 4/8 threshold reconstruction" do
      shares = Enum.take_random([
        %{data: <<6, 22, 15, 59, 158>>, share_id: 1},
        %{data: <<34, 94, 10, 249, 107>>, share_id: 2},
        %{data: <<102, 5, 238, 187, 152>>, share_id: 3},
        %{data: <<228, 54, 173, 6, 42>>, share_id: 4},
        %{data: <<173, 26, 60, 96, 40>>, share_id: 5},
        %{data: <<212, 220, 144, 76, 152>>, share_id: 6},
        %{data: <<106, 164, 156, 79, 127>>, share_id: 7},
        %{data: <<130, 157, 84, 238, 228>>, share_id: 8}
      ], 4)
      data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 65, 42, 73, 42>>
      assert {:ok, data} == RabinIDA.reconstruct(shares)
    end

    test "Test 12/12 threshold reconstruction" do
      shares = [
        %{data: "\xCB", share_id: 1},
        %{data: "\x88", share_id: 2},
        %{data: "\xCD", share_id: 3},
        %{data: "\d", share_id: 4},
        %{data: "\xD9", share_id: 5},
        %{data: "\x15", share_id: 6},
        %{data: "\x02", share_id: 7},
        %{data: "\xD7", share_id: 8},
        %{data: "c", share_id: 9},
        %{data: "\t", share_id: 10},
        %{data: <<25>>, share_id: 11},
        %{data: <<255, 1>>, share_id: 12}
      ]
      data = "Short data"
      assert {:ok, data} == RabinIDA.reconstruct(shares)
    end
  end
end
