# Reference

[networkop/docker-topo](https://github.com/networkop/docker-topo/tree/master/topo-extra-files/host)

## Overview

The Dockerfile allows user to build alpine-host image, using which can be used as clients in the Fabric topology instead of using cEOS switch.

The alpine-hosts contains the following tools:

- libteam
- open-lldp
- sudo
- tcpdump
- scapy
- iperf3

## Host configuration

### Bonding Configuration

Supported bonding modes are:

- lacp
- static
- none (default)

The teaming mode needs to be specified in the containerlab topology.yml file when deploying the fabric.

Example:

```shell
    client1:
      kind: linux
      image: alpine-host
      mgmt_ipv4: 172.100.100.10
      env:
        TMODE: lacp
    client2:
      kind: linux
      image: alpine-host
      mgmt_ipv4: 172.100.100.11
      env:
        TMODE: lacp
```

### L3 configuration

Currently L3 configuration has to be done manually. Following example illustrates setting up:

- VLAN ID
- Interface IP and Netmask
- Route to directly connected GW

```shell
# configure IP and VLAN
/ $ sudo vconfig add team0 110
/ $ sudo ifconfig team0.110 10.1.10.11 netmask 255.255.255.0
/ $ sudo ip link set team0.110 up

# Add route pointing to GW on the leaf switch
/ $ sudo ip route add 10.1.0.0/16 via 10.1.10.1 dev team0.110

# ping GW

/ $ route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         172.100.100.1   0.0.0.0         UG    0      0        0 eth0
10.1.0.0        10.1.10.1       255.255.0.0     UG    0      0        0 team0.110
10.1.10.0       0.0.0.0         255.255.255.0   U     0      0        0 team0.110
172.100.100.0   0.0.0.0         255.255.255.0   U     0      0        0 eth0

/ $ sudo ping -c 2 10.1.10.1
PING 10.1.10.1 (10.1.10.1): 56 data bytes
64 bytes from 10.1.10.1: seq=0 ttl=64 time=20.531 ms
64 bytes from 10.1.10.1: seq=1 ttl=64 time=5.946 ms

--- 10.1.10.1 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 5.946/13.238/20.531 ms

/ $ arp -a
? (10.1.10.1) at 00:00:00:00:00:01 [ether]  on team0.110
```
