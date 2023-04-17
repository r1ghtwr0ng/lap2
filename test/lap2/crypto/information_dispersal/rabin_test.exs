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
          data:
            "\0+\0J\0\xFA\0E\0\xF1\0X\0=\0\xE5\0\0\0\xFD\0\a\0\xFE\0I\0\x11\0\xFD\0\a\0\xFE\0H\0k",
          share_idx: 1
        },
        %{
          data:
            "\0\xE8\0\xFC\0q\0\0\0\xB5\0 \0\xDF\0j\0\xE5\0\xB6\0\x82\0\xCC\0\xFD\0\b\0\xB6\0\x82\0\xCC\x01\0\0s",
          share_idx: 2
        },
        %{
          data:
            "\0\x89\0\x88\0\xCE\0\x9B\0\xB9\0\xCC\0M\0\xB1\0 \0L\0\xE4\0\xDA\0\x8D\0W\0L\0\xE4\0\xDA\0\x92\0\d",
          share_idx: 3
        },
        %{
          data:
            "\0\x0F\0\xF0\0\x0F\0\x14\0\xFD\0Z\0\x89\0\xB9\0\xB4\0\xC0\0,\0'\0\xFB\0\xFE\0\xC0\0,\0'\x01\0\0\x8F",
          share_idx: 4
        }
      ]

      assert shares == RabinIDA.split(data, n, m)
    end

    test "Test with non-printable binary data" do
      data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 255, 255, 255, 255, 0, 0, 0, 0>>
      n = 8
      m = 4

      shares = [
        %{data: "\0\x06\0\x16\0\r\0\xFD\0\x04", share_idx: 1},
        %{data: "\0\"\0^\0\x02\0\xFB\0\x18", share_idx: 2},
        %{data: "\0f\0\x05\0\xDC\0\xF9\0H", share_idx: 3},
        %{data: "\0\xE4\06\0\x8D\0\xF7\0\xA0", share_idx: 4},
        %{data: "\0\xAD\0\x1A\0\n\0\xF5\0+", share_idx: 5},
        %{data: "\0\xD4\0\xDC\0H\0\xF3\0\xF7", share_idx: 6},
        %{data: "\0j\0\xA4\0:\0\xF1\0\r", share_idx: 7},
        %{data: "\0\x82\0\x9D\0\xD5\0\xEF\0|", share_idx: 8}
      ]

      assert shares == RabinIDA.split(data, n, m)
    end

    test "Test with short data, more shares" do
      data = "Short data"
      n = 12
      m = 12

      shares = [
        %{data: <<0, 203>>, share_idx: 1},
        %{data: <<0, 136>>, share_idx: 2},
        %{data: <<0, 205>>, share_idx: 3},
        %{data: <<0, 127>>, share_idx: 4},
        %{data: <<0, 217>>, share_idx: 5},
        %{data: <<0, 21>>, share_idx: 6},
        %{data: <<0, 2>>, share_idx: 7},
        %{data: <<0, 215>>, share_idx: 8},
        %{data: <<0, 99>>, share_idx: 9},
        %{data: <<0, 9>>, share_idx: 10},
        %{data: <<0, 25>>, share_idx: 11},
        %{data: <<1, 0>>, share_idx: 12}
      ]

      assert shares == RabinIDA.split(data, n, m)
    end
  end

  describe "reconstruct/1" do
    test "Test random 3/4 threshold reconstruction" do
      shares =
        Enum.take_random(
          [
            %{
              data:
                <<0, 43, 0, 74, 0, 250, 0, 69, 0, 241, 0, 88, 0, 61, 0, 229, 0, 0, 0, 253, 0, 7,
                  0, 254, 0, 73, 0, 17, 0, 253, 0, 7, 0, 254, 0, 72, 0, 107>>,
              share_idx: 1
            },
            %{
              data:
                <<0, 232, 0, 252, 0, 113, 0, 0, 0, 181, 0, 32, 0, 223, 0, 106, 0, 229, 0, 182, 0,
                  130, 0, 204, 0, 253, 0, 8, 0, 182, 0, 130, 0, 204, 1, 0, 0, 115>>,
              share_idx: 2
            },
            %{
              data:
                <<0, 137, 0, 136, 0, 206, 0, 155, 0, 185, 0, 204, 0, 77, 0, 177, 0, 32, 0, 76, 0,
                  228, 0, 218, 0, 141, 0, 87, 0, 76, 0, 228, 0, 218, 0, 146, 0, 127>>,
              share_idx: 3
            },
            %{
              data:
                <<0, 15, 0, 240, 0, 15, 0, 20, 0, 253, 0, 90, 0, 137, 0, 185, 0, 180, 0, 192, 0,
                  44, 0, 39, 0, 251, 0, 254, 0, 192, 0, 44, 0, 39, 1, 0, 0, 143>>,
              share_idx: 4
            }
          ],
          3
        )

      data = "Testing simple string data, not too short, not too long"
      assert {:ok, data} == RabinIDA.reconstruct(shares)
    end

    test "Test random 4/8 threshold reconstruction" do
      shares =
        Enum.take_random(
          [
            %{data: <<0, 6, 0, 22, 0, 15, 0, 59, 0, 158>>, share_idx: 1},
            %{data: <<0, 34, 0, 94, 0, 10, 0, 249, 0, 107>>, share_idx: 2},
            %{data: <<0, 102, 0, 5, 0, 238, 0, 187, 0, 152>>, share_idx: 3},
            %{data: <<0, 228, 0, 54, 0, 173, 0, 6, 0, 42>>, share_idx: 4},
            %{data: <<0, 173, 0, 26, 0, 60, 0, 96, 0, 40>>, share_idx: 5},
            %{data: <<0, 212, 0, 220, 0, 144, 0, 76, 0, 152>>, share_idx: 6},
            %{data: <<0, 106, 0, 164, 0, 156, 0, 79, 0, 127>>, share_idx: 7},
            %{data: <<0, 130, 0, 157, 0, 84, 0, 238, 0, 228>>, share_idx: 8}
          ],
          4
        )

      data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 255, 255, 255, 255, 65, 42, 73, 42>>
      assert {:ok, data} == RabinIDA.reconstruct(shares)
    end

    test "Test 12/12 threshold reconstruction" do
      shares = [
        %{data: <<0, 203>>, share_idx: 1},
        %{data: <<0, 136>>, share_idx: 2},
        %{data: <<0, 205>>, share_idx: 3},
        %{data: <<0, 127>>, share_idx: 4},
        %{data: <<0, 217>>, share_idx: 5},
        %{data: <<0, 21>>, share_idx: 6},
        %{data: <<0, 2>>, share_idx: 7},
        %{data: <<0, 215>>, share_idx: 8},
        %{data: <<0, 99>>, share_idx: 9},
        %{data: <<0, 9>>, share_idx: 10},
        %{data: <<0, 25>>, share_idx: 11},
        %{data: <<1, 0>>, share_idx: 12}
      ]

      data = "Short data"
      assert {:ok, data} == RabinIDA.reconstruct(shares)
    end
  end
end
