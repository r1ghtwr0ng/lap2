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

The documentation for LAP2 project can be found [here](https://r1ghtwr0ng.github.io/lap2/LAP2.html).<br>
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
- The IEx shell can be used to test out much of the functionality of the modules in the project (with the exception of private functions). The following sections show some examples of how to test out some of LAP2's most important features.
#### **Networking**
- In order to simulate a network environment, multiple nodes can be spawned simultaneously. This can be done using the `spawn_network` function, made available by the utility script. The function takes in the number of nodes to spawn and the port to use for the first node (subsequent nodes' port numbers are incremented by 1). The function returns a hash map of network and IP addresses for the instanciated nodes. For example, to spawn 5 nodes starting from port 5000 and save the return in the addresses variable, run the following command:

    ```elixir
    addresses = spawn_network(5, 5000)
    ```
- Once the network has been started, the nodes' routing tables should be bootstrapped. This can be done using the `bootstrap_nodes` utility function. The function takes in the addresses hash map and updates the routing tables of all the nodes with a part of the addresses hash map. For example, to bootstrap the nodes with the addresses hash map created in the previous step, run the following command:

    ```elixir
    bootstrap_nodes(addresses)
    ```

- If you want to perform routing table updates over the network, then you can use the `bootstrap_single_node` function to bootstrap a single node with the addresses hash map. This function accepts the addresses hash map and the node's LAP2 address as arguments. For example, to bootstrap node #3 with the addresses hash map created in the previous step, run the following command:

    ```elixir
    node_3_address = Enum.at(Enum.keys(addresses), 2)
    bootstrap_single_node(addresses, node_3_address)
    ```

- From here, DHT update requests can be performed over the network. For example, here's how to perform a DHT update request from node #1 to node #3:

    ```elixir
    node_1_address = Enum.at(Enum.keys(addresses), 0)
    update_dht(node_1_address, node_3_address)
    ```
    
#### **Cryptography**
- The cryptographic section has a wide range of modules that can be tested out. To start off, 
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
