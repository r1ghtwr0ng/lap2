# **LAP2**
<img src="https://user-images.githubusercontent.com/42644807/234358607-a11e2223-3ddf-489d-af27-5392e65dc4a5.png" alt="Image" width="150" height="150">

## **Lightweight Anonymous P2P Overlay Network**
[![Tests](https://img.shields.io/github/actions/workflow/status/r1ghtwr0ng/lap2/.github/workflows/elixir.yml?branch=master&label=Elixir%20CI&logo=github)](https://github.com/r1ghtwr0ng/lap2/actions/workflows/elixir.yml)
[![Docs](https://img.shields.io/badge/Docs-LAP2%20Docs-blue)](https://r1ghtwr0ng.github.io/lap2/LAP2.html)
[![License](https://badgen.net/badge/License/MIT/blue)](https://opensource.org/licenses/MIT)
## **Introduction**


> &nbsp;&nbsp;The goal of the LAP2 project is to create an anonymous peer-to-peer overlay network that reduces cryptographic overhead for intermediate relays in proxy chains, making it more accessible for usage by low-spec IoT devices. <br><br>
&nbsp;&nbsp;LAP2 is inspired by and builds upon existing solutions for anonymous peer-to-peer networks such as Tor and I2P while attempting to improve performance using recently published research on a new, more efficient routing technique called Garlic Cast. Furthermore, LAP2 extends the functionality of the existing deniable authenticated key exchange algorithm RSDAKE to introduce the first claimable deniable authenticated key exchange protocol, C-RSDAKE, complete with an open-source Elixir implementation.
---
## **About**

> &nbsp;&nbsp;The LAP2 project is implemented using the Elixir programming language. The main objective is to create an anonymous peer-to-peer overlay network with a significantly lower cryptographic overhead compared to conventional anonymity networks such as TOR and I2P. This will allow low-spec IoT devices to be incorporated into the network.<br><br>
&nbsp;&nbsp;To improve performance in certain sections, NIFs (Native Implemented Functions) are used to implement computationally intensive algorithms in C and several cryptographic schemes in Rust.

## **Garlic Cast**

> &nbsp;&nbsp;Garlic Cast is a new, more efficient routing technique that LAP2 uses to improve network performance. It does not require the usage of layered cryptography between intermediate relays, thus increasing performance.

## **C-RSDAKE**

> &nbsp;&nbsp;LAP2 extends the functionality of the existing deniable authenticated key exchange algorithm RSDAKE to introduce the first claimable deniable authenticated key exchange protocol, C-RSDAKE, complete with an open-source Rust implementation. When introduced within the AP2P network, the C-RSDAKE construction empowers users to verify each other's identities through cryptographic means independent of the network. This can be a desirable property for an anonymous network due to the lack of central certificate authorities and will extend the network's ability to provide a secure platform for expressing oneself online while mitigating the risk of third-party monitoring and interference.
---
## **Usage** 

The documentation for the LAP2 project can be found [here](https://r1ghtwr0ng.github.io/lap2/LAP2.html).<br>
It is recommended that you use the project inside a Docker container. To do that, follow the instructions in the next section:

### **Docker Setup**
- Install Docker by following the instructions [here](https://docs.docker.com/get-docker/)

- Build a Docker container for the project by running the following command in the root of the project directory:

    ```bash
    docker build -t lap2 .
    ```

- Start the container in the LAP2 debug shell (IEx) with the following command:

    ```bash
    docker run -it lap2
    ```
- Instructions on how to use the debug shell can be found in the section below.

    > **Note:** If you want to run a different shell inside the container, set the `ENTRYPOINT` in the Dockerfile to the desired shell (e.g., `/bin/bash`), then rebuild the container and run it with the same command as above.

    That's it! Now you can use the project inside a Docker container.

    > **Note:** If ran interactively using docker, the project should automatically start in the IEx shell (unless the Dockerfile entrypoint is changed).

### **IEx interactive shell**

- The LAP2 project can be demoed using Elixir's interactive shell (IEx). To improve the user experience, a utility script sets up the IEx environment (aliases, utility lambdas, etc). To start the shell, run the following command in the root directory:

    ```bash
    mix run
    ```

- The shell can be exited by pressing `Ctrl+C` twice.
- The IEx shell can be used to test out much of the functionality of the modules in the project (with the exception of private functions). The following sections show some examples of how to test out some of LAP2's most important features. If needed, a short syntax reference for Elixir can be found [here](https://hexdocs.pm/elixir/1.12.3/syntax-reference.html), however the code examples should provide enough context to understand what is going on. 
---
### **File transfer example**
We can test out the file transfer functionality of the project by using the `NetUtils` module to simulate the network of nodes and then using the `FileUtils` module to transfer files between them.
Here is a general example of testing out the network by performing a file transfer using the IEx shell:

```elixir
iex(1)> addresses = NetUtils.start_network(50, 40000) # Start network with 50 nodes
["aa7707a292f29733", "5280647b9387f11f", ...]
iex(2)> NetUtils.bootstrap_network() # Setup DHT tables
:ok
iex(3)> [host, client] = Enum.take_random(addresses, 2) # Pick random host and client
["4db73be2deb45f76", "5585735a2ed3018a"]
iex(4)> Enum.each(0..3, fn _ -> # Setup 4 anonymous proxies for both nodes
...(4)>   NetUtils.find_anon_proxy(host)
...(4)>   NetUtils.find_anon_proxy(client)
...(4)> end)
:ok
iex(5)> {:ok, fileio_host} = NetUtils.run_fileio(host)  # Start FileIO host service
{:ok, "ed7494faa04094d4"}
iex(6)> {:ok, fileio_cli} = NetUtils.run_fileio(client) # Start FileIO client service
{:ok, "7df091674c3d4f7f"}
iex(7)> NetUtils.find_intro_point(host, [fileio_host])  # Find an introduction point
:ok
iex(8)> intros = NetUtils.get_introduction_points(fileio_host) # Get the intro point list (if empty, rerun previous command)
["03ce49e5dfc1091f"]
iex(9)> FileIO.request_file(intros, fileio_host, "README.md", "/tmp/readme.md", fileio_cli) # Request remote file
:ok
iex(10)> ls "/tmp/readme.md" # Check if file was written (debug output should indicate success or fail)
/tmp/readme.md
iex(11)> FileIO.stop_service(fileio_host)
:ok
iex(12)> FileIO.stop_service(fileio_cli)
:ok
iex(13)> NetUtils.stop_network()
true
```

### **C-RSDAKE example**
In the previous example C-RSDAKE was used during the anonymous route establishment phase. To test out the C-RSDAKE protocol in isolation, refer to the code example in section [C-RSDAKE](#c_rsdake).

---
### **Networking**



#### **_NetUtils_**

To start off, use the `NetUtils.spawn_network` function to simulate a network environment by starting multiple network nodes simultaneously. The function takes as arguments the number of nodes to be started and the starting port of the first node. The port numbers for subsequent nodes are incremented by 1 from this number. It returns a list of network addresses (string type) for the spawned nodes.

In the following example, we are spawning 100 nodes starting from port 40000. The returned network addresses are stored in the `addresses` variable:

```elixir
iex(1)> addresses = NetUtils.spawn_network(100, 40000)
[...]
```

> **Note:** The number of running nodes is limited by the number of available ports on the host machine. If you get an error saying that the port is already in use, try using a different port number. Try to run less than 1000 nodes to avoid hitting an open port or experiencing performance issues.

The network address of any node can be obtained using the `Enum` module as such:

```elixir
iex(2)> address_0 = Enum.at(addresses, 0) # Take the address at index 0
"..."
iex(3)> rand_address = Enum.random(addresses) # Take a random address
"..."
```

Alternatively, nodes can be spawned individually using `NetUtils.start_node`. To do this, first construct a config file for the node using the `NetUtils.make_config` function, then pass the config file to the `NetUtils.start_node` function. However, if `NetUtils.start_network` has not been called before, the ETS table must be created manually before spawning the node. This can be done using the following commands:

```elixir
iex(1)> :ets.new(:network_registry, [:named_table, :set, :public]) # Create ETS table
iex(2)> udp_port = 40000 # Set UDP port
40000
iex(3)> tcp_port = 40000 # Set TCP port
40000
iex(4)> addr = Generator.generate_hex(8) # Set network address, any string will do
"..."
iex(5)> config = NetUtils.make_config(addr, udp_port, tcp_port) # Create config
%{...}
iex(6)> NetUtils.spawn_node(config) # Start node
:ok
```
---
Once the network has been started, the nodes' routing tables should be bootstrapped. This can be accomplished in multiple ways:

- If you wish to bootstrap all network nodes **without** making any network requests (quickest and most reliable way), use `NetUtils.seed_network`. This function will update each node's routing table with a copy of the global one (stored in an ETS table). This function takes no arguments:

    ```elixir
    iex( )> NetUtils.seed_network()
    :ok
    ```

- Alternatively, if you wish to bootstrap all network nodes by using network DHT update requests, use `NetUtils.bootstrap_network`. This function will first seed a single node with the global registry table, then instruct all other nodes to request a DHT update from it. Again, this function takes no arguments and returns an atom of the status of the operation:

    ```elixir
    iex( )> NetUtils.bootstrap_network()
    :ok
    ```

- The final option is to bootstrap individual nodes. To do that, first use `NetUtils.seed_node` to setup a random node's DHT table as before. This function accepts no arguments but returns the IP address and port of the node that was seeded:

    ```elixir
    iex( )> {:ok, seed_addr} = NetUtils.seed_node()
    {:ok, "..."}
    ```

- Then, use `NetUtils.bootstrap_node` to instruct another node to request a DHT update from the seeded node. This function takes the network address of the client node and the IP address and port of DHT provider node:

    ```elixir
    iex( )> NetUtils.update_dht(lap2_addr, seed_addr)
    :ok
    ```

    This process can be repeated to bootstrap the entire network (which is exactly what `NetUtils.bootstrap_network` does).

To check the contents of a node's routing table, use `NetUtils.inspect_dht`. This function takes the network address of the node as an argument and returns a map of the node's routing table:

```elixir
iex( )> NetUtils.inspect_dht(lap2_addr)
%{
    "..." => {"127.0.0.1", ...},
    ...
}
```
---
Once the nodes have had their routing tables set up, they can start communicating with each other. To set up anonymous routes, select any node and use `NetUtils.find_anon_proxy` to instruct it to find an anonymous proxy. This function takes the network address of the node as an argument and returns the status of the operation:

```elixir
iex( )> NetUtils.find_anon_proxy(lap2_addr)
:ok
```

The function can be called multiple times to establish multiple proxies:

```elixir
iex( )> Enum.each(1..num_proxies, fn _ -> NetUtils.find_anon_proxy(lap2_addr) end)
:ok
```

Once a sufficient number of proxies has been established (depends on config setup, usually >1 in DEV environment), a node can request a random proxy to become its introduction point. To do this, use `NetUtils.find_intro_point`.

**_Arguments:_**
This function expects the following arguments:
1. `lap2_addr`: (string) The network address of the node requesting the introduction point.
2. `service_identifier`: (string) The service identifier of the service that the node wishes to access. See how to generate service identifiers in the [FileUtils](#fileutils-services) section.

```elixir
iex( )> NetUtils.find_intro_point(lap2_addr, service_identifier)
:ok
```

Verify that an introduction point has been setup and find its network address by using `NetUtils.list_intro_points` (no arguments required):

```elixir
iex( )> NetUtils.list_intro_points()
%{...}
```

Retrieving remote files anonymously is covered in the [FileUtils](#fileutils-services) section.

---
Finally, to stop the network, use `NetUtils.stop_network`. This function takes no arguments and returns the status of the operation:

```elixir
iex( )> NetUtils.stop_network()
:ok
```

If needed, individual nodes can be stopped using `NetUtils.stop_node`. This function takes the network address of the node as an argument and returns the status of the operation:

```elixir
iex( )> NetUtils.stop_node(lap2_addr)
:ok
```

This just about covers the networking section of the LAP2 project. The following sections will cover the other modules in the project.

---
### **Cryptography**
The cryptographic section has a wide range of modules that can be tested out. Unlike the networking section, the CryptoUtils module only provides a few functions for encoding/decoding data to hex and base64. Since these modules are not designed to be used from the command line, their usage is a little less straightforward (deeply nested structures). I recommend looking at the unit tests and [docs](https://r1ghtwr0ng.github.io/lap2/LAP2.html) for examples that haven't been covered in this README.<br><br>
The following modules are available in the crypto section:

`CryptoNifs` - Cryptographic primitives implemented in Rust NIFs. Avoid calling these functions directly where possible, they can throw exceptions if argument sizes are not correct (the code is memory safe but debugging Rust NIF exceptions can be a pain).<br>
`CryptoUtils` - Provides functions for encoding/decoding data to hex and base64.<br>
`ClaimableRS` - Implements the claimable ring signature scheme.<br>
`RSDAKE` - Implements the RSDAKE protocol (out-of-date, use `C_RSDAKE` instead).<br>
`C_RSDAKE` - Implements the Claimable RSDAKE key exchange protocol.<br>
`RabinIDA` - Implements Rabin's IDA.<br>
`SecureIDA` - Implements a security enhanced IDA using Rabin's IDA for data dispersal and Shamir's secret sharing for symmetric key dispersal.<br>

---

#### **_CryptoUtils_**
The `CryptoUtils` module provides functions for encoding/decoding data to hex and base64, as well as a few convenience functions for various crypto schemes. These functions can be used to encode and more easily transfer data to and from external tools. The following functions are available:
- `CryptoUtils.list_to_hex/1` - Converts a charlist to a hex string.
- `CryptoUtils.hex_to_list/1` - Converts a hex string to a charlist.
- `CryptoUtils.list_to_b64/1` - Converts a charlist to a base64 string.
- `CryptoUtils.b64_to_list/1` - Converts a base64 string to a charlist.
- `CryptoUtils.gen_ring/3` - Given a public key, ring index and ring size, generate a ring of public keys with the given public key at the given index (demo in next section).

```elixir
iex(1)> list = [99, 104, 97, 114, 108, 105, 115, 116]
'charlist'
iex(2)> CryptoUtils.list_to_hex(list)
"636861726C697374"
iex(3)> |> CryptoUtils.hex_to_list() # The pipe operator ( |> ) is used to pass the result of the previous function call as the first argument to the next function call
'charlist'
iex(4)> |> CryptoUtils.list_to_b64()
"Y2hhcmxpc3Q="
iex(5)> |> CryptoUtils.b64_to_list()
'charlist'
iex(6)> == list
true
```

---
#### **_CryptoNifs_**
The `CryptoNifs` module provides the cryptographic primitives on which the rest of the crypto modules are built (except RabinIDA and SecureIDA). These primitives are implemented in Rust NIFs for performance reasons. The following functions are available:

- `CryptoNifs.prf_gen/1` - Generates a pseudorandom function (PRF) key. Takes the size of the key in bits as an argument and returns the key as a binary.

- `CryptoNifs.prf_eval/2` - Evaluates a PRF. Takes the secret key and input as arguments and returns a 128-bit output as a charlist.

```elixir
iex(1)> prf_sk = CryptoNifs.prf_gen(256)
[230, 75, 38, 236, 139, 109, 101, 23, 114, 235, 115, 57, 0, 0, 248, 80, 143, 19,
 176, 131, 149, 133, 134, 221, 126, 129, 109, 217, 59, 237, 209, 220]
iex(2)> CryptoNifs.prf_eval(prf_sk, 'RANDOM SEED DATA')
[14, 74, 45, 113, 94, 226, 43, 87, 30, 99, 15, 167, 131, 202, 127, 41]
```
- `CryptoNifs.commit_gen/2` - Generates a commitment. Takes the secret key and message as arguments and returns the commitment as a binary.

- `CryptoNifs.commit_vrfy/3` - Verifies the validity of a commitment. Takes the secret key, message and commitment as arguments and returns a boolean.

```elixir
iex(3)> commitment = CryptoNifs.commit_gen(prf_sk, 'Commitment message')
[63, 15, 188, 48, 50, 209, 247, 12, 240, 207, 11, 6, 128, 240, 3, 134, 128, 127,
 108, 226, 82, 192, 45, 29, 241, 124, 207, 101, 241, 49, 114, 197]
iex(4)> CryptoNifs.commit_vrfy(prf_sk, 'Commitment message', commitment)
true
iex(5)> CryptoNifs.commit_vrfy(prf_sk, 'Invalid message', commitment)
false
```

- `CryptoNifs.rs_nif_gen/0` - Generates a secret and public key pair for the SAG (Spontaneous Anonymous Group) ring signature scheme. The result is returned as a tuple of charlists (use the wrapper `ClaimableRS.rs_gen/0` instead).

- `CryptoNifs.rs_nif_sign/4` - Signs a message using the SAG ring signature scheme. Takes index of the signer in the ring, the signer's secret key, the ring of public keys (list of charlists) and the message to be signed (charlist). The function returns a ring signature tuple containing the signature challenge, response, and ring (charlist, list(charlist), list(charlist)). Use the wrapper `ClaimableRS.rs_sign/4` instead for argument size verification.

- `CryptoNifs.rs_nif_vrfy/4` - Verifies the validity of an SAG ring signature. Expects as input the signature challenge (charlist), the ring of public keys (list of charlists), the challenge responses (list of charlists) and the message that was signed. Returns a true if the signature is valid, false otherwise. Use the wrapper `ClaimableRS.rs_vrfy/2` instead for argument size verification and overall better interface.
  
- `CryptoUtils.gen_ring/3` - Creates a ring of public keys. Expects the ring position of the signer (integer index, starting from 0), the public key of the signer and the size of the ring. This is a utility function for quickly creating rings for the signature scheme. Returns a ring in the form of a list of public keys (charlists).

```elixir
iex(1)> {sk, pk} = CryptoNifs.rs_nif_gen() # Generate key pair
{[...],[...]}
iex(2)> ring_idx = 0 # The index position of the signer in the ring
iex(3)> ring_size = 3 # The number of ring participants (including the signer)
iex(4)> ring = CryptoUtils.gen_ring(ring_idx, pk, ring_size) # Generate a ring
[[...], [...], [...]]
iex(5)> {chal, new_ring, resp} = CryptoNifs.rs_nif_sign(0, sk, ring, 'Test message for signing') # Sign message
{[...],[...],[...]}
iex(6)> CryptoNifs.rs_nif_vrfy(chal, new_ring, resp, 'Test message for signing') # Check valid signature
true
iex(7)> CryptoNifs.rs_nif_vrfy(chal, new_ring, resp, 'Invalid message') # Check invalid signature
false
```
> **Note:** The contents of the charlists have been replaced with ... for readability. The charlists in this crypto modules are essentially integer lists of type uint8 (0-255).

- `CryptoNifs.standard_signature_gen/0` - Standard signature scheme key generation function. Returns a tuple of secret and verification keys (charlists).

- `CryptoNifs.standard_signature_sign/3` - Probabilistic signature scheme signing function (RSA-PSS). Expects as arguments the signer's secret key, message for signing and randomness as a seed. Returns the RSA-PSS signature as a charlist.

- `CryptoNifs.standard_signature_vrfy/3` - Probabilistic signature scheme verification function (RSA-PSS). Expects as arguments the signature, signer's verification key and message for verification and signature. Returns a boolean.

```elixir
iex(1)> rand = CryptoNifs.prf_gen(256) # Generate randomness
[...]
iex(2)> {sk, vk} = CryptoNifs.standard_signature_gen() # Generate RSA keys
{[...], [...]}
iex(3)> signature = CryptoNifs.standard_signature_sign(sk, 'Test message for signing', rand) # Sign message
[...]
iex(4)> CryptoNifs.standard_signature_vrfy(signature, vk, 'Test message for signing') # Verify signature
true
iex(5)> CryptoNifs.standard_signature_vrfy(signature, vk, 'Invalid message') # Invalid signature
false
```
---

#### **_ClaimableRS_**
The `ClaimableRS` module is a contains a few wrappers for the `CryptoNifs` module, as well as functions for generating, signing and verifying claimable ring signatures. The module is used in the `C_RSDAKE` module for using claimable ring signatures in the RSDAKE protocol. The following section does not include the wrappers for the `CryptoNifs` functions, as they are essentially the same as the ones in the `CryptoNifs` module. The other functions are as follows:

- `ClaimableRS.crs_gen/0` - Generates a secret and verification key pair for the claimable ring signature scheme, returned as map with sk: and vk: keys.

- `ClaimableRS.crs_sign/4` - Signs a message using the claimable ring signature scheme. Similarly to `ClaimableRS.rs_sign/4`, it takes as arguments the ring index of the signer, the signer's secret *claimable ring signature* key, the ring of public keys and the message to be signed. Returns a tuple of {:ok, SAG} or {:error, atom}, where SAG is a struct containing the signature challenge, response and ring and atom is the error that has occured.

- `ClaimableRS.crs_vrfy/2` - Verifies the validity of a claimable ring signature. Expects as arguments the SAG struct generated on signing and the message that has been signed. Returns an {:ok, boolean} if the arguments are valid, or {:error, atom} with information about the error in the atom.

- `ClaimableRS.crs_claim/3` - Produces a claim for a given ring signature. Expects as arguments the ring index of the signer, the signer's secret *claimable ring signature* key and the claimable signature (SAG struct) for which the claim will be made. If valid, returns {:ok, claim} where the claim is a tuple of the commitment randomness and standard signature. If invalid, returns {:error, atom} with information about the error in the atom.

- `ClaimableRS.crs_vrfy_claim/3` - Verifies the validity of a claim for a given ring signature. Expects as arguments the claim, the ring index of the signer and the claimable signature (SAG struct) for which the claim will be made. If valid, returns {:ok, boolean}. If invalid, returns {:error, atom} with information about the error in the atom.

- `ClaimableRS.sag_to_charlist/1` - Deconstructs a SAG struct to a charlist. Expects as argument the SAG struct. Returns a list of the challenge, ring and responses (like in `CryptoNifs.rs_nif_sign/4`).

```elixir
iex(1)> ring_idx = 0
iex(2)> %{sk: sk, vk: vk} = ClaimableRS.crs_gen() # Generate claimable RS key pair
%{
  sk: {{[...], [...]}, [...], [...], [...]},
  vk: {[...], [...]}
}
iex(3)> {pk_rs, _} = vk # Get the RS pub key from the CRS pub key
{[...], [...]}
iex(4)> ring = CryptoUtils.gen_ring(ring_idx, pk_rs, 3) # Generate a ring of size 3
[[...], [...], [...]]
iex(5)> {:ok, ring_sig} = ClaimableRS.crs_sign(0, sk, ring, 'Message to be signed') # Sign message
{:ok, %SAG{
   chal: [...],
   ring: [[...], [...], [...]],
   resp: [[...], [...], [...]],
   commitment: [...],
   __uf__: []
}}
iex(6)> ClaimableRS.crs_vrfy(ring_sig, 'Message to be signed') # Verify signature
{:ok, true}
iex(7)> ClaimableRS.crs_vrfy(ring_sig, 'Different (invalid) message')
{:ok, false}
iex(8)> {:ok, claim} = ClaimableRS.crs_claim(0, sk, ring_sig) # Generate claim
{:ok, {[...], [...]}}
iex(9)> ClaimableRS.crs_vrfy_claim(vk, ring_sig, claim) # Verify claim
{:ok, true}
```

---
#### **_C_RSDAKE_**
The `C_RSDAKE` module contains functions for performing the RSDAKE key exchange protocol using claimable ring signature schemes. It provides 4 functions, representing each of the stages in the key exchange protocol. The functions are as follows:

- `C_RSDAKE.initialise/1` - Generate the first message in the protocol. Expects as a single argument the identity of the sender as a charlist. If valid, it returns {:ok, {crypto_state, msg}} where crypto_state is a struct containing all crypto structs needed for future stages of the exchange and msg is the message to be sent to the receiver. If invalid (argument type error), it returns {:error, :invalid_identity}.

- `C_RSDAKE.respond/3` - Generate a response to the first message of the exchange. Expects as arguments the identity of the receiver, long-term claimable ring signature key pair and the initial exchange message. If successful, it returns {:ok, {crypto_state, msg}} where crypto_state is a struct containing all crypto structs needed for future stages of the exchange and msg is the response to be sent to the receiver. If invalid (argument error), it returns {:error, atom}, where atom includes information for the error type.

- `C_RSDAKE.finalise/3` - Generate the final message of the exchange. Expects as arguments the identity of the sender, crypto_struct generated by the `C_RSDAKE.initialise/1` function and the response from the second stage of the exchange. If successful, it returns {:ok, {crypto_state, msg}} where crypto_state is a struct containing all crypto structs needed for future stages of the exchange and msg is the final message to be sent to the receiver. If invalid (argument error), it returns {:error, atom}, where atom includes information for the error type.

- `C_RSDAKE.verify_final/3` - Verify the final message of the exchange. Expects as arguments the identity of the receiver, crypto_struct generated by the `C_RSDAKE.initialise/1` function and the final message from the third stage of the exchange. If successful, it returns {:ok, boolean} where the boolean indicates the validity of the final message. If invalid (argument error), it returns {:error, atom}, where atom includes information for the error type.

```elixir
iex(1)> init_id = 'INITIATOR_IDENTITY' # The identity of the initiator
'INITIATOR_IDENTITY'
iex(2)> recv_id = 'RECEPIENT_IDENTITY' # The identity of the recepient
'RECEPIENT_IDENTITY'
iex(3)> {:ok, {init_struct, {_, init_msg}}} = C_RSDAKE.initialise(init_id)
# Long structure omitted
iex(4)> lt_keys = ClaimableRS.crs_gen() # Generate long-term CRS keys for responder
%{
  sk: {{[...]}, [...], [...], [...]},
  vk: {[...], [...]}
}
iex(5)> {:ok, {resp_struct, {_, resp_msg}}} = C_RSDAKE.respond(recv_id, lt_keys, init_msg)
# Long structure omitted
iex(6)> {:ok, {fin_struct, {_, fin_msg}}} = C_RSDAKE.finalise(init_id, init_struct, resp_msg)
# Long structure omitted
iex(7)> C_RSDAKE.verify_final(recv_id, resp_struct, fin_msg)
{:ok, true}
iex(8)> resp_struct.shared_secret == fin_struct.shared_secret # Check that the shared secret is the same for both parties
true
iex(9)> resp_struct.shared_secret # The shared secret (responder)
<<...>>
```

This concludes the cryptographic module tests. Below are example tests for the information dispersal modules (Rabin's IDA and Security Enhanced IDA).

---
#### **_RabinIDA_**
This is an implementation of Rabin's Information Dispersal Algorithm. It provides 4 functions, two of which are used for splitting and reconstructing data and the other two are only used for encoding/decoding the data output for serialisation and will not be described here. To improve performance, this module calls a C NIF to perform matrix multiplication operations.
The available functions are:

- `RabinIDA.split/3` - Split a binary into n shares. Expects as arguments the binary to be split, the number of shares to be generated (n) and the size of each share, which is also the reconstruction threshold. Returns a list of maps with the data and index of each share (accessible via the :data, :idx keys respectively).

- `RabinIDA.reconstruct/1` - Attempt to reconstruct the original data from the a list of maps generated by the `RabinIDA.split/3` function. If successful, it returns {:ok, binary} where binary is the original data. If unsuccessful, it returns {:error, nil}.

```elixir
iex(1)> shares = RabinIDA.split("This will be split into 4 shares", 4, 4)
[
  %{
    data: <<...>>,
    share_idx: 1
  }, %{
    data: <<...>>,
    share_idx: 2
  }, %{
    data: <<...>>,
    share_idx: 3
  }, %{
    data: <<...>>,
    share_idx: 4
  }
]
iex(2)> RabinIDA.reconstruct(shares)
{:ok, "This will be split into 4 shares"}
iex(3)> new_shares = RabinIDA.split("This will be split into 4 shares with threshold 2", 4, 2)
iex(3)> rand_shares = Enum.take_random(new_shares, 2) # Take 2 random shares out of the 4
[
  %{
    data: <<...>>,
    share_idx: 2
  }, %{
    data: <<...>>,
    share_idx: 1
  }
]
iex(4)> RabinIDA.reconstruct(rand_shares)
{:ok, "This will be split into 4 shares with threshold 2"}
```
> **Note:** The reconstruction will only work if the number of shares passed to it is equal to the reconstruction threshold. The example above shows how a random number of items from a list can be taken using `Enum.take_random/2`.

---
#### **_SecureIDA_**
This module is an implementation of a security enhanced information dispersal algorithm. Overall its usage is almost identical to RabinIDA, with the exception that it returns more complicated structs and handles errors better. It works by encrypting the data with AES256-CBC using a random key and IV, splitting the data into shares using RabinIDA and splitting the key intro shares using Shamir's Secret Sharing Scheme, then adding a part of each to a message. The available functions are:

- `SecureIDA.disperse/4` - Disperse a binary into shares. Expects as input the binary to be split, the number of shares to be generated (n), the share size (reconstruction threshold) m, and the integer message ID (used to identify shares of the same message). Returns a list of share stricts.

- `SecureIDA.reconstruct/1` - Attempt to reconstruct the original data from a list of share structs generated by the `SecureIDA.disperse/4` function. Unlike RabinIDA, this function handles being given more messages than the recontruction threshold. If successful, it returns {:ok, binary} where binary is the original data. If unsuccessful, it returns {:error, string}, where the string contains an error message.

```elixir
iex(1)> shares = SecureIDA.disperse("A secure dispersal message", 4, 3, 1234567)
[
  %Share{
    message_id: 1234567,
    total_shares: 4,
    share_idx: 1,
    share_threshold: 3,
    key_share: %KeyShare{
      aes_key: <<...>>,
      iv: <<...>>
    },
    data: <<...>>
  },
  ...
]
iex(2)> SecureIDA.reconstruct(shares)
{:ok, "A secure dispersal message"}
```

---
### **FileIO (Services)**
The FileIO service is a simple file transfer service which allows users to test out the functionality of the LAP2 network. It is not recommended to be run outside of a docker contained as it has access to the entire filesystem and will happily read and write to any file if instructed to do so and the program has the correct permissions. It cannot be used by itself since it requires on an instance of the LAP2 network node to be running. The following functions are available:

- `FileIO.run_service/1` - Starts the FileIO service. Expects as input the name of the master GenServer process, however it is advisable to call it using `NetUtils.run_fileio/1`, which expects the network address of the host node and resolves the master process name automatically. This function will return {:ok, service_id} if successful, where service_id is the name of the service process. If unsuccessful, it will return {:error, reason}.

- `FileIO.request_file/5` - Requests a file from an introduction point in the network and writes it to the filesystem. Expects a list of network addresses of the introduction points to use, the name of the remote service process, the name of the remote file, the save location on the local filesystem and the name of the local FileIO service process. The function will return :ok or :error based on the initial attempt to send the requests and then write to the filesystem if the retrieval was successful.

- `FileIO.stop_service/1` - Stops the FileIO service. Expects as input the name of the service process, which is returned by `FileIO.run_service/1`. This function will return :ok if successful, or {:error, reason} if unsuccessful.

> **Note:** The FileIO service is not designed to be used by itself. Code examples can be found in the [File Transfer Example](#file-transfer-example).

---
## **Task List**

The following tasks are planned for the LAP2 project:

### **General**

- [x] Unit testing
- [x] Docker build
- [x] Error logging
- [x] Command Line Interface
- [x] Configuration file parsing

### **Networking**

- [x] Efficient UDP datagram buffering and handling
- [x] UDP socket wrapper
- [x] TCP socket wrapper
- [x] ProtoBuff serialisation/deserialisation
- [x] Peer connection and discovery
- [x] Distributed hash table
- [x] Clove storage and relay
- [x] Introduction Points
- [x] Proxy routing
- [x] Connection supervisor module

### **Garlic Cast**

- [x] Rabin's IDA
- [x] Security Enhanced IDA
- [x] Proxy discovery

### **Crypto**

- [x] Cryptographic primitives NIF
- [x] Claimable Ring Signature scheme
- [x] RSDAKE
- [x] RSDAKE - Claimability
- [x] Key exchange

### **Math**

- [x] Matrix module
- [x] Matrix NIF

### **Bonus**
- [ ] Add function argument descriptions to docs
- [ ] Add proxy heartbeat
- [ ] Refactor registry_table as ETS
- [ ] Sybil guard
- [ ] Rewrite matrix NIF module in Rust
- [ ] Contribution verification
- [ ] Removing bad nodes
- [ ] Phoenix frontend
