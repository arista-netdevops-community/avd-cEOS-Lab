# Reference

## Alpine-host Configuration

### Teaming Configuration

If using alpine-host containers as end hosts/clients, the following teaming modes are supported:

* [x] lacp
* [x] static
* [x] active-backup
* [x] none (*default*)

The teaming mode needs to be specified in the containerlab `topology.yml` file under the respective lab's directory.

```yaml title="Example"
    client1:
      kind: linux
      image: alpine-host
      mgmt_ipv4: 172.100.100.10
      env:
        TMODE: lacp # (1)!
    client2:
      kind: linux
      image: alpine-host
      mgmt_ipv4: 172.100.100.11
      env:
        TMODE: static # (2)!
    client3:
      kind: linux
      mgmt_ipv4: 172.100.100.10
      env:
        TMODE: active-backup # (3)!
        TACTIVE: eth1 # (4)!
```

1. Sets teaming mode as `lacp` when teaming `eth1` and `eth2` on the client side.
2. Sets teaming mode as `static` when teaming `eth1` and `eth2` on the client side.
3. Sets the teaming mode as `active-backup` where the active interface on the client can be specified using `TACTIVE` setting below.
4. `TACTIVE` specified the active interface (ex. eth1) when using `active-backup` teaming mode as specified by `TMODE`. The other interface (ex. eth2) will be automatically set to backup.

### Teaming status

To check the teaming status on the client side. Login to the client container:

```bash
docker exec -it clab-avdirb-client1 /bin/sh
```

Use the `teamdctl` command to view the `team0` state.

```sh title="Example" hl_lines="1"
/ $ sudo teamdctl team0 state view
setup:
  runner: lacp
ports:
  eth1
    link watches:
      link summary: up
      instance[link_watch_0]:
        name: ethtool
        link: up
        down count: 0
    runner:
      aggregator ID: 125, Selected
      selected: yes
      state: current
  eth2
    link watches:
      link summary: up
      instance[link_watch_0]:
        name: ethtool
        link: up
        down count: 0
    runner:
      aggregator ID: 125, Selected
      selected: yes
      state: current
runner:
  active: yes
  fast rate: yes
```

### Host L3 Configuration

If using alpine-host as the end client, the client-side configuration can be done using:

1. Using the `labs/evpn/avd_<lab>/host_l3_config/l3_build.sh`. The shell script contains the command to configure the VLAN, IP address, and Gateway route on the alpine-hosts. For example, refer to the Getting Started guide [here](./quickStart.md/#configuring-end-hosts).
2. Manually using the following steps.

```bash

# Login to the container
$ docker exec -it clab-avdirb-client1 /bin/sh

# Configure IP and VLAN
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

## Lab Deployment using Makefile

Each lab contains a `Makefile`, which simplifies the lab deployment steps using the `make` command.

```bash title="Example"
$ cd avd-cEOS-Lab/labs/evpn/avd_sym_irb

$ make help
deploy                         Complete AVD & cEOS-Lab Deployment
destroy                        Delete cEOS-Lab Deployment and AVD generated config and documentation
help                           Display help message
```

`make deploy` will perform the following actions

* [x] Start the containerlab topology
* [x] Generate and deploy switch configuration using AVD
* [x] Configure the alpine-host clients.

`make destroy` will perform the following actions

* [x] Destroy the containers and remove all the containerlab and the AVD generated configuration and artifacts.
