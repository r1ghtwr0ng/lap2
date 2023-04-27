# LAP2
<img src="https://user-images.githubusercontent.com/42644807/234358607-a11e2223-3ddf-489d-af27-5392e65dc4a5.png" alt="Image" width="150" height="150">

## Lightweight Anonymous P2P Overlay Network
[![Tests](https://img.shields.io/github/actions/workflow/status/r1ghtwr0ng/lap2/.github/workflows/elixir.yml?branch=master&label=Elixir%20CI&logo=github)](https://github.com/r1ghtwr0ng/lap2/actions/workflows/elixir.yml)
[![Docs](https://img.shields.io/badge/Docs-LAP2%20Docs-blue)](https://r1ghtwr0ng.github.io/lap2/LAP2.html)
[![License](https://badgen.net/badge/License/MIT/blue)](https://opensource.org/licenses/MIT)
## Introduction


The significance of privacy and anonymity in preserving human rights is paramount, especially in the current digital era, where internet users are exposed to various data collection risks such as corporate surveillance, ransomware, and government mass surveillance. The goal of the LAP2 project is to create an anonymous peer-to-peer overlay network that reduces cryptographic overhead for intermediate relays in proxy chains, making it more accessible for usage by low-spec IoT devices. 

LAP2 is inspired by and builds upon existing solutions for anonymous peer-to-peer networks such as Tor and I2P while attempting to improve performance using recently published research on a new, more efficient routing technique called Garlic Cast. Furthermore, LAP2 extends the functionality of the existing deniable authenticated key exchange algorithm RSDAKE to introduce the first claimable deniable authenticated key exchange protocol, C-RSDAKE, complete with an open-source Rust implementation.

## About

The LAP2 project is implemented using the Elixir programming language. The main objective is to create an anonymous peer-to-peer overlay network with a significantly lower cryptographic overhead compared to conventional anonymity networks such as TOR and I2P. This will allow low-spec IoT devices to be incorporated into the network.

To improve performance in certain sections, NIFs (Native Implemented Functions) are used to implement computationally intensive algorithms in C and several cryptographic schemes in Rust.

## Garlic Cast

Garlic Cast is a new, more efficient routing technique that LAP2 uses to improve network performance. It does not require the usage of layered cryptography between intermediate relays, thus increasing performance.

## C-RSDAKE

LAP2 extends the functionality of the existing deniable authenticated key exchange algorithm RSDAKE to introduce the first claimable deniable authenticated key exchange protocol, C-RSDAKE, complete with an open-source Rust implementation. When introduced within the AP2P network, the C-RSDAKE construction empowers users to verify each other's identities through cryptographic means independent of the network. This can be a desirable property for an anonymous network due to the lack of central certificate authorities and will extend the network's ability to provide a secure platform for expressing oneself online while mitigating the risk of third-party monitoring and interference.

## TODO

The following tasks are planned for the LAP2 project:

### General

- [x] Unit testing
- [ ] Docker build
- [x] Error logging
- [x] Configuration file parsing

### Networking

- [x] Efficient UDP datagram buffering and handling
- [x] UDP socket wrapper
- [ ] TCP socket wrapper
- [x] ProtoBuff serialisation/deserialisation
- [x] Peer connection and discovery
- [ ] Distributed hash table
- [x] Clove storage and relay
- [ ] Introduction Points
- [x] Proxy routing
- [ ] Connection supervisor module

### Garlic Cast

- [x] Rabin's IDA
- [x] Security Enhanced IDA
- [x] Proxy discovery

### Crypto

- [x] Cryptographic primitives NIF
- [ ] Claimable Ring Signature scheme
- [ ] RSDAKE
- [ ] RSDAKE - Claimability
- [ ] Key exchange

### Math

- [x] Matrix module
- [x] Matrix NIF

### Bonus
- [ ] Sybil guard
- [x] Rewrite matrix module as NIF
- [ ] Contribution verification
- [ ] Removing bad nodes
- [ ] Phoenix frontend
