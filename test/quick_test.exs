alias LAP2.Networking.Router
alias LAP2.Utils.CloveHelper
alias LAP2.Networking.ProtoBuf

port_range = 10_000..10_010
# Configs
config = %{
  main_supervisor: %{
    name: :lap2_deamon
  },
  task_supervisor: %{
      name: :lap2_superv,
      max_children: 10
  },
  router: %{
    name: :router,
    lap2_addr: "test",
    clove_cache_size: 1000,
    clove_cache_ttl: 30000,
    proxy_limit: 20,
    proxy_policy: true,
    relay_routes_size: 5000,
    relay_routes_ttl: 1800000
  },
  udp_server: %{
    name: :udp_server,
    max_dgram_handlers: 10,
    max_queue_size: 1000,
    queue_interval: 100,
    req_timeout: 50000,
    udp_port: 10000
  }
}

configs = Enum.map(port_range, fn port -> %{config |
  main_supervisor: %{name: names[port].main_supervisor},
  task_supervisor: %{config.task_supervisor | name: names[port].task_supervisor},
  udp_server: %{config.udp_server | udp_port: port, name: names[port].udp_server},
  router: %{config.router | lap2_addr: "TEST_NAME_#{port}", name: names[port].router}}; end)

# Names
names = Enum.into(port_range, %{}, fn port -> {port, %{
    main_supervisor: String.to_atom("lap2_daemon_#{port}"),
    task_supervisor: String.to_atom("lap2_superv_#{port}"),
    udp_server: String.to_atom("udp_serv_#{port}"),
    router: String.to_atom("router_#{port}")}}; end)
addresses = Enum.map(port_range, fn port -> {"127.0.0.1", port}; end)
seed_address = Enum.map(configs, fn cfg -> {cfg.router.lap2_addr, {"127.0.0.1", cfg.udp_server.udp_port}}; end)

# Spawning processes
pids = Enum.map(configs, fn cfg -> {:ok, pid} = LAP2.start(cfg); pid; end)
Enum.each(configs, fn cfg ->
  name = cfg.router.name
  Router.update_config(cfg, name)
  Enum.each(Enum.take_random(seed_address, 4), fn {lap_seed, ip_seed} -> Router.append_dht(lap_seed, ip_seed, name); end); end)

# Packet serialisation
hdr1 = {:proxy_discovery, %{clove_seq: CloveHelper.gen_seq_num(), drop_probab: CloveHelper.gen_drop_probab(0.7, 1.0)}}
hdr2 = {:proxy_discovery, %{clove_seq: CloveHelper.gen_seq_num(), drop_probab: CloveHelper.gen_drop_probab(0.7, 1.0)}}
hdr3 = {:proxy_response, %{clove_seq: CloveHelper.gen_seq_num(), hop_count: 0, proxy_seq: CloveHelper.gen_seq_num()}}
hdr4 = {:proxy_response, %{clove_seq: CloveHelper.gen_seq_num(), hop_count: 0, proxy_seq: CloveHelper.gen_seq_num()}}
hdr5 = {:regular_proxy, %{proxy_seq: CloveHelper.gen_seq_num()}}
hdr6 = {:regular_proxy, %{proxy_seq: CloveHelper.gen_seq_num()}}

headers = [hdr1, hdr2, hdr3, hdr4, hdr5, hdr6]
data = "TEST DATA"
cloves = Enum.map(headers, fn {type, hdr} -> {type, CloveHelper.set_headers(data, hdr)}; end)
serial = Enum.map(cloves, fn {type, clove} -> ProtoBuf.serialise(clove, type); end)

# Kill them all
Enum.each(names, fn {_, name} -> LAP2.kill(name.main_supervisor); end)
