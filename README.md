# **LAP2** 
## *Lightweight Anonymous P2P Overlay Network*
<br>

# **About**
### &nbsp;&nbsp;&nbsp;&nbsp;The main purpose of this project is to provide an anonymous peer-to-peer (AP2P) overlay network with significantly lower cryptographic overhead, compared to conventional anonymity networks such as TOR and I2P, thus allowing low-spec IoT devices to be incorporated into the network.
<br>

### &nbsp;&nbsp;&nbsp;&nbsp;This project is implemented using the Elixir programming language.
<br>

# **TODO**

## *General*
- [ ] Testing framework
- [ ] Docker build
- [x] Error logging
- [x] Configuration file parsing
## *Networking*
- [x] Efficient UDP datagram buffering and handling
- [x] UDP communication module
- [x] ProtoBuff serialisation/deserialisation
- [ ] Peer connection and discovery
- [ ] Distributeed hash table
- [x] Clove storage and relay
- [ ] Introduction Points
- [ ] Connection supervisor module
## *Garlic Cast*
- [x] Rabin's IDA
- [x] Security Enchansed IDA
- [ ] Dynamic proxy discovery

## *Crypto*
- [ ] Key exchange
- [ ] Cryptographic module
- [ ] RSDAKE - Random Oracle
- [ ] RSDAKE - Claimability

## *Math*
- [x] Matrix module

## *Bonus*
- [ ] Sybil guard
- [ ] Rewrite matrix module as NIF
- [ ] Contribution verification
- [ ] Removing bad nodes
- [ ] Phoenix frontend
