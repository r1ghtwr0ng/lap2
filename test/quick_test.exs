alias LAP2.Networking.Router
alias LAP2.Utils.CloveHelper

port_range = 10_000..10_010
config = %{
  name: :lap2,
  router: %{
    clove_cache_size: 1000,
    clove_cache_ttl: 30000,
    proxy_limit: 20,
    proxy_policy: true,
    relay_routes_size: 5000,
    relay_routes_ttl: 1800000
  },
  udp_server: %{
    name: :router,
    lap2_addr: nil,
    max_dgram_handlers: 10,
    max_queue_size: 1000,
    queue_interval: 100,
    req_timeout: 50000,
    udp_port: 10000
  }
}

addresses = Enum.map(port_range, fn port -> {"127.0.0.1", port}; end)
configs = Enum.map(port_range, fn port -> %{config |
  name: String.to_atom("lap2_#{port}"),
  udp_server: %{config.udp_server |
    udp_port: port,
    name: String.to_atom("router_#{port}"),
    lap2_addr: "TEST_#{:crypto.hash(port)}"}; end)

seed_address = Enum.map(configs, fn config -> {config.router.lap2_addr, {"127.0.0.1", config.udp_server.udp_port}}; end)
pids = Enum.map(configs, fn config -> {:ok, pid} = LAP2.start(config); pid; end)
Enum.each(configs, fn config ->
  name = config.udp_server.name
  Router.update_config(config, name)
  Enum.each(Enum.take_random(seed_address, 4), fn  -> Router.append_dataset(seed, name); end); end)

hdr1 = %{clove_seq: CloveHelper.gen_seq_num(8), drop_probab: CloveHelper.gen_drop_probab(0.7, 1.0)}
hdr2 = %{clove_seq: CloveHelper.gen_seq_num(8), drop_probab: CloveHelper.gen_drop_probab(0.7, 1.0)}
hdr3 = %{clove_seq: CloveHelper.gen_seq_num(8), hop_count: 0, proxy_seq: CloveHelper.gen_seq_num(8)}
hdr4 = %{clove_seq: CloveHelper.gen_seq_num(8), hop_count: 0, proxy_seq: CloveHelper.gen_seq_num(8)}
hdr3 = %{proxy_seq: CloveHelper.gen_seq_num(8)}
hdr4 = %{proxy_seq: CloveHelper.gen_seq_num(8)}

headers = [hdr1, hdr2, hdr3, hdr4, hdr5, hdr6]
data = "TEST DATA"
cloves = Enum.map(headers, fn hdr -> data |> CloveHelper.set_headers(hdr) |> CloveHelper.set_checksum(); end)
serial = Enum.map(cloves, fn clove -> ProtoBuf.serialize(clove); end)
