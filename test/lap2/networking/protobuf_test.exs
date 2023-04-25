defmodule LAP2.Networking.ProtoBufTest do
  alias LAP2.Networking.ProtoBuf
  alias LAP2.Utils.ProtoBuf.CloveHelper

  use ExUnit.Case
  doctest LAP2.Networking.ProtoBuf

  describe "(Clove) serialise/1" do
    test "Test proxy discovery clove serialisation" do
      data = "TEST_DATA"
      # Packet serialisation
      hdr = %{clove_seq: 1, drop_probab: 0.7}
      # Create the clove
      clove = CloveHelper.create_clove(data, hdr, :proxy_discovery)
      # Expected serial outputs
      serial = [
        [
          [[], "\x1A", ["\a", "\b\x01\x15333?"]],
          "\b",
          ["\xC7", ["\xD0", ["\xA7", ["\xEC", "\x02"]]]]
        ],
        "\x12",
        ["\t", "TEST_DATA"]
      ]

      # Serialise the cloves
      assert {:ok, IO.iodata_to_binary(serial)} == ProtoBuf.serialise(clove)
    end

    test "Test proxy response clove serialisation" do
      data = "TEST_DATA"
      # Packet serialisation
      hdr = %{clove_seq: 2, hop_count: 0, proxy_seq: 4}
      # Create the clove
      clove = CloveHelper.create_clove(data, hdr, :proxy_response)
      # Expected serial outputs
      serial = [
        [
          [[], "\"", [<<4>>, <<8, 4, 16, 2>>]],
          "\b",
          [<<199>>, [<<208>>, [<<167>>, [<<236>>, <<2>>]]]]
        ],
        <<18>>,
        ["\t", "TEST_DATA"]
      ]

      # Serialise the cloves
      assert {:ok, IO.iodata_to_binary(serial)} == ProtoBuf.serialise(clove)
    end

    test "Test regular proxy clove serialisation" do
      data = "TEST_DATA"
      # Packet serialisation
      hdr = %{proxy_seq: 3}
      # Create the clove
      clove = CloveHelper.create_clove(data, hdr, :regular_proxy)
      # Expected serial outputs
      serial = [
        [[[], "*", [<<2>>, <<8, 3>>]], "\b", [<<199>>, [<<208>>, [<<167>>, [<<236>>, <<2>>]]]]],
        <<18>>,
        ["\t", "TEST_DATA"]
      ]

      # Serialise the cloves
      assert {:ok, IO.iodata_to_binary(serial)} == ProtoBuf.serialise(clove)
    end
  end

  describe "(Share) serialise/1" do
    test "Test proxy discovery share serialisation" do
      # Create the share
      share = %Share{
        message_id: 1,
        total_shares: 2,
        share_idx: 1,
        share_threshold: 2,
        key_share: %KeyShare{aes_key: <<1, 1, 1, 1>>, iv: <<1, 1, 1, 1>>, __uf__: []},
        data: <<1, 1, 1, 1>>,
        __uf__: []
      }

      # Expected serial outputs
      serial = [
        [
          [[[[[], "\b", <<1>>], <<16>>, <<2>>], <<24>>, <<1>>], " ", <<2>>],
          "*",
          ["\f", <<10, 4, 1, 1, 1, 1, 18, 4, 1, 1, 1, 1>>]
        ],
        "2",
        [<<4>>, <<1, 1, 1, 1>>]
      ]

      # Serialise the cloves
      assert {:ok, IO.iodata_to_binary(serial)} == ProtoBuf.serialise(share)
    end
  end

  describe "(Request) serialise/1" do
    test "Test initial key exchange serialisation" do
      # Packet serialisation
      request = %Request{
        hmac: 0,
        request_id: 0,
        request_type: "proxy_discovery",
        data: "TEST_DATA",
        crypto:
          {:init_ke,
           %KeyExchangeInit{
             identity: <<>>,
             ephemeral_pk: <<>>,
             generator: <<>>,
             ring_pk: <<>>,
             signature: <<>>,
             hmac_key: <<>>
           }}
      }

      # Expected serial outputs
      serial = [
        [[[], "*", [<<0>>, ""]], <<26>>, [<<15>>, "proxy_discovery"]],
        "\"",
        ["\t", "TEST_DATA"]
      ]

      # Serialise the cloves
      assert {:ok, IO.iodata_to_binary(serial)} == ProtoBuf.serialise(request)
    end

    test "Test key exchange response serialisation" do
      # Packet serialisation
      request = %Request{
        hmac: 0,
        request_id: 0,
        request_type: "discovery_response",
        data: "TEST_DATA",
        crypto:
          {:resp_ke,
           %KeyExchangeResponse{
             identity: <<>>,
             ephemeral_pk: <<>>,
             generator: <<>>,
             ring_pk: <<>>,
             signature: <<>>,
             ring_signature: <<>>,
             hmac_key: <<>>
           }}
      }

      # Expected serial outputs
      serial = [
        [[[], "2", [<<0>>, ""]], <<26>>, [<<18>>, "discovery_response"]],
        "\"",
        ["\t", "TEST_DATA"]
      ]

      # Serialise the cloves
      assert {:ok, IO.iodata_to_binary(serial)} == ProtoBuf.serialise(request)
    end

    test "Test final key exchange serialisation" do
      # Packet serialisation
      request = %Request{
        hmac: 0,
        request_id: 0,
        request_type: "key_exchange",
        data: "TEST_DATA",
        crypto:
          {:fin_ke,
           %KeyExchangeFinal{
             ring_signature: <<>>,
             hmac_key: <<>>
           }}
      }

      # Expected serial outputs
      serial = [
        [[[], ":", [<<0>>, ""]], <<26>>, ["\f", "key_exchange"]],
        "\"",
        ["\t", "TEST_DATA"]
      ]

      # Serialise the cloves
      assert {:ok, IO.iodata_to_binary(serial)} == ProtoBuf.serialise(request)
    end

    test "Test symmetric key communication serialisation" do
      # Packet serialisation
      request = %Request{
        hmac: 0,
        request_id: 0,
        request_type: "regular_proxy",
        data: "TEST_DATA",
        crypto:
          {:sym_key,
           %SymmetricKey{
             hmac_key: <<>>
           }}
      }

      # Expected serial outputs
      serial = [
        [[[], "J", [<<0>>, ""]], <<26>>, ["\r", "regular_proxy"]],
        "\"",
        ["\t", "TEST_DATA"]
      ]

      # Serialise the cloves
      assert {:ok, IO.iodata_to_binary(serial)} == ProtoBuf.serialise(request)
    end

    test "Test key rotation serialisation" do
      # Packet serialisation
      request = %Request{
        hmac: 0,
        request_id: 0,
        request_type: "regular_proxy",
        data: "TEST_DATA",
        crypto:
          {:key_rot,
           %KeyRotation{
             new_key: <<>>,
             hmac_key: <<>>
           }}
      }

      # Expected serial outputs
      serial = [
        [[[], "B", [<<0>>, ""]], <<26>>, ["\r", "regular_proxy"]],
        "\"",
        ["\t", "TEST_DATA"]
      ]

      # Serialise the cloves
      assert {:ok, IO.iodata_to_binary(serial)} == ProtoBuf.serialise(request)
    end
  end

  describe "(Clove) deserialise/2" do
    test "Test proxy discovery deserialisation" do
      # Serial data
      serial = <<26, 5, 21, 51, 51, 51, 63, 18, 9, 84, 69, 83, 84, 95, 68, 65, 84, 65>>
      # Expected deserial outputs
      clove = %Clove{
        data: "TEST_DATA",
        headers:
          {:proxy_discovery, %ProxyDiscoveryHeader{clove_seq: 0, drop_probab: 0.699999988079071}},
        checksum: 0
      }

      # Deserialise the cloves
      assert {:ok, clove} == ProtoBuf.deserialise(serial, Clove)
    end

    test "Test proxy response deserialisation" do
      # Serial data
      serial = <<34, 4, 8, 4, 16, 2, 18, 9, 84, 69, 83, 84, 95, 68, 65, 84, 65>>
      # Expected deserial outputs
      clove = %Clove{
        data: "TEST_DATA",
        headers:
          {:proxy_response,
           %ProxyResponseHeader{proxy_seq: 4, clove_seq: 2, hop_count: 0, __uf__: []}},
        checksum: 0
      }

      # Deserialise the cloves
      assert {:ok, clove} == ProtoBuf.deserialise(serial, Clove)
    end

    test "Test regular proxy deserialisation" do
      # Serial data
      serial = <<42, 2, 8, 3, 18, 9, 84, 69, 83, 84, 95, 68, 65, 84, 65>>
      # Expected deserial outputs
      clove = %Clove{
        data: "TEST_DATA",
        headers: {:regular_proxy, %RegularProxyHeader{proxy_seq: 3}},
        checksum: 0
      }

      # Deserialise the cloves
      assert {:ok, clove} == ProtoBuf.deserialise(serial, Clove)
    end
  end

  describe "(Share) deserialise/2" do
    test "Test proxy discovery deserialisation" do
      # Serial data
      serial =
        <<8, 1, 16, 2, 24, 1, 32, 2, 42, 12, 10, 4, 1, 1, 1, 1, 18, 4, 1, 1, 1, 1, 50, 4, 1, 1, 1,
          1>>

      # Expected deserial outputs
      share = %Share{
        message_id: 1,
        total_shares: 2,
        share_idx: 1,
        share_threshold: 2,
        key_share: %KeyShare{aes_key: <<1, 1, 1, 1>>, iv: <<1, 1, 1, 1>>, __uf__: []},
        data: <<1, 1, 1, 1>>,
        __uf__: []
      }

      # Deserialise the share
      assert {:ok, share} == ProtoBuf.deserialise(serial, Share)
    end
  end

  describe "(Request) deserialise/2" do
    test "Test initial key exchange deserialisation" do
      # Serial data
      serial =
        <<42, 0, 26, 15, 112, 114, 111, 120, 121, 95, 100, 105, 115, 99, 111, 118, 101, 114, 121,
          34, 9, 84, 69, 83, 84, 95, 68, 65, 84, 65>>

      # Expected deserialised outputs
      request = %Request{
        hmac: 0,
        request_id: 0,
        request_type: "proxy_discovery",
        data: "TEST_DATA",
        crypto:
          {:init_ke,
           %KeyExchangeInit{
             identity: <<>>,
             ephemeral_pk: <<>>,
             generator: <<>>,
             ring_pk: <<>>,
             signature: <<>>,
             hmac_key: <<>>
           }}
      }

      # Deserialise the request
      assert {:ok, request} == ProtoBuf.deserialise(serial, Request)
    end

    test "Test key exchange response deserialisation" do
      # Serial data
      serial =
        <<50, 0, 26, 18, 100, 105, 115, 99, 111, 118, 101, 114, 121, 95, 114, 101, 115, 112, 111,
          110, 115, 101, 34, 9, 84, 69, 83, 84, 95, 68, 65, 84, 65>>

      # Expected deserialised outputs
      request = %Request{
        hmac: 0,
        request_id: 0,
        request_type: "discovery_response",
        data: "TEST_DATA",
        crypto:
          {:resp_ke,
           %KeyExchangeResponse{
             identity: <<>>,
             ephemeral_pk: <<>>,
             generator: <<>>,
             ring_pk: <<>>,
             signature: <<>>,
             ring_signature: <<>>,
             hmac_key: <<>>
           }}
      }

      # Deserialise the request
      assert {:ok, request} == ProtoBuf.deserialise(serial, Request)
    end

    test "Test final key exchange deserialisation" do
      # Serial data
      serial =
        <<58, 0, 26, 12, 107, 101, 121, 95, 101, 120, 99, 104, 97, 110, 103, 101, 34, 9, 84, 69,
          83, 84, 95, 68, 65, 84, 65>>

      # Expected deserialised outputs
      request = %Request{
        hmac: 0,
        request_id: 0,
        request_type: "key_exchange",
        data: "TEST_DATA",
        crypto:
          {:fin_ke,
           %KeyExchangeFinal{
             ring_signature: <<>>,
             hmac_key: <<>>
           }}
      }

      # Deserialise the request
      assert {:ok, request} == ProtoBuf.deserialise(serial, Request)
    end

    test "Test symmetric key communication deserialisation" do
      # Serial data
      serial =
        <<74, 0, 26, 13, 114, 101, 103, 117, 108, 97, 114, 95, 112, 114, 111, 120, 121, 34, 9, 84,
          69, 83, 84, 95, 68, 65, 84, 65>>

      # Expected deserialised outputs
      request = %Request{
        hmac: 0,
        request_id: 0,
        request_type: "regular_proxy",
        data: "TEST_DATA",
        crypto:
          {:sym_key,
           %SymmetricKey{
             hmac_key: <<>>
           }}
      }

      # Deserialise the request
      assert {:ok, request} == ProtoBuf.deserialise(serial, Request)
    end

    test "Test key rotation deserialisation" do
      # Serial data
      serial =
        <<66, 0, 26, 13, 114, 101, 103, 117, 108, 97, 114, 95, 112, 114, 111, 120, 121, 34, 9, 84,
          69, 83, 84, 95, 68, 65, 84, 65>>

      # Expected deserialised outputs
      request = %Request{
        hmac: 0,
        request_id: 0,
        request_type: "regular_proxy",
        data: "TEST_DATA",
        crypto:
          {:key_rot,
           %KeyRotation{
             new_key: <<>>,
             hmac_key: <<>>
           }}
      }

      # Deserialise the request
      assert {:ok, request} == ProtoBuf.deserialise(serial, Request)
    end
  end
end
