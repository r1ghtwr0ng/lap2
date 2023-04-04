# Get user input
defmodule Test do
  def prompts() do
    port = IO.gets("[+] Port: ") |> String.trim |> String.to_integer
    uid = IO.gets("[+] UID: ") |> String.trim
    bstrp_port = IO.gets("[+] Bootstrap port: ") |> String.trim |> String.to_integer
    bstrp_ip = IO.gets("[+] Bootstrap IP address: ") |> String.trim
    bstrp_addr = IO.gets("[+] Bootstrap LAP2 address: ") |> String.trim
    {port, uid, bstrp_port, bstrp_ip, bstrp_addr}
  end
end

alias LAP2.Networking.Router
alias LAP2.Utils.CloveHelper
alias LAP2.Networking.ProtoBuf

{port, uid, bstrp_port, bstrp_ip, bstrp_addr} = Test.prompts()

# Configs
config = %{
  main_supervisor: %{name: String.to_atom("lap2_daemon_#{uid}")},
  router: %{
    clove_cache_size: 1000,
    clove_cache_ttl: 30000,
    lap2_addr: "LAP2_ADDR_#{uid}",
    name: String.to_atom("router_#{uid}"),
    proxy_limit: 20,
    proxy_policy: true,
    registry_table: %{
      data_processor: String.to_atom("data_processor_#{uid}"),
      router: String.to_atom("router_#{uid}"),
      main_supervisor: String.to_atom("lap2_daemon_#{uid}"),
      task_supervisor: String.to_atom("lap2_superv_#{uid}"),
      tcp_server: String.to_atom("tcp_server_#{uid}"),
      udp_server: String.to_atom("udp_server_#{uid}")
    },
    relay_routes_size: 5000,
    relay_routes_ttl: 1800000
  },
  task_supervisor: %{max_children: 10, name: String.to_atom("lap2_superv_#{uid}")},
  tcp_server: %{
    max_queue_size: 1000,
    name: :tcp_server,
    queue_interval: 100,
    registry_table: %{
      data_processor: String.to_atom("data_processor_#{uid}"),
      router: String.to_atom("router_#{uid}"),
      main_supervisor: String.to_atom("lap2_daemon_#{uid}"),
      task_supervisor: String.to_atom("lap2_superv_#{uid}"),
      tcp_server: String.to_atom("tcp_server_#{uid}"),
      udp_server: String.to_atom("udp_server_#{uid}")
    },
    req_timeout: 50000,
    tcp_port: 3001
  },
  udp_server: %{
    max_dgram_handlers: 10,
    max_queue_size: 1000,
    name: String.to_atom("udp_server_#{uid}"),
    queue_interval: 100,
    registry_table: %{
      data_processor: String.to_atom("data_processor_#{uid}"),
      router: String.to_atom("router_#{uid}"),
      main_supervisor: String.to_atom("lap2_daemon_#{uid}"),
      task_supervisor: String.to_atom("lap2_superv_#{uid}"),
      tcp_server: String.to_atom("tcp_server_#{uid}"),
      udp_server: String.to_atom("udp_server_#{uid}")
    },
    req_timeout: 50000,
    udp_port: port
  },
  data_processor: %{
    name: :data_processor,
    registry_table: %{
      data_processor: String.to_atom("data_processor_#{uid}"),
      router: String.to_atom("router_#{uid}"),
      main_supervisor: String.to_atom("lap2_daemon_#{uid}"),
      task_supervisor: String.to_atom("lap2_superv_#{uid}"),
      tcp_server: String.to_atom("tcp_server_#{uid}"),
      udp_server: String.to_atom("udp_server_#{uid}")
    }
  },
}

# Spawn and bootstrap process
IO.puts("[+] Starting LAP2 daemon")
{:ok, _pid} = LAP2.start(config)
Router.update_config(config, config.router.name)
Router.append_dht(bstrp_addr, {bstrp_ip, bstrp_port}, config.router.name)

# Packet serialisation
hdr1 = {:proxy_discovery, %{clove_seq: CloveHelper.gen_seq_num(), drop_probab: CloveHelper.gen_drop_probab(0.7, 1.0)}}
hdr2 = {:proxy_response, %{clove_seq: CloveHelper.gen_seq_num(), hop_count: 0, proxy_seq: CloveHelper.gen_seq_num()}}
hdr3 = {:regular_proxy, %{proxy_seq: CloveHelper.gen_seq_num()}}
headers = [hdr1, hdr2, hdr3]

IO.puts("[+] Testing CloveHelper.set_headers")
cloves = Enum.map(headers, fn {type, hdr} -> {type, CloveHelper.set_headers("TEST_DATA", hdr)}; end)
IO.puts("[+] Testing ProtoBuf.serialise")
_serial = Enum.map(cloves, fn {type, clove} -> ProtoBuf.serialise(clove, type); end)

IO.puts("[+] Building cloves")
data = Enum.map(headers, fn {req_type, hdr} -> {req_type, hdr, IO.gets("[+] Data: ")}; end)

IO.puts("[+] Sending data")
{_, _, data} = Enum.at(data, 0)
clove_seq = LAP2.Utils.CloveHelper.gen_seq_num()
Router.route_outbound_discovery({bstrp_ip, bstrp_port}, clove_seq, data, config.router.name)

# Kill them all
IO.puts("[+] Enter to kill daemon")
IO.puts("[+] Killing LAP2 daemon")
LAP2.kill(config.main_supervisor.name)
