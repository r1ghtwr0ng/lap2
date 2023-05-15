sidebarNodes={"extras":[{"group":"","headers":[{"anchor":"modules","id":"Modules"}],"id":"api-reference","title":"API Reference"},{"group":"","headers":[{"anchor":"lightweight-anonymous-p2p-overlay-network","id":"Lightweight Anonymous P2P Overlay Network"},{"anchor":"introduction","id":"Introduction"},{"anchor":"about","id":"About"},{"anchor":"garlic-cast","id":"Garlic Cast"},{"anchor":"c-rsdake","id":"C-RSDAKE"},{"anchor":"usage","id":"Usage"},{"anchor":"task-list","id":"Task List"}],"id":"readme","title":"LAP2"}],"modules":[{"group":"","id":"LAP2.Services.FileIO","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"handle_call/3","id":"handle_call/3","title":"handle_call(arg1, from, state)"},{"anchor":"init/1","id":"init/1","title":"init(registry_table)"},{"anchor":"parse_cmd/2","id":"parse_cmd/2","title":"parse_cmd(json_data, serv_id)"},{"anchor":"request_file/6","id":"request_file/6","title":"request_file(intro_points, remote_serv_id, filename, save_location, serv_id, fragment_idx \\\\ 0)"},{"anchor":"run_service/1","id":"run_service/1","title":"run_service(master_name)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"},{"anchor":"stop_service/1","id":"stop_service/1","title":"stop_service(serv_id)"}]}],"sections":[],"title":"LAP2.Services.FileIO"},{"group":"","id":"LAP2.Main.ConnectionSupervisor","nested_context":"LAP2.Main","nested_title":".ConnectionSupervisor","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"debug/1","id":"debug/1","title":"debug(name)"},{"anchor":"deliver_inbound/3","id":"deliver_inbound/3","title":"deliver_inbound(data, proxy_seq, registry_table)"},{"anchor":"establish_proxy/1","id":"establish_proxy/1","title":"establish_proxy(registry_table)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"modify_connection/4","id":"modify_connection/4","title":"modify_connection(proxy_seq, atom, service_ids, conn_supervisor)"},{"anchor":"proxy_established/2","id":"proxy_established/2","title":"proxy_established(proxy_seq, registry_table)"},{"anchor":"remove_proxy/2","id":"remove_proxy/2","title":"remove_proxy(proxy_seq, registry_table)"},{"anchor":"request_introduction_point/2","id":"request_introduction_point/2","title":"request_introduction_point(service_ids, registry_table)"},{"anchor":"request_introduction_point/3","id":"request_introduction_point/3","title":"request_introduction_point(listener_id, service_ids, registry_table)"},{"anchor":"send_queries/2","id":"send_queries/2","title":"send_queries(queries, registry_table)"},{"anchor":"send_query/3","id":"send_query/3","title":"send_query(query, proxy_seq, registry_table)"},{"anchor":"send_responses/2","id":"send_responses/2","title":"send_responses(response_list, registry_table)"},{"anchor":"service_lookup/2","id":"service_lookup/2","title":"service_lookup(service_id, name)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"},{"anchor":"successful_key_rotation/2","id":"successful_key_rotation/2","title":"successful_key_rotation(proxy_seq, registry_table)"},{"anchor":"teardown_introduction_point/2","id":"teardown_introduction_point/2","title":"teardown_introduction_point(proxy_seq, registry_table)"}]}],"sections":[],"title":"LAP2.Main.ConnectionSupervisor"},{"group":"","id":"LAP2.Main.ServiceProviders","nested_context":"LAP2.Main","nested_title":".ServiceProviders","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"route_query/3","id":"route_query/3","title":"route_query(query, proxy_seq, registry_table)"},{"anchor":"route_tcp_query/3","id":"route_tcp_query/3","title":"route_tcp_query(query, conn_id, registry_table)"}]}],"sections":[],"title":"LAP2.Main.ServiceProviders"},{"group":"","id":"LAP2.Main.Helpers.HostBuffer","nested_context":"LAP2.Main.Helpers","nested_title":".HostBuffer","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"disperse_response/3","id":"disperse_response/3","title":"disperse_response(response_list, data, registry_table)"},{"anchor":"reassemble_query/3","id":"reassemble_query/3","title":"reassemble_query(query, proxy_seq, registry_table)"},{"anchor":"request_remote/5","id":"request_remote/5","title":"request_remote(intro_points, data, service_id, listener_id, registry_table)"}]}],"sections":[],"title":"LAP2.Main.Helpers.HostBuffer"},{"group":"","id":"LAP2.Main.Helpers.ListenerHandler","nested_context":"LAP2.Main.Helpers","nested_title":".ListenerHandler","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"broadcast/2","id":"broadcast/2","title":"broadcast(data, master_name)"},{"anchor":"deliver/5","id":"deliver/5","title":"deliver(listener_id, type, data, query_ids, master_name)"},{"anchor":"deliver_to_listener/2","id":"deliver_to_listener/2","title":"deliver_to_listener(listener_id, cmd)"}]}],"sections":[],"title":"LAP2.Main.Helpers.ListenerHandler"},{"group":"","id":"LAP2.Networking.Sockets.TcpServer","nested_context":"LAP2.Networking.Sockets","nested_title":".TcpServer","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"respond/3","id":"respond/3","title":"respond(conn_id, data, name)"},{"anchor":"send/3","id":"send/3","title":"send(arg, data, registry_table)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"},{"anchor":"terminate/2","id":"terminate/2","title":"terminate(reason, arg2)"}]}],"sections":[],"title":"LAP2.Networking.Sockets.TcpServer"},{"group":"","id":"LAP2.Utils.Generator","nested_context":"LAP2.Utils","nested_title":".Generator","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"generate_float/2","id":"generate_float/2","title":"generate_float(min, max)"},{"anchor":"generate_hex/1","id":"generate_hex/1","title":"generate_hex(byte_length)"},{"anchor":"generate_integer/1","id":"generate_integer/1","title":"generate_integer(byte_length)"}]}],"sections":[],"title":"LAP2.Utils.Generator"},{"group":"","id":"LAP2.Utils.ProtoBuf.QueryHelper","nested_context":"LAP2.Utils.ProtoBuf","nested_title":".QueryHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"build_content_request_header/1","id":"build_content_request_header/1","title":"build_content_request_header(service_id)"},{"anchor":"build_dht_request_header/0","id":"build_dht_request_header/0","title":"build_dht_request_header()"},{"anchor":"build_establish_header/1","id":"build_establish_header/1","title":"build_establish_header(service_ids)"},{"anchor":"build_query/3","id":"build_query/3","title":"build_query(header, query_id, data)"},{"anchor":"build_remote_query_header/3","id":"build_remote_query_header/3","title":"build_remote_query_header(address, port, service_id)"},{"anchor":"build_response/2","id":"build_response/2","title":"build_response(query, data)"},{"anchor":"build_teardown_header/0","id":"build_teardown_header/0","title":"build_teardown_header()"},{"anchor":"deserialise/1","id":"deserialise/1","title":"deserialise(data)"},{"anchor":"serialise/1","id":"serialise/1","title":"serialise(query)"}]}],"sections":[],"title":"LAP2.Utils.ProtoBuf.QueryHelper"},{"group":"Cryptography","id":"LAP2.Crypto.CryptoManager","nested_context":"LAP2.Crypto","nested_title":".CryptoManager","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"add_crypto_struct/3","id":"add_crypto_struct/3","title":"add_crypto_struct(crypto_struct, proxy_seq, name)"},{"anchor":"add_temp_crypto_struct/3","id":"add_temp_crypto_struct/3","title":"add_temp_crypto_struct(crypto_struct, clove_seq, name)"},{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"debug_crypto_structs/1","id":"debug_crypto_structs/1","title":"debug_crypto_structs(name)"},{"anchor":"decrypt_request/3","id":"decrypt_request/3","title":"decrypt_request(enc_request, proxy_seq, name)"},{"anchor":"delete_temp_crypto/2","id":"delete_temp_crypto/2","title":"delete_temp_crypto(clove_seq, name)"},{"anchor":"encrypt_request/3","id":"encrypt_request/3","title":"encrypt_request(data, proxy_seq, name)"},{"anchor":"get_crypto_struct/2","id":"get_crypto_struct/2","title":"get_crypto_struct(name, proxy_seq)"},{"anchor":"get_identity/1","id":"get_identity/1","title":"get_identity(name)"},{"anchor":"get_temp_crypto_struct/2","id":"get_temp_crypto_struct/2","title":"get_temp_crypto_struct(clove_seq, name)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"remove_crypto_struct/2","id":"remove_crypto_struct/2","title":"remove_crypto_struct(proxy_seq, name)"},{"anchor":"rotate_keys/3","id":"rotate_keys/3","title":"rotate_keys(crypto_struct, proxy_seq, name)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"}]}],"sections":[],"title":"LAP2.Crypto.CryptoManager"},{"group":"Cryptography","id":"LAP2.Crypto.Constructions.ClaimableRS","nested_context":"LAP2.Crypto.Constructions","nested_title":".ClaimableRS","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"crs_claim/3","id":"crs_claim/3","title":"crs_claim(ring_idx, sk, sag)"},{"anchor":"crs_gen/0","id":"crs_gen/0","title":"crs_gen()"},{"anchor":"crs_sign/4","id":"crs_sign/4","title":"crs_sign(ring_idx, sk, ring, msg)"},{"anchor":"crs_vrfy/2","id":"crs_vrfy/2","title":"crs_vrfy(sag, msg)"},{"anchor":"crs_vrfy_claim/3","id":"crs_vrfy_claim/3","title":"crs_vrfy_claim(arg1, sag, arg3)"},{"anchor":"rs_gen/0","id":"rs_gen/0","title":"rs_gen()"},{"anchor":"rs_sign/4","id":"rs_sign/4","title":"rs_sign(ring_idx, sk, ring, msg)"},{"anchor":"rs_vrfy/2","id":"rs_vrfy/2","title":"rs_vrfy(sag, msg)"},{"anchor":"sag_to_charlist/1","id":"sag_to_charlist/1","title":"sag_to_charlist(sag)"}]}],"sections":[],"title":"LAP2.Crypto.Constructions.ClaimableRS"},{"group":"Cryptography","id":"LAP2.Crypto.Constructions.CryptoNifs","nested_context":"LAP2.Crypto.Constructions","nested_title":".CryptoNifs","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"commit_gen/2","id":"commit_gen/2","title":"commit_gen(sk, rand)"},{"anchor":"commit_vrfy/3","id":"commit_vrfy/3","title":"commit_vrfy(sk, rand, com)"},{"anchor":"prf_eval/2","id":"prf_eval/2","title":"prf_eval(sk, data)"},{"anchor":"prf_gen/1","id":"prf_gen/1","title":"prf_gen(n)"},{"anchor":"rs_nif_gen/0","id":"rs_nif_gen/0","title":"rs_nif_gen()"},{"anchor":"rs_nif_sign/4","id":"rs_nif_sign/4","title":"rs_nif_sign(idx, sk, ring, msg)"},{"anchor":"rs_nif_vrfy/4","id":"rs_nif_vrfy/4","title":"rs_nif_vrfy(chal, ring, resp, msg)"},{"anchor":"standard_signature_gen/0","id":"standard_signature_gen/0","title":"standard_signature_gen()"},{"anchor":"standard_signature_sign/3","id":"standard_signature_sign/3","title":"standard_signature_sign(sk, msg, rand)"},{"anchor":"standard_signature_vrfy/3","id":"standard_signature_vrfy/3","title":"standard_signature_vrfy(sig, vk, msg)"}]}],"sections":[],"title":"LAP2.Crypto.Constructions.CryptoNifs"},{"group":"Cryptography","id":"LAP2.Crypto.Helpers.CryptoStructHelper","nested_context":"LAP2.Crypto.Helpers","nested_title":".CryptoStructHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"ack_key_rotation/3","id":"ack_key_rotation/3","title":"ack_key_rotation(proxy_seq, response_id, crypto_manager)"},{"anchor":"check_hmac/1","id":"check_hmac/1","title":"check_hmac(req)"},{"anchor":"gen_fin_crypto/3","id":"gen_fin_crypto/3","title":"gen_fin_crypto(arg1, temp_struct, crypto_mgr)"},{"anchor":"gen_init_crypto/2","id":"gen_init_crypto/2","title":"gen_init_crypto(request_id, crypto_mgr)"},{"anchor":"gen_key_rotation/2","id":"gen_key_rotation/2","title":"gen_key_rotation(proxy_seq, crypto_mgr_name)"},{"anchor":"gen_request/5","id":"gen_request/5","title":"gen_request(proxy_seq, request_id, request_type, data, crypto_mgr)"},{"anchor":"gen_resp_crypto/2","id":"gen_resp_crypto/2","title":"gen_resp_crypto(_, _)"},{"anchor":"gen_resp_crypto/3","id":"gen_resp_crypto/3","title":"gen_resp_crypto(arg, request_id, crypto_mgr)"},{"anchor":"set_hmac/1","id":"set_hmac/1","title":"set_hmac(request)"},{"anchor":"verify_ring_signature/3","id":"verify_ring_signature/3","title":"verify_ring_signature(crypto_hdr, proxy_seq, crypto_mgr)"}]}],"sections":[],"title":"LAP2.Crypto.Helpers.CryptoStructHelper"},{"group":"Cryptography","id":"LAP2.Crypto.InformationDispersal.RabinIDA","nested_context":"LAP2.Crypto.InformationDispersal","nested_title":".RabinIDA","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"decode_double_byte/1","id":"decode_double_byte/1","title":"decode_double_byte(bytes)"},{"anchor":"encode_double_byte/1","id":"encode_double_byte/1","title":"encode_double_byte(bytes)"},{"anchor":"reconstruct/1","id":"reconstruct/1","title":"reconstruct(shares)"},{"anchor":"split/3","id":"split/3","title":"split(data, n, m)"}]}],"sections":[],"title":"LAP2.Crypto.InformationDispersal.RabinIDA"},{"group":"Cryptography","id":"LAP2.Crypto.InformationDispersal.SecureIDA","nested_context":"LAP2.Crypto.InformationDispersal","nested_title":".SecureIDA","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"disperse/4","id":"disperse/4","title":"disperse(data, n, m, message_id)"},{"anchor":"reconstruct/1","id":"reconstruct/1","title":"reconstruct(shares)"}]}],"sections":[],"title":"LAP2.Crypto.InformationDispersal.SecureIDA"},{"group":"Cryptography","id":"LAP2.Crypto.KeyExchange.C_RSDAKE","nested_context":"LAP2.Crypto.KeyExchange","nested_title":".C_RSDAKE","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:crypto_state/0","id":"crypto_state/0","title":"crypto_state()"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"finalise/3","id":"finalise/3","title":"finalise(identity, crypto_state, recv_resp)"},{"anchor":"initialise/1","id":"initialise/1","title":"initialise(identity)"},{"anchor":"respond/3","id":"respond/3","title":"respond(identity, arg2, recv_init)"},{"anchor":"verify_final/3","id":"verify_final/3","title":"verify_final(identity, crypto_state, arg3)"}]}],"sections":[],"title":"LAP2.Crypto.KeyExchange.C_RSDAKE"},{"group":"Cryptography","id":"LAP2.Crypto.KeyExchange.RSDAKE","nested_context":"LAP2.Crypto.KeyExchange","nested_title":".RSDAKE","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:crypto_state/0","id":"crypto_state/0","title":"crypto_state()"},{"anchor":"t:rsdake_final/0","id":"rsdake_final/0","title":"rsdake_final()"},{"anchor":"t:rsdake_init/0","id":"rsdake_init/0","title":"rsdake_init()"},{"anchor":"t:rsdake_resp/0","id":"rsdake_resp/0","title":"rsdake_resp()"},{"anchor":"t:sag/0","id":"sag/0","title":"sag()"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"finalise/3","id":"finalise/3","title":"finalise(identity, crypto_state, recv_resp)"},{"anchor":"initialise/1","id":"initialise/1","title":"initialise(identity)"},{"anchor":"respond/3","id":"respond/3","title":"respond(identity, lt_keys, recv_init)"},{"anchor":"verify_final/3","id":"verify_final/3","title":"verify_final(identity, crypto_state, map)"}]}],"sections":[],"title":"LAP2.Crypto.KeyExchange.RSDAKE"},{"group":"Cryptography","id":"LAP2.Crypto.Padding.PKCS7","nested_context":"LAP2.Crypto.Padding","nested_title":".PKCS7","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"pad/2","id":"pad/2","title":"pad(data, len)"},{"anchor":"unpad/1","id":"unpad/1","title":"unpad(data)"}]}],"sections":[],"title":"LAP2.Crypto.Padding.PKCS7"},{"group":"Networking","id":"LAP2.Networking.ProtoBuf","nested_context":"LAP2.Networking","nested_title":".ProtoBuf","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"deserialise/2","id":"deserialise/2","title":"deserialise(data, struct_type)"},{"anchor":"serialise/1","id":"serialise/1","title":"serialise(struct)"}]}],"sections":[],"title":"LAP2.Networking.ProtoBuf"},{"group":"Networking","id":"LAP2.Networking.Resolver","nested_context":"LAP2.Networking","nested_title":".Resolver","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"build_dht_query/0","id":"build_dht_query/0","title":"build_dht_query()"},{"anchor":"distribute_dht/2","id":"distribute_dht/2","title":"distribute_dht(query, router_name)"},{"anchor":"resolve_addr/2","id":"resolve_addr/2","title":"resolve_addr(addr, dht)"},{"anchor":"update_dht/2","id":"update_dht/2","title":"update_dht(dht_data, router_name)"}]}],"sections":[],"title":"LAP2.Networking.Resolver"},{"group":"Networking","id":"LAP2.Networking.Router","nested_context":"LAP2.Networking","nested_title":".Router","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"add_proxy_relays/3","id":"add_proxy_relays/3","title":"add_proxy_relays(proxy_seq, relays, name)"},{"anchor":"append_dht/3","id":"append_dht/3","title":"append_dht(lap2_addr, ip_addr, name)"},{"anchor":"cache_query/4","id":"cache_query/4","title":"cache_query(query, new_qid, conn_id, name)"},{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"clean_state/1","id":"clean_state/1","title":"clean_state(name)"},{"anchor":"debug/1","id":"debug/1","title":"debug(name)"},{"anchor":"drop_test/2","id":"drop_test/2","title":"drop_test(route, drop_probab)"},{"anchor":"get_cached_query/2","id":"get_cached_query/2","title":"get_cached_query(qid, name)"},{"anchor":"get_dht/1","id":"get_dht/1","title":"get_dht(name)"},{"anchor":"get_neighbors/1","id":"get_neighbors/1","title":"get_neighbors(name)"},{"anchor":"get_query_relay/2","id":"get_query_relay/2","title":"get_query_relay(query_id, name)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"route_inbound/3","id":"route_inbound/3","title":"route_inbound(source, clove, name)"},{"anchor":"route_outbound/3","id":"route_outbound/3","title":"route_outbound(dest, clove, name)"},{"anchor":"route_outbound_discovery/3","id":"route_outbound_discovery/3","title":"route_outbound_discovery(lap2_addr, clove, name)"},{"anchor":"route_tcp/2","id":"route_tcp/2","title":"route_tcp(query, name)"},{"anchor":"save_query_relay/3","id":"save_query_relay/3","title":"save_query_relay(query_id, proxy_seq, name)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"},{"anchor":"terminate/2","id":"terminate/2","title":"terminate(reason, arg2)"},{"anchor":"update_config/2","id":"update_config/2","title":"update_config(config, name)"}]}],"sections":[],"title":"LAP2.Networking.Router"},{"group":"Networking","id":"LAP2.Networking.Helpers.OutboundPipelines","nested_context":"LAP2.Networking.Helpers","nested_title":".OutboundPipelines","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"send_proxy_accept/5","id":"send_proxy_accept/5","title":"send_proxy_accept(enc_request, proxy_seq, clove_seq, relay_pool, router_name)"},{"anchor":"send_proxy_discovery/5","id":"send_proxy_discovery/5","title":"send_proxy_discovery(enc_request, random_neighbors, clove_seq, clove_limit, router_name)"},{"anchor":"send_regular_request/4","id":"send_regular_request/4","title":"send_regular_request(enc_request, proxy_seq, relay_pool, router_name)"}]}],"sections":[],"title":"LAP2.Networking.Helpers.OutboundPipelines"},{"group":"Networking","id":"LAP2.Networking.Helpers.RelaySelector","nested_context":"LAP2.Networking.Helpers","nested_title":".RelaySelector","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"cast_proxy_discovery/5","id":"cast_proxy_discovery/5","title":"cast_proxy_discovery(data, clove_seq, random_neighbors, clove_limit, router_name)"},{"anchor":"disperse_and_send/5","id":"disperse_and_send/5","title":"disperse_and_send(data, clove_type, clove_header, relay_list, router_name)"}]}],"sections":[],"title":"LAP2.Networking.Helpers.RelaySelector"},{"group":"Networking","id":"LAP2.Networking.Helpers.State","nested_context":"LAP2.Networking.Helpers","nested_title":".State","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"add_own_clove/2","id":"add_own_clove/2","title":"add_own_clove(state, clove_seq)"},{"anchor":"add_proxy_relay/3","id":"add_proxy_relay/3","title":"add_proxy_relay(state, proxy_seq, relay_node)"},{"anchor":"add_query_relay/3","id":"add_query_relay/3","title":"add_query_relay(state, query_id, proxy_seq)"},{"anchor":"add_relay/4","id":"add_relay/4","title":"add_relay(state, proxy_seq, relay_1, relay_2)"},{"anchor":"ban_clove/2","id":"ban_clove/2","title":"ban_clove(state, clove_seq)"},{"anchor":"cache_clove/4","id":"cache_clove/4","title":"cache_clove(state, source, dest, clove)"},{"anchor":"clean_state/1","id":"clean_state/1","title":"clean_state(state)"},{"anchor":"delete_own_clove/2","id":"delete_own_clove/2","title":"delete_own_clove(state, clove_seq)"},{"anchor":"evict_clove/2","id":"evict_clove/2","title":"evict_clove(state, clove_seq)"},{"anchor":"get_route/3","id":"get_route/3","title":"get_route(state, source, clove)"},{"anchor":"remove_neighbor/2","id":"remove_neighbor/2","title":"remove_neighbor(state, neighbor)"},{"anchor":"update_clove_timestamp/2","id":"update_clove_timestamp/2","title":"update_clove_timestamp(state, clove_seq)"},{"anchor":"update_relay_timestamp/2","id":"update_relay_timestamp/2","title":"update_relay_timestamp(state, proxy_seq)"}]}],"sections":[],"title":"LAP2.Networking.Helpers.State"},{"group":"Networking","id":"LAP2.Networking.Routing.Local","nested_context":"LAP2.Networking.Routing","nested_title":".Local","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"handle_proxy_request/3","id":"handle_proxy_request/3","title":"handle_proxy_request(state, source, clove)"},{"anchor":"receive_discovery_response/3","id":"receive_discovery_response/3","title":"receive_discovery_response(state, source, clove)"},{"anchor":"relay_clove/2","id":"relay_clove/2","title":"relay_clove(state, clove)"}]}],"sections":[],"title":"LAP2.Networking.Routing.Local"},{"group":"Networking","id":"LAP2.Networking.Routing.Remote","nested_context":"LAP2.Networking.Routing","nested_title":".Remote","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"relay_clove/3","id":"relay_clove/3","title":"relay_clove(state, dest, clove)"},{"anchor":"relay_discovery_response/4","id":"relay_discovery_response/4","title":"relay_discovery_response(state, source, dest, clove)"},{"anchor":"relay_proxy_discovery/4","id":"relay_proxy_discovery/4","title":"relay_proxy_discovery(state, source, neighbor_addr, clove)"},{"anchor":"route_outbound/3","id":"route_outbound/3","title":"route_outbound(state, dest, clove)"},{"anchor":"route_outbound_discovery/3","id":"route_outbound_discovery/3","title":"route_outbound_discovery(state, dest, clove)"}]}],"sections":[],"title":"LAP2.Networking.Routing.Remote"},{"group":"Networking","id":"LAP2.Networking.Sockets.Lap2Socket","nested_context":"LAP2.Networking.Sockets","nested_title":".Lap2Socket","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"parse_dgram/3","id":"parse_dgram/3","title":"parse_dgram(source, dgram, router_name)"},{"anchor":"parse_segment/3","id":"parse_segment/3","title":"parse_segment(conn_id, segment, registry_table)"},{"anchor":"respond_tcp/3","id":"respond_tcp/3","title":"respond_tcp(query, conn_id, tcp_name)"},{"anchor":"send_clove/3","id":"send_clove/3","title":"send_clove(arg, clove, udp_name)"},{"anchor":"send_tcp/3","id":"send_tcp/3","title":"send_tcp(arg, query, registry_table)"}]}],"sections":[],"title":"LAP2.Networking.Sockets.Lap2Socket"},{"group":"Networking","id":"LAP2.Networking.Sockets.UdpServer","nested_context":"LAP2.Networking.Sockets","nested_title":".UdpServer","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"send_dgram/3","id":"send_dgram/3","title":"send_dgram(udp_name, dgram, dest)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"},{"anchor":"terminate/2","id":"terminate/2","title":"terminate(reason, arg2)"}]}],"sections":[],"title":"LAP2.Networking.Sockets.UdpServer"},{"group":"Utilities","id":"LAP2.Utils.ConfigParser","nested_context":"LAP2.Utils","nested_title":".ConfigParser","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"get_config/1","id":"get_config/1","title":"get_config(env)"}]}],"sections":[],"title":"LAP2.Utils.ConfigParser"},{"group":"Utilities","id":"LAP2.Utils.EtsHelper","nested_context":"LAP2.Utils","nested_title":".EtsHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"delete_value/2","id":"delete_value/2","title":"delete_value(table, key)"},{"anchor":"get_value/2","id":"get_value/2","title":"get_value(table, key)"},{"anchor":"insert_value/3","id":"insert_value/3","title":"insert_value(table, key, value)"}]}],"sections":[],"title":"LAP2.Utils.EtsHelper"},{"group":"Utilities","id":"LAP2.Utils.JsonUtils","nested_context":"LAP2.Utils","nested_title":".JsonUtils","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"keys_to_atoms/1","id":"keys_to_atoms/1","title":"keys_to_atoms(map)"},{"anchor":"parse_json/1","id":"parse_json/1","title":"parse_json(json)"},{"anchor":"values_to_atoms/2","id":"values_to_atoms/2","title":"values_to_atoms(map, key)"}]}],"sections":[],"title":"LAP2.Utils.JsonUtils"},{"group":"Utilities","id":"LAP2.Utils.ProtoBuf.CloveHelper","nested_context":"LAP2.Utils.ProtoBuf","nested_title":".CloveHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"create_clove/3","id":"create_clove/3","title":"create_clove(data, headers, clove_type)"},{"anchor":"deserialise/1","id":"deserialise/1","title":"deserialise(dgram)"},{"anchor":"handle_deserialised_clove/3","id":"handle_deserialised_clove/3","title":"handle_deserialised_clove(source, clove, router_name)"},{"anchor":"serialise/1","id":"serialise/1","title":"serialise(clove)"},{"anchor":"verify_checksum/1","id":"verify_checksum/1","title":"verify_checksum(clove)"},{"anchor":"verify_clove/1","id":"verify_clove/1","title":"verify_clove(clove)"},{"anchor":"verify_headers/1","id":"verify_headers/1","title":"verify_headers(arg1)"}]}],"sections":[],"title":"LAP2.Utils.ProtoBuf.CloveHelper"},{"group":"Utilities","id":"LAP2.Utils.ProtoBuf.RequestHelper","nested_context":"LAP2.Utils.ProtoBuf","nested_title":".RequestHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"build_fin_claimable/1","id":"build_fin_claimable/1","title":"build_fin_claimable(ring_sig)"},{"anchor":"build_init_claimable/6","id":"build_init_claimable/6","title":"build_init_claimable(identity, pk_ephem_sign, pk_dh, signature, arg1, arg2)"},{"anchor":"build_key_rotation/1","id":"build_key_rotation/1","title":"build_key_rotation(new_key)"},{"anchor":"build_request/4","id":"build_request/4","title":"build_request(crypto, data, req_type, req_id)"},{"anchor":"build_resp_claimable/7","id":"build_resp_claimable/7","title":"build_resp_claimable(identity, pk_ephem_sign, pk_dh, signature, arg1, arg2, ring_sig)"},{"anchor":"build_symmetric_crypto/0","id":"build_symmetric_crypto/0","title":"build_symmetric_crypto()"},{"anchor":"deserialise/2","id":"deserialise/2","title":"deserialise(data, struct)"},{"anchor":"deserialise_and_unwrap/1","id":"deserialise_and_unwrap/1","title":"deserialise_and_unwrap(enc_request)"},{"anchor":"deserialise_and_unwrap/3","id":"deserialise_and_unwrap/3","title":"deserialise_and_unwrap(enc_request, proxy_seq, crypto_mgr_name)"},{"anchor":"encrypt_and_wrap/3","id":"encrypt_and_wrap/3","title":"encrypt_and_wrap(request, proxy_seq, crypto_mgr_name)"},{"anchor":"format_export/1","id":"format_export/1","title":"format_export(struct)"},{"anchor":"format_import/1","id":"format_import/1","title":"format_import(struct)"},{"anchor":"format_sag_export/1","id":"format_sag_export/1","title":"format_sag_export(sag)"},{"anchor":"format_sag_import/1","id":"format_sag_import/1","title":"format_sag_import(sag)"},{"anchor":"gen_finalise_exchange/3","id":"gen_finalise_exchange/3","title":"gen_finalise_exchange(request, proxy_seq, crypto_mgr)"},{"anchor":"gen_response/3","id":"gen_response/3","title":"gen_response(request, proxy_seq, crypto_mgr)"},{"anchor":"init_exchange/1","id":"init_exchange/1","title":"init_exchange(crypto_mgr)"},{"anchor":"init_key_rotation/2","id":"init_key_rotation/2","title":"init_key_rotation(proxy_seq, crypto_mgr)"},{"anchor":"recv_finalise_exchange/3","id":"recv_finalise_exchange/3","title":"recv_finalise_exchange(request, proxy_seq, crypto_mgr)"},{"anchor":"rotate_keys/3","id":"rotate_keys/3","title":"rotate_keys(request, proxy_seq, crypto_mgr)"},{"anchor":"serialise/1","id":"serialise/1","title":"serialise(request)"},{"anchor":"wrap_unencrypted/1","id":"wrap_unencrypted/1","title":"wrap_unencrypted(request)"}]}],"sections":[],"title":"LAP2.Utils.ProtoBuf.RequestHelper"},{"group":"Utilities","id":"LAP2.Utils.ProtoBuf.ShareHelper","nested_context":"LAP2.Utils.ProtoBuf","nested_title":".ShareHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"deserialise/1","id":"deserialise/1","title":"deserialise(dgram)"},{"anchor":"format_aux_data/1","id":"format_aux_data/1","title":"format_aux_data(arg1)"},{"anchor":"reconstruct/1","id":"reconstruct/1","title":"reconstruct(shares)"},{"anchor":"serialise/1","id":"serialise/1","title":"serialise(share)"},{"anchor":"verify_share/1","id":"verify_share/1","title":"verify_share(arg1)"}]}],"sections":[],"title":"LAP2.Utils.ProtoBuf.ShareHelper"},{"group":"Maths","id":"LAP2.Math.Matrix","nested_context":"LAP2.Math","nested_title":".Matrix","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"elementary_symmetric_functions/3","id":"elementary_symmetric_functions/3","title":"elementary_symmetric_functions(m, l, field_limit)"},{"anchor":"extended_gcd/2","id":"extended_gcd/2","title":"extended_gcd(a, b)"},{"anchor":"gen_vandermonde_matrix/3","id":"gen_vandermonde_matrix/3","title":"gen_vandermonde_matrix(n, m, field_limit)"},{"anchor":"load_nif/0","id":"load_nif/0","title":"load_nif()"},{"anchor":"matrix_dot_product/3","id":"matrix_dot_product/3","title":"matrix_dot_product(a, b, field_limit)"},{"anchor":"matrix_nif_product/3","id":"matrix_nif_product/3","title":"matrix_nif_product(a, b, field_limit)"},{"anchor":"transpose/1","id":"transpose/1","title":"transpose(a)"},{"anchor":"vandermonde_inverse/2","id":"vandermonde_inverse/2","title":"vandermonde_inverse(basis, field_limit)"},{"anchor":"vector_dot_product/3","id":"vector_dot_product/3","title":"vector_dot_product(vector_a, vector_b, field_limit)"}]}],"sections":[],"title":"LAP2.Math.Matrix"},{"group":"Control","id":"LAP2","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"kill/1","id":"kill/1","title":"kill(pid)"},{"anchor":"load_config/0","id":"load_config/0","title":"load_config()"},{"anchor":"start/0","id":"start/0","title":"start()"},{"anchor":"start/1","id":"start/1","title":"start(config)"},{"anchor":"terminate_child/2","id":"terminate_child/2","title":"terminate_child(supervisor_name, pid)"}]}],"sections":[],"title":"LAP2"},{"group":"Control","id":"LAP2.Main.Master","nested_context":"LAP2.Main","nested_title":".Master","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"bootstrap_dht/2","id":"bootstrap_dht/2","title":"bootstrap_dht(bootstrap_addr, master_name)"},{"anchor":"cache_query/4","id":"cache_query/4","title":"cache_query(query, routing_info, service_id, name)"},{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"deregister_listener/2","id":"deregister_listener/2","title":"deregister_listener(listener_id, master_name)"},{"anchor":"deregister_service/3","id":"deregister_service/3","title":"deregister_service(service_id, secret, master_name)"},{"anchor":"discard_query/4","id":"discard_query/4","title":"discard_query(service_id, query_id, secret, name)"},{"anchor":"discover_proxy/1","id":"discover_proxy/1","title":"discover_proxy(master_name)"},{"anchor":"get_listener_struct/2","id":"get_listener_struct/2","title":"get_listener_struct(listener_id, master_name)"},{"anchor":"get_registry_table/1","id":"get_registry_table/1","title":"get_registry_table(name)"},{"anchor":"get_service_target/2","id":"get_service_target/2","title":"get_service_target(listener_id, master_name)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"pop_return/2","id":"pop_return/2","title":"pop_return(query_id, name)"},{"anchor":"register_dht_request/2","id":"register_dht_request/2","title":"register_dht_request(query_id, name)"},{"anchor":"register_listener/2","id":"register_listener/2","title":"register_listener(listener, master_name)"},{"anchor":"register_return/3","id":"register_return/3","title":"register_return(query_id, listener_id, name)"},{"anchor":"register_service/3","id":"register_service/3","title":"register_service(service_id, listener_id, master_name)"},{"anchor":"request_remote/5","id":"request_remote/5","title":"request_remote(intro_points, data, service_id, listener_id, name)"},{"anchor":"respond/5","id":"respond/5","title":"respond(service_id, query_ids, secret, data, name)"},{"anchor":"service_lookup/2","id":"service_lookup/2","title":"service_lookup(service_id, master_name)"},{"anchor":"setup_introduction_point/2","id":"setup_introduction_point/2","title":"setup_introduction_point(service_ids, name)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"},{"anchor":"valid_dht_request?/2","id":"valid_dht_request?/2","title":"valid_dht_request?(query_id, name)"}]}],"sections":[],"title":"LAP2.Main.Master"},{"group":"Control","id":"LAP2.Main.ProxyManager","nested_context":"LAP2.Main","nested_title":".ProxyManager","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"debug/1","id":"debug/1","title":"debug(name)"},{"anchor":"handle_call/2","id":"handle_call/2","title":"handle_call(arg, state)"},{"anchor":"handle_discovery_response/3","id":"handle_discovery_response/3","title":"handle_discovery_response(request, aux_data, proxy_name)"},{"anchor":"handle_proxy_request/3","id":"handle_proxy_request/3","title":"handle_proxy_request(request, aux_data, proxy_name)"},{"anchor":"handle_regular_proxy/3","id":"handle_regular_proxy/3","title":"handle_regular_proxy(request, pseq, proxy_name)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"init_proxy/1","id":"init_proxy/1","title":"init_proxy(proxy_name)"},{"anchor":"remove_proxy/2","id":"remove_proxy/2","title":"remove_proxy(proxy_seq, proxy_name)"},{"anchor":"send_request/3","id":"send_request/3","title":"send_request(data, proxy_seq, name)"},{"anchor":"send_response/3","id":"send_response/3","title":"send_response(data, proxy_seq, name)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"}]}],"sections":[],"title":"LAP2.Main.ProxyManager"},{"group":"Control","id":"LAP2.Main.Helpers.ProcessorState","nested_context":"LAP2.Main.Helpers","nested_title":".ProcessorState","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"add_share_to_ets/3","id":"add_share_to_ets/3","title":"add_share_to_ets(ets, share, aux_data)"},{"anchor":"add_to_drop_list/2","id":"add_to_drop_list/2","title":"add_to_drop_list(state, msg_id)"},{"anchor":"cache_share/2","id":"cache_share/2","title":"cache_share(state, share)"},{"anchor":"delete_from_cache/2","id":"delete_from_cache/2","title":"delete_from_cache(state, msg_id)"},{"anchor":"route_share/2","id":"route_share/2","title":"route_share(state, share)"}]}],"sections":[],"title":"LAP2.Main.Helpers.ProcessorState"},{"group":"Control","id":"LAP2.Main.Helpers.ProxyHelper","nested_context":"LAP2.Main.Helpers","nested_title":".ProxyHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"accept_proxy_request/3","id":"accept_proxy_request/3","title":"accept_proxy_request(request, map, state)"},{"anchor":"handle_discovery_response/3","id":"handle_discovery_response/3","title":"handle_discovery_response(request, map, state)"},{"anchor":"handle_fin_key_exhange/3","id":"handle_fin_key_exhange/3","title":"handle_fin_key_exhange(request, proxy_seq, state)"},{"anchor":"handle_key_exchange_ack/2","id":"handle_key_exchange_ack/2","title":"handle_key_exchange_ack(proxy_seq, registry_table)"},{"anchor":"handle_key_rotation/3","id":"handle_key_rotation/3","title":"handle_key_rotation(request, proxy_seq, state)"},{"anchor":"handle_key_rotation_ack/2","id":"handle_key_rotation_ack/2","title":"handle_key_rotation_ack(proxy_seq, registry_table)"},{"anchor":"handle_proxy_query/3","id":"handle_proxy_query/3","title":"handle_proxy_query(request, pseq, registry_table)"},{"anchor":"init_proxy_request/3","id":"init_proxy_request/3","title":"init_proxy_request(registry_table, clove_seq, cloves)"},{"anchor":"remove_proxy/2","id":"remove_proxy/2","title":"remove_proxy(state, proxy_seq)"},{"anchor":"send_to_proxy/4","id":"send_to_proxy/4","title":"send_to_proxy(request, proxy_seq, relay_pool, registry_table)"}]}],"sections":[],"title":"LAP2.Main.Helpers.ProxyHelper"},{"group":"Control","id":"LAP2.Main.StructHandlers.RequestHandler","nested_context":"LAP2.Main.StructHandlers","nested_title":".RequestHandler","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"handle_request/3","id":"handle_request/3","title":"handle_request(enc_request_bin, aux_data, registry_table)"}]}],"sections":[],"title":"LAP2.Main.StructHandlers.RequestHandler"},{"group":"Control","id":"LAP2.Main.StructHandlers.ShareHandler","nested_context":"LAP2.Main.StructHandlers","nested_title":".ShareHandler","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"deliver/3","id":"deliver/3","title":"deliver(data, aux_data, name)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"service_deliver/3","id":"service_deliver/3","title":"service_deliver(data, routing_info, name)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"},{"anchor":"terminate/2","id":"terminate/2","title":"terminate(reason, state)"}]}],"sections":[],"title":"LAP2.Main.StructHandlers.ShareHandler"}],"tasks":[]}