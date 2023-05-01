sidebarNodes={"extras":[{"group":"","headers":[{"anchor":"modules","id":"Modules"}],"id":"api-reference","title":"API Reference"},{"group":"","headers":[{"anchor":"lightweight-anonymous-p2p-overlay-network","id":"Lightweight Anonymous P2P Overlay Network"},{"anchor":"introduction","id":"Introduction"},{"anchor":"about","id":"About"},{"anchor":"garlic-cast","id":"Garlic Cast"},{"anchor":"c-rsdake","id":"C-RSDAKE"},{"anchor":"todo","id":"TODO"}],"id":"readme","title":"LAP2"}],"modules":[{"group":"Cryptography","id":"LAP2.Crypto.CryptoManager","nested_context":"LAP2.Crypto","nested_title":".CryptoManager","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"add_crypto_struct/3","id":"add_crypto_struct/3","title":"add_crypto_struct(crypto_struct, proxy_seq, name \\\\ :crypto_manager)"},{"anchor":"add_temp_crypto_struct/3","id":"add_temp_crypto_struct/3","title":"add_temp_crypto_struct(crypto_struct, clove_seq, name \\\\ :crypto_manager)"},{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"decrypt_request/3","id":"decrypt_request/3","title":"decrypt_request(enc_request, proxy_seq, name \\\\ :crypto_manager)"},{"anchor":"delete_temp_crypto/2","id":"delete_temp_crypto/2","title":"delete_temp_crypto(clove_seq, name \\\\ :crypto_manager)"},{"anchor":"encrypt_request/3","id":"encrypt_request/3","title":"encrypt_request(data, proxy_seq, name \\\\ :crypto_manager)"},{"anchor":"get_identity/1","id":"get_identity/1","title":"get_identity(name \\\\ :crypto_manager)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"remove_crypto_struct/2","id":"remove_crypto_struct/2","title":"remove_crypto_struct(proxy_seq, name \\\\ :crypto_manager)"},{"anchor":"rotate_keys/3","id":"rotate_keys/3","title":"rotate_keys(crypto_struct, proxy_seq, name \\\\ :crypto_manager)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"}]}],"sections":[],"title":"LAP2.Crypto.CryptoManager"},{"group":"Cryptography","id":"LAP2.Crypto.Constructions.ClaimableRS","nested_context":"LAP2.Crypto.Constructions","nested_title":".ClaimableRS","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:sag/0","id":"sag/0","title":"sag()"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"crs_claim/3","id":"crs_claim/3","title":"crs_claim(ring_idx, arg1, arg2)"},{"anchor":"crs_gen/0","id":"crs_gen/0","title":"crs_gen()"},{"anchor":"crs_sign/4","id":"crs_sign/4","title":"crs_sign(ring_idx, arg, ring, msg)"},{"anchor":"crs_vrfy/2","id":"crs_vrfy/2","title":"crs_vrfy(arg, msg)"},{"anchor":"crs_vrfy_claim/3","id":"crs_vrfy_claim/3","title":"crs_vrfy_claim(arg1, arg2, arg3)"},{"anchor":"rs_gen/0","id":"rs_gen/0","title":"rs_gen()"},{"anchor":"rs_sign/4","id":"rs_sign/4","title":"rs_sign(ring_idx, sk, ring, msg)"},{"anchor":"rs_vrfy/2","id":"rs_vrfy/2","title":"rs_vrfy(sag, msg)"},{"anchor":"sag_to_charlist/1","id":"sag_to_charlist/1","title":"sag_to_charlist(sag)"}]}],"sections":[],"title":"LAP2.Crypto.Constructions.ClaimableRS"},{"group":"Cryptography","id":"LAP2.Crypto.Constructions.CryptoNifs","nested_context":"LAP2.Crypto.Constructions","nested_title":".CryptoNifs","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"commit_gen/2","id":"commit_gen/2","title":"commit_gen(sk, rand)"},{"anchor":"commit_vrfy/3","id":"commit_vrfy/3","title":"commit_vrfy(sk, rand, com)"},{"anchor":"prf_eval/2","id":"prf_eval/2","title":"prf_eval(sk, data)"},{"anchor":"prf_gen/1","id":"prf_gen/1","title":"prf_gen(n)"},{"anchor":"rs_nif_gen/0","id":"rs_nif_gen/0","title":"rs_nif_gen()"},{"anchor":"rs_nif_sign/4","id":"rs_nif_sign/4","title":"rs_nif_sign(idx, sk, ring, msg)"},{"anchor":"rs_nif_vrfy/4","id":"rs_nif_vrfy/4","title":"rs_nif_vrfy(chal, ring, resp, msg)"},{"anchor":"standard_signature_gen/0","id":"standard_signature_gen/0","title":"standard_signature_gen()"},{"anchor":"standard_signature_sign/3","id":"standard_signature_sign/3","title":"standard_signature_sign(sk, msg, rand)"},{"anchor":"standard_signature_vrfy/3","id":"standard_signature_vrfy/3","title":"standard_signature_vrfy(sig, vk, msg)"}]}],"sections":[],"title":"LAP2.Crypto.Constructions.CryptoNifs"},{"group":"Cryptography","id":"LAP2.Crypto.Helpers.CryptoStructHelper","nested_context":"LAP2.Crypto.Helpers","nested_title":".CryptoStructHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"ack_key_rotation/3","id":"ack_key_rotation/3","title":"ack_key_rotation(proxy_seq, request_id, crypto_manager)"},{"anchor":"check_hmac/1","id":"check_hmac/1","title":"check_hmac(req)"},{"anchor":"gen_fin_crypto/1","id":"gen_fin_crypto/1","title":"gen_fin_crypto(arg)"},{"anchor":"gen_init_crypto/1","id":"gen_init_crypto/1","title":"gen_init_crypto(crypto_mgr \\\\ :crypto_manager)"},{"anchor":"gen_key_rotation/2","id":"gen_key_rotation/2","title":"gen_key_rotation(proxy_seq, crypto_mgr_name)"},{"anchor":"gen_resp_crypto/2","id":"gen_resp_crypto/2","title":"gen_resp_crypto(arg, crypto_mgr)"},{"anchor":"set_hmac/1","id":"set_hmac/1","title":"set_hmac(request)"},{"anchor":"verify_ring_signature/2","id":"verify_ring_signature/2","title":"verify_ring_signature(arg, proxy_seq)"}]}],"sections":[],"title":"LAP2.Crypto.Helpers.CryptoStructHelper"},{"group":"Cryptography","id":"LAP2.Crypto.InformationDispersal.RabinIDA","nested_context":"LAP2.Crypto.InformationDispersal","nested_title":".RabinIDA","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"decode_double_byte/1","id":"decode_double_byte/1","title":"decode_double_byte(bytes)"},{"anchor":"encode_double_byte/1","id":"encode_double_byte/1","title":"encode_double_byte(bytes)"},{"anchor":"reconstruct/1","id":"reconstruct/1","title":"reconstruct(shares)"},{"anchor":"split/3","id":"split/3","title":"split(data, n, m)"}]}],"sections":[],"title":"LAP2.Crypto.InformationDispersal.RabinIDA"},{"group":"Cryptography","id":"LAP2.Crypto.InformationDispersal.SecureIDA","nested_context":"LAP2.Crypto.InformationDispersal","nested_title":".SecureIDA","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"disperse/4","id":"disperse/4","title":"disperse(data, n, m, message_id)"},{"anchor":"reconstruct/1","id":"reconstruct/1","title":"reconstruct(shares)"}]}],"sections":[],"title":"LAP2.Crypto.InformationDispersal.SecureIDA"},{"group":"Cryptography","id":"LAP2.Crypto.KeyExchange.C_RSDAKE","nested_context":"LAP2.Crypto.KeyExchange","nested_title":".C_RSDAKE","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:crypto_state/0","id":"crypto_state/0","title":"crypto_state()"},{"anchor":"t:rsdake_final/0","id":"rsdake_final/0","title":"rsdake_final()"},{"anchor":"t:rsdake_init/0","id":"rsdake_init/0","title":"rsdake_init()"},{"anchor":"t:rsdake_resp/0","id":"rsdake_resp/0","title":"rsdake_resp()"},{"anchor":"t:sag/0","id":"sag/0","title":"sag()"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"finalise/3","id":"finalise/3","title":"finalise(identity, crypto_state, recv_resp)"},{"anchor":"initialise/1","id":"initialise/1","title":"initialise(identity)"},{"anchor":"respond/3","id":"respond/3","title":"respond(identity, lt_keys, recv_init)"},{"anchor":"verify_final/3","id":"verify_final/3","title":"verify_final(identity, crypto_state, map)"}]}],"sections":[],"title":"LAP2.Crypto.KeyExchange.C_RSDAKE"},{"group":"Cryptography","id":"LAP2.Crypto.KeyExchange.RSDAKE","nested_context":"LAP2.Crypto.KeyExchange","nested_title":".RSDAKE","nodeGroups":[{"key":"types","name":"Types","nodes":[{"anchor":"t:crypto_state/0","id":"crypto_state/0","title":"crypto_state()"},{"anchor":"t:rsdake_final/0","id":"rsdake_final/0","title":"rsdake_final()"},{"anchor":"t:rsdake_init/0","id":"rsdake_init/0","title":"rsdake_init()"},{"anchor":"t:rsdake_resp/0","id":"rsdake_resp/0","title":"rsdake_resp()"},{"anchor":"t:sag/0","id":"sag/0","title":"sag()"}]},{"key":"functions","name":"Functions","nodes":[{"anchor":"finalise/3","id":"finalise/3","title":"finalise(identity, crypto_state, recv_resp)"},{"anchor":"initialise/1","id":"initialise/1","title":"initialise(identity)"},{"anchor":"respond/3","id":"respond/3","title":"respond(identity, lt_keys, recv_init)"},{"anchor":"verify_final/3","id":"verify_final/3","title":"verify_final(identity, crypto_state, map)"}]}],"sections":[],"title":"LAP2.Crypto.KeyExchange.RSDAKE"},{"group":"Cryptography","id":"LAP2.Crypto.Padding.PKCS7","nested_context":"LAP2.Crypto.Padding","nested_title":".PKCS7","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"pad/2","id":"pad/2","title":"pad(data, len)"},{"anchor":"unpad/1","id":"unpad/1","title":"unpad(data)"}]}],"sections":[],"title":"LAP2.Crypto.Padding.PKCS7"},{"group":"Networking","id":"LAP2.Networking.ProtoBuf","nested_context":"LAP2.Networking","nested_title":".ProtoBuf","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"deserialise/2","id":"deserialise/2","title":"deserialise(data, struct_type \\\\ Clove)"},{"anchor":"serialise/1","id":"serialise/1","title":"serialise(struct)"}]}],"sections":[],"title":"LAP2.Networking.ProtoBuf"},{"group":"Networking","id":"LAP2.Networking.Resolver","nested_context":"LAP2.Networking","nested_title":".Resolver","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"build_query/1","id":"build_query/1","title":"build_query(addr)"},{"anchor":"resolve_addr/2","id":"resolve_addr/2","title":"resolve_addr(addr, dht)"}]}],"sections":[],"title":"LAP2.Networking.Resolver"},{"group":"Networking","id":"LAP2.Networking.Router","nested_context":"LAP2.Networking","nested_title":".Router","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"add_proxy_relays/3","id":"add_proxy_relays/3","title":"add_proxy_relays(proxy_seq, relays, name \\\\ :router)"},{"anchor":"append_dht/3","id":"append_dht/3","title":"append_dht(lap2_addr, ip_addr, name \\\\ :router)"},{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"clean_state/1","id":"clean_state/1","title":"clean_state(name \\\\ :router)"},{"anchor":"debug/1","id":"debug/1","title":"debug(name \\\\ :router)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"route_inbound/3","id":"route_inbound/3","title":"route_inbound(source, clove, name \\\\ :router)"},{"anchor":"route_outbound/3","id":"route_outbound/3","title":"route_outbound(dest, clove, name)"},{"anchor":"route_outbound_discovery/3","id":"route_outbound_discovery/3","title":"route_outbound_discovery(lap2_addr, clove, name)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"},{"anchor":"terminate/2","id":"terminate/2","title":"terminate(reason, arg2)"},{"anchor":"update_config/2","id":"update_config/2","title":"update_config(config, name \\\\ :router)"}]}],"sections":[],"title":"LAP2.Networking.Router"},{"group":"Networking","id":"LAP2.Networking.Helpers.OutboundPipelines","nested_context":"LAP2.Networking.Helpers","nested_title":".OutboundPipelines","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"send_proxy_accept/5","id":"send_proxy_accept/5","title":"send_proxy_accept(enc_request, proxy_seq, clove_seq, relay_pool, router_name \\\\ :router)"},{"anchor":"send_proxy_discovery/4","id":"send_proxy_discovery/4","title":"send_proxy_discovery(enc_request, random_neighbors, clove_limit \\\\ 20, router_name \\\\ :router)"},{"anchor":"send_regular_response/4","id":"send_regular_response/4","title":"send_regular_response(enc_request, proxy_seq, relay_pool, router_name)"}]}],"sections":[],"title":"LAP2.Networking.Helpers.OutboundPipelines"},{"group":"Networking","id":"LAP2.Networking.Helpers.RelaySelector","nested_context":"LAP2.Networking.Helpers","nested_title":".RelaySelector","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"cast_proxy_discovery/5","id":"cast_proxy_discovery/5","title":"cast_proxy_discovery(data, clove_seq, random_neighbors, clove_limit, router_name)"},{"anchor":"disperse_and_send/5","id":"disperse_and_send/5","title":"disperse_and_send(data, clove_type, clove_header, relay_list, router_name)"}]}],"sections":[],"title":"LAP2.Networking.Helpers.RelaySelector"},{"group":"Networking","id":"LAP2.Networking.Helpers.State","nested_context":"LAP2.Networking.Helpers","nested_title":".State","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"add_own_clove/2","id":"add_own_clove/2","title":"add_own_clove(state, clove_seq)"},{"anchor":"add_proxy_relay/3","id":"add_proxy_relay/3","title":"add_proxy_relay(state, proxy_seq, relay_node)"},{"anchor":"add_relay/4","id":"add_relay/4","title":"add_relay(state, proxy_seq, relay_1, relay_2)"},{"anchor":"ban_clove/2","id":"ban_clove/2","title":"ban_clove(state, clove_seq)"},{"anchor":"cache_clove/4","id":"cache_clove/4","title":"cache_clove(state, source, dest, clove)"},{"anchor":"clean_state/1","id":"clean_state/1","title":"clean_state(state)"},{"anchor":"delete_own_clove/2","id":"delete_own_clove/2","title":"delete_own_clove(state, clove_seq)"},{"anchor":"evict_clove/2","id":"evict_clove/2","title":"evict_clove(state, clove_seq)"},{"anchor":"get_route/3","id":"get_route/3","title":"get_route(state, source, clove)"},{"anchor":"remove_neighbor/2","id":"remove_neighbor/2","title":"remove_neighbor(state, neighbor)"},{"anchor":"update_clove_timestamp/2","id":"update_clove_timestamp/2","title":"update_clove_timestamp(state, clove_seq)"},{"anchor":"update_relay_timestamp/2","id":"update_relay_timestamp/2","title":"update_relay_timestamp(state, proxy_seq)"}]}],"sections":[],"title":"LAP2.Networking.Helpers.State"},{"group":"Networking","id":"LAP2.Networking.Routing.Local","nested_context":"LAP2.Networking.Routing","nested_title":".Local","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"handle_proxy_request/3","id":"handle_proxy_request/3","title":"handle_proxy_request(state, source, clove)"},{"anchor":"receive_discovery_response/3","id":"receive_discovery_response/3","title":"receive_discovery_response(state, source, clove)"},{"anchor":"relay_clove/2","id":"relay_clove/2","title":"relay_clove(state, clove)"}]}],"sections":[],"title":"LAP2.Networking.Routing.Local"},{"group":"Networking","id":"LAP2.Networking.Routing.Remote","nested_context":"LAP2.Networking.Routing","nested_title":".Remote","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"relay_clove/3","id":"relay_clove/3","title":"relay_clove(state, dest, clove)"},{"anchor":"relay_discovery_response/4","id":"relay_discovery_response/4","title":"relay_discovery_response(state, source, dest, clove)"},{"anchor":"relay_proxy_discovery/4","id":"relay_proxy_discovery/4","title":"relay_proxy_discovery(state, source, neighbor_addr, clove)"},{"anchor":"route_outbound/3","id":"route_outbound/3","title":"route_outbound(state, dest, clove)"},{"anchor":"route_outbound_discovery/3","id":"route_outbound_discovery/3","title":"route_outbound_discovery(state, dest, clove)"}]}],"sections":[],"title":"LAP2.Networking.Routing.Remote"},{"group":"Networking","id":"LAP2.Networking.Sockets.Lap2Socket","nested_context":"LAP2.Networking.Sockets","nested_title":".Lap2Socket","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"parse_dgram/3","id":"parse_dgram/3","title":"parse_dgram(source, dgram, router_name)"},{"anchor":"send_clove/3","id":"send_clove/3","title":"send_clove(arg, clove, udp_name)"}]}],"sections":[],"title":"LAP2.Networking.Sockets.Lap2Socket"},{"group":"Networking","id":"LAP2.Networking.Sockets.UdpServer","nested_context":"LAP2.Networking.Sockets","nested_title":".UdpServer","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"send_dgram/3","id":"send_dgram/3","title":"send_dgram(udp_name, dgram, dest)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"},{"anchor":"terminate/2","id":"terminate/2","title":"terminate(reason, arg2)"}]}],"sections":[],"title":"LAP2.Networking.Sockets.UdpServer"},{"group":"Utilities","id":"LAP2.Utils.ConfigParser","nested_context":"LAP2.Utils","nested_title":".ConfigParser","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"get_config/1","id":"get_config/1","title":"get_config(env)"}]}],"sections":[],"title":"LAP2.Utils.ConfigParser"},{"group":"Utilities","id":"LAP2.Utils.EtsHelper","nested_context":"LAP2.Utils","nested_title":".EtsHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"delete_value/2","id":"delete_value/2","title":"delete_value(table, key)"},{"anchor":"get_value/2","id":"get_value/2","title":"get_value(table, key)"},{"anchor":"insert_value/3","id":"insert_value/3","title":"insert_value(table, key, value)"}]}],"sections":[],"title":"LAP2.Utils.EtsHelper"},{"group":"Utilities","id":"LAP2.Utils.JsonUtils","nested_context":"LAP2.Utils","nested_title":".JsonUtils","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"keys_to_atoms/1","id":"keys_to_atoms/1","title":"keys_to_atoms(map)"},{"anchor":"parse_json/1","id":"parse_json/1","title":"parse_json(json)"},{"anchor":"values_to_atoms/2","id":"values_to_atoms/2","title":"values_to_atoms(map, key)"}]}],"sections":[],"title":"LAP2.Utils.JsonUtils"},{"group":"Utilities","id":"LAP2.Utils.ProtoBuf.CloveHelper","nested_context":"LAP2.Utils.ProtoBuf","nested_title":".CloveHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"create_clove/3","id":"create_clove/3","title":"create_clove(data, headers, clove_type)"},{"anchor":"deserialise/1","id":"deserialise/1","title":"deserialise(dgram)"},{"anchor":"gen_drop_probab/2","id":"gen_drop_probab/2","title":"gen_drop_probab(min, max)"},{"anchor":"gen_seq_num/0","id":"gen_seq_num/0","title":"gen_seq_num()"},{"anchor":"handle_deserialised_clove/3","id":"handle_deserialised_clove/3","title":"handle_deserialised_clove(source, clove, router_name)"},{"anchor":"serialise/1","id":"serialise/1","title":"serialise(clove)"},{"anchor":"verify_checksum/1","id":"verify_checksum/1","title":"verify_checksum(clove)"},{"anchor":"verify_clove/1","id":"verify_clove/1","title":"verify_clove(clove)"},{"anchor":"verify_headers/1","id":"verify_headers/1","title":"verify_headers(arg1)"}]}],"sections":[],"title":"LAP2.Utils.ProtoBuf.CloveHelper"},{"group":"Utilities","id":"LAP2.Utils.ProtoBuf.RequestHelper","nested_context":"LAP2.Utils.ProtoBuf","nested_title":".RequestHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"build_fin_crypto/1","id":"build_fin_crypto/1","title":"build_fin_crypto(ring_sign)"},{"anchor":"build_init_crypto/5","id":"build_init_crypto/5","title":"build_init_crypto(identity, ephem_pk, generator, ring_pk, signature)"},{"anchor":"build_key_rotation/1","id":"build_key_rotation/1","title":"build_key_rotation(new_key)"},{"anchor":"build_request/4","id":"build_request/4","title":"build_request(crypto, data, req_type, req_id)"},{"anchor":"build_resp_crypto/6","id":"build_resp_crypto/6","title":"build_resp_crypto(identity, ephem_pk, generator, ring_pk, signature, ring_sign)"},{"anchor":"build_symmetric_crypto/0","id":"build_symmetric_crypto/0","title":"build_symmetric_crypto()"},{"anchor":"deserialise/2","id":"deserialise/2","title":"deserialise(data, struct)"},{"anchor":"deserialise_and_unwrap/1","id":"deserialise_and_unwrap/1","title":"deserialise_and_unwrap(enc_request)"},{"anchor":"deserialise_and_unwrap/3","id":"deserialise_and_unwrap/3","title":"deserialise_and_unwrap(enc_request, proxy_seq, crypto_mgr_name \\\\ :crypto_manager)"},{"anchor":"encrypt_and_wrap/3","id":"encrypt_and_wrap/3","title":"encrypt_and_wrap(request, proxy_seq, crypto_mgr_name \\\\ :crypto_manager)"},{"anchor":"gen_finalise_exchange/4","id":"gen_finalise_exchange/4","title":"gen_finalise_exchange(request, proxy_seq, clove_seq, crypto_mgr \\\\ :crypto_manager)"},{"anchor":"gen_response/3","id":"gen_response/3","title":"gen_response(request, proxy_seq, crypto_mgr \\\\ :crypto_manager)"},{"anchor":"init_exchange/2","id":"init_exchange/2","title":"init_exchange(clove_seq, crypto_mgr \\\\ :crypto_manager)"},{"anchor":"init_key_rotation/2","id":"init_key_rotation/2","title":"init_key_rotation(proxy_seq, crypto_mgr \\\\ :crypto_manager)"},{"anchor":"recv_finalise_exchange/3","id":"recv_finalise_exchange/3","title":"recv_finalise_exchange(request, proxy_seq, crypto_mgr \\\\ :crypto_manager)"},{"anchor":"rotate_keys/3","id":"rotate_keys/3","title":"rotate_keys(request, proxy_seq, crypto_mgr \\\\ :crypto_manager)"},{"anchor":"serialise/1","id":"serialise/1","title":"serialise(request)"},{"anchor":"wrap_unencrypted/1","id":"wrap_unencrypted/1","title":"wrap_unencrypted(request)"}]}],"sections":[],"title":"LAP2.Utils.ProtoBuf.RequestHelper"},{"group":"Utilities","id":"LAP2.Utils.ProtoBuf.ShareHelper","nested_context":"LAP2.Utils.ProtoBuf","nested_title":".ShareHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"deserialise/1","id":"deserialise/1","title":"deserialise(dgram)"},{"anchor":"format_aux_data/1","id":"format_aux_data/1","title":"format_aux_data(arg1)"},{"anchor":"reconstruct/1","id":"reconstruct/1","title":"reconstruct(shares)"},{"anchor":"serialise/1","id":"serialise/1","title":"serialise(share)"},{"anchor":"verify_share/1","id":"verify_share/1","title":"verify_share(arg1)"}]}],"sections":[],"title":"LAP2.Utils.ProtoBuf.ShareHelper"},{"group":"Maths","id":"LAP2.Math.Matrix","nested_context":"LAP2.Math","nested_title":".Matrix","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"elementary_symmetric_functions/3","id":"elementary_symmetric_functions/3","title":"elementary_symmetric_functions(m, l, field_limit)"},{"anchor":"extended_gcd/2","id":"extended_gcd/2","title":"extended_gcd(a, b)"},{"anchor":"gen_vandermonde_matrix/3","id":"gen_vandermonde_matrix/3","title":"gen_vandermonde_matrix(n, m, field_limit)"},{"anchor":"load_nif/0","id":"load_nif/0","title":"load_nif()"},{"anchor":"matrix_dot_product/3","id":"matrix_dot_product/3","title":"matrix_dot_product(a, b, field_limit)"},{"anchor":"matrix_nif_product/3","id":"matrix_nif_product/3","title":"matrix_nif_product(a, b, field_limit)"},{"anchor":"transpose/1","id":"transpose/1","title":"transpose(a)"},{"anchor":"vandermonde_inverse/2","id":"vandermonde_inverse/2","title":"vandermonde_inverse(basis, field_limit)"},{"anchor":"vector_dot_product/3","id":"vector_dot_product/3","title":"vector_dot_product(vector_a, vector_b, field_limit)"}]}],"sections":[],"title":"LAP2.Math.Matrix"},{"group":"Control","id":"LAP2","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"kill/1","id":"kill/1","title":"kill(pid)"},{"anchor":"load_config/0","id":"load_config/0","title":"load_config()"},{"anchor":"start/0","id":"start/0","title":"start()"},{"anchor":"start/1","id":"start/1","title":"start(config)"},{"anchor":"terminate_child/2","id":"terminate_child/2","title":"terminate_child(supervisor_name, pid)"}]}],"sections":[],"title":"LAP2"},{"group":"Control","id":"LAP2.Main.Master","nested_context":"LAP2.Main","nested_title":".Master","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"deliver_query/3","id":"deliver_query/3","title":"deliver_query(data, stream_id, master_name \\\\ :master)"},{"anchor":"deliver_response/3","id":"deliver_response/3","title":"deliver_response(data, stream_id, master_name \\\\ :master)"},{"anchor":"handle_cast/3","id":"handle_cast/3","title":"handle_cast(arg, from, state)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"register_listener/3","id":"register_listener/3","title":"register_listener(stream_id, listener, master_name \\\\ :master)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"}]}],"sections":[],"title":"LAP2.Main.Master"},{"group":"Control","id":"LAP2.Main.ProxyManager","nested_context":"LAP2.Main","nested_title":".ProxyManager","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"add_proxy/3","id":"add_proxy/3","title":"add_proxy(proxy_name, proxy_seq, proxy_pid)"},{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"debug/1","id":"debug/1","title":"debug(name)"},{"anchor":"handle_discovery_response/3","id":"handle_discovery_response/3","title":"handle_discovery_response(request, aux_data, proxy_name)"},{"anchor":"handle_proxy_request/3","id":"handle_proxy_request/3","title":"handle_proxy_request(request, aux_data, proxy_name)"},{"anchor":"handle_regular_proxy/3","id":"handle_regular_proxy/3","title":"handle_regular_proxy(request, pseq, proxy_name)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"remove_proxy/2","id":"remove_proxy/2","title":"remove_proxy(proxy_seq, proxy_name)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"}]}],"sections":[],"title":"LAP2.Main.ProxyManager"},{"group":"Control","id":"LAP2.Main.Helpers.ProcessorState","nested_context":"LAP2.Main.Helpers","nested_title":".ProcessorState","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"add_share_to_ets/3","id":"add_share_to_ets/3","title":"add_share_to_ets(ets, share, aux_data)"},{"anchor":"add_to_drop_list/2","id":"add_to_drop_list/2","title":"add_to_drop_list(state, msg_id)"},{"anchor":"cache_share/2","id":"cache_share/2","title":"cache_share(state, share)"},{"anchor":"delete_from_cache/2","id":"delete_from_cache/2","title":"delete_from_cache(state, msg_id)"},{"anchor":"route_share/2","id":"route_share/2","title":"route_share(state, share)"}]}],"sections":[],"title":"LAP2.Main.Helpers.ProcessorState"},{"group":"Control","id":"LAP2.Main.Helpers.ProxyHelper","nested_context":"LAP2.Main.Helpers","nested_title":".ProxyHelper","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"accept_proxy_request/3","id":"accept_proxy_request/3","title":"accept_proxy_request(request, map, state)"},{"anchor":"handle_discovery_response/3","id":"handle_discovery_response/3","title":"handle_discovery_response(request, map, state)"},{"anchor":"handle_fin_key_exhange/3","id":"handle_fin_key_exhange/3","title":"handle_fin_key_exhange(request, proxy_seq, state)"},{"anchor":"handle_key_rotation/3","id":"handle_key_rotation/3","title":"handle_key_rotation(request, proxy_seq, state)"},{"anchor":"handle_key_rotation_ack/3","id":"handle_key_rotation_ack/3","title":"handle_key_rotation_ack(request, proxy_seq, crypto_manager)"},{"anchor":"handle_proxy_query/4","id":"handle_proxy_query/4","title":"handle_proxy_query(request, ets, pseq, master_name)"},{"anchor":"handle_proxy_response/4","id":"handle_proxy_response/4","title":"handle_proxy_response(request, ets, pseq, master_name)"},{"anchor":"remove_proxy/2","id":"remove_proxy/2","title":"remove_proxy(state, proxy_seq)"}]}],"sections":[],"title":"LAP2.Main.Helpers.ProxyHelper"},{"group":"Control","id":"LAP2.Main.StructHandlers.RequestHandler","nested_context":"LAP2.Main.StructHandlers","nested_title":".RequestHandler","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"handle_request/3","id":"handle_request/3","title":"handle_request(enc_request_bin, aux_data, registry_table)"}]}],"sections":[],"title":"LAP2.Main.StructHandlers.RequestHandler"},{"group":"Control","id":"LAP2.Main.StructHandlers.ShareHandler","nested_context":"LAP2.Main.StructHandlers","nested_title":".ShareHandler","nodeGroups":[{"key":"functions","name":"Functions","nodes":[{"anchor":"child_spec/1","id":"child_spec/1","title":"child_spec(init_arg)"},{"anchor":"deliver/3","id":"deliver/3","title":"deliver(data, aux_data, name)"},{"anchor":"init/1","id":"init/1","title":"init(config)"},{"anchor":"start_link/1","id":"start_link/1","title":"start_link(config)"},{"anchor":"terminate/2","id":"terminate/2","title":"terminate(reason, state)"}]}],"sections":[],"title":"LAP2.Main.StructHandlers.ShareHandler"}],"tasks":[]}