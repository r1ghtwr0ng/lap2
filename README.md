# **LAP2**
<img src="https://user-images.githubusercontent.com/42644807/234358607-a11e2223-3ddf-489d-af27-5392e65dc4a5.png" alt="Image" width="150" height="150">

## **Lightweight Anonymous P2P Overlay Network**
[![Tests](https://img.shields.io/github/actions/workflow/status/r1ghtwr0ng/lap2/.github/workflows/elixir.yml?branch=master&label=Elixir%20CI&logo=github)](https://github.com/r1ghtwr0ng/lap2/actions/workflows/elixir.yml)
[![Docs](https://img.shields.io/badge/Docs-LAP2%20Docs-blue)](https://r1ghtwr0ng.github.io/lap2/LAP2.html)
[![License](https://badgen.net/badge/License/MIT/blue)](https://opensource.org/licenses/MIT)
## **Introduction**


> &nbsp;&nbsp;The significance of privacy and anonymity in preserving human rights is paramount, especially in the current digital era, where internet users are exposed to various data collection risks such as corporate surveillance, ransomware, and government mass surveillance. The goal of the LAP2 project is to create an anonymous peer-to-peer overlay network that reduces cryptographic overhead for intermediate relays in proxy chains, making it more accessible for usage by low-spec IoT devices. <br><br>
&nbsp;&nbsp;LAP2 is inspired by and builds upon existing solutions for anonymous peer-to-peer networks such as Tor and I2P while attempting to improve performance using recently published research on a new, more efficient routing technique called Garlic Cast. Furthermore, LAP2 extends the functionality of the existing deniable authenticated key exchange algorithm RSDAKE to introduce the first claimable deniable authenticated key exchange protocol, C-RSDAKE, complete with an open-source Rust implementation.
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

- Build a Docker container for the project by running the following command in the root directory:

    ```bash
    docker build -t lap2 .
    ```
- Start the container in the LAP2 debug shell (IEx) with the following command:

    ```bash
    docker run -it lap2
    ```
- Instructions on how to use the debug shell can be found in the section below.

    **Note:** If you want to run a different shell inside the container, set the `ENTRYPOINT` in the Dockerfile to the desired shell (e.g., `/bin/bash`), then rebuild the container and run it with the same command as above.

    That's it! Now you can use the project inside a Docker container.

    **Note:** If ran interactively using docker, the project should automatically start in the IEx shell (unless the Dockerfile entrypoint is changed).

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
Here is a general example of testing out file transfer over the simulated LAP2 network inside the IEx shell:

```elixir
iex> addresses = NetUtils.spawn_network(100, 40000) # Start network
iex> NetUtils.bootstrap_network() # Setup routing tables
iex> host = Enum.random(addresses) # Pick a random host
iex> client = Enum.random(addresses) # Pick a random client
iex> Enum.each(0..5, fn _ -> # Establish anonymous routes
...         NetUtils.find_anon_proxy(host)
...         NetUtils.find_anon_proxy(client)
...     end)
iex> # TODO
iex> NetUtils.stop_network() # Stop the network
```

### **C-RSDAKE example**
In the previous example C-RSDAKE was used during the anonymous route establishment phase. To test out the C-RSDAKE protocol in isolation, we can use the `CryptoUtils` module.
Here is a general example of testing out the C-RSDAKE protocol inside the IEx shell:

```elixir
iex> # TODO
```
For more detailed usage instructions as well as more specific test examples for the various modules, refer to the sections below.

---
### **NetUtils Module (Networking)**

To start off, use the `NetUtils.spawn_network` function to simulate a network environment by starting multiple network nodes simultaneously.

#### **_Arguments:_**

This function takes the following arguments:

1. `num_nodes`: (integer) The number of nodes to be started.
2. `start_port`: (integer) The starting port for the first node. The port numbers for subsequent nodes are incremented by 1 from this number.

#### **_Returns:_**

This function returns a list of network addresses (string type) for the spawned nodes.

#### **_Usage Example:_**

In the following example, we are spawning 100 nodes starting from port 40000. The returned network addresses are stored in the `addresses` variable:

```elixir
iex> addresses = NetUtils.spawn_network(100, 40000)
```
> **Note:** The number of running nodes is limited by the number of available ports on the host machine. If you get an error saying that the port is already in use, try using a different port number. Try to run less than 1000 nodes to avoid hitting an open port or experiencing performance issues.

The network address of any node can be obtained using the `Enum` module as such:

```elixir
iex> address_0 = Enum.at(addresses, 0) # Take the address at index 0
iex> rand_address = Enum.random(addresses) # Take a random address
```

Alternatively, nodes can be spawned individually using `NetUtils.start_node`. To do this, first construct a config file for the node using the `NetUtils.make_config` function, then pass the config file to the `NetUtils.start_node` function. However, if `NetUtils.start_network` has not been called before, the ETS table must be created manually before spawning the node. This can be done using the following commands:

```elixir
iex> :ets.new(:network_registry, [:named_table, :set, :public]) # Create ETS table
iex> udp_port = 40000 # Set UDP port
iex> tcp_port = 40000 # Set TCP port
iex> addr = Generator.generate_hex(8) # Set network address, any string will do
iex> config = NetUtils.make_config(addr, udp_port, tcp_port) # Create config
iex> NetUtils.spawn_node(config) # Start node
```
---
Once the network has been started, the nodes' routing tables should be bootstrapped. This can be accomplished in multiple ways:

- If you wish to bootstrap all network nodes **without** making any network requests (quickest and most reliable way), use `NetUtils.seed_network`. This function will update each node's routing table with a copy of the global one (stored in an ETS table). This function takes no arguments:

    ```elixir
    iex> NetUtils.seed_network()
    ```

- Alternatively, if you wish to bootstrap all network nodes by using network DHT update requests, use `NetUtils.bootstrap_network`. This function will first seed a single node with the global registry table, then instruct all other nodes to request a DHT update from it. Again, this function takes no arguments and returns an atom of the status of the operation:

    ```elixir
    iex> NetUtils.bootstrap_network()
    ```

- The final option is to bootstrap individual nodes. To do that, first use `NetUtils.seed_node` to setup a random node's DHT table as before. This function accepts no arguments but returns the IP address and port of the node that was seeded:

    ```elixir
    iex> {:ok, seed_addr} = NetUtils.seed_node()
    ```

- Then, use `NetUtils.bootstrap_node` to instruct another node to request a DHT update from the seeded node. This function takes the network address of the client node and the IP address and port of DHT provider node:

    ```elixir
    iex> NetUtils.update_dht(lap2_addr, seed_addr)
    ```

    This process can be repeated to bootstrap the entire network (which is exactly what `NetUtils.bootstrap_network` does).

To check the contents of a node's routing table, use `NetUtils.inspect_dht`. This function takes the network address of the node as an argument and returns a map of the node's routing table:

```elixir
iex> NetUtils.inspect_dht(lap2_addr)
```
---
Once the nodes have had their routing tables set up, they can start communicating with each other. To set up anonymous routes, select any node and use `NetUtils.find_anon_proxy` to instruct it to find an anonymous proxy. This function takes the network address of the node as an argument and returns the status of the operation:

```elixir
iex> NetUtils.find_anon_proxy(lap2_addr)
```

The function can be called multiple times to establish multiple proxies:

```elixir
iex> Enum.each(1..num_proxies, fn _ -> NetUtils.find_anon_proxy(lap2_addr) end)
```

Once a sufficient number of proxies has been established (depends on config setup, usually >1 in DEV environment), a node can request a random proxy to become its introduction point. To do this, use `NetUtils.find_intro_point`.

**_Arguments:_**
This function expects the following arguments:
1. `lap2_addr`: (string) The network address of the node requesting the introduction point.
2. `service_identifier`: (string) The service identifier of the service that the node wishes to access. See how to generate service identifiers in the [FileUtils](#fileutils-services) section.
```
iex> NetUtils.find_intro_point(lap2_addr, service_identifier)
```

Verify that an introduction point has been setup and find its network address by using `NetUtils.list_intro_points` (no arguments required):

```elixir
iex> NetUtils.list_intro_points()
```

Retrieving remote files anonymously is covered in the [FileUtils](#fileutils-services) section.

---
Finally, to stop the network, use `NetUtils.stop_network`. This function takes no arguments and returns the status of the operation:

```elixir
iex> NetUtils.stop_network()
```

If needed, individual nodes can be stopped using `NetUtils.stop_node`. This function takes the network address of the node as an argument and returns the status of the operation:

```elixir
iex> NetUtils.stop_node(lap2_addr)
```

This just about covers the networking section of the LAP2 project. The following sections will cover the other modules in the project.

---
### **(Cryptography)**
- The cryptographic section has a wide range of modules that can be tested out. To start off, 
---
### **FileUtils (Services)**
---
## **Task List**

The following tasks are planned for the LAP2 project:

### **General**

- [x] Unit testing
- [x] Docker build
- [x] Error logging
- [ ] Command Line Interface
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
