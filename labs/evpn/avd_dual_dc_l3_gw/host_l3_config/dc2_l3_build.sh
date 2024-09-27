#!/bin/bash


CMD1='cat /etc/hostname; \
sudo vconfig add team0 120; \
sudo ifconfig team0.120 10.1.20.101 netmask 255.255.255.0;\
sudo ip link set up team0.120; \
sudo ip route add 10.1.0.0/16 via 10.1.20.1 dev team0.120; \
sudo ifconfig team0.120; \
sudo route -n
'

CMD2='cat /etc/hostname; \
sudo vconfig add team0 121; \
sudo ifconfig team0.121 10.1.21.102 netmask 255.255.255.0; \
sudo ip link set up team0.121; \
sudo ip route add 10.1.0.0/16 via 10.1.21.1 dev team0.121; \
sudo ifconfig team0.121; \
sudo route -n'

CMD3='cat /etc/hostname; \
sudo vconfig add team0 122; \
sudo ifconfig team0.122 10.1.22.103 netmask 255.255.255.0; \
sudo ip link set up team0.122; \
sudo ip route add 10.1.0.0/16 via 10.1.22.1 dev team0.122; \
sudo ifconfig team0.122; \
sudo route -n
'

CMD4='cat /etc/hostname; \
sudo vconfig add team0 123; \
sudo ifconfig team0.123 10.1.23.104 netmask 255.255.255.0; \
sudo ip link set up team0.123; \
sudo ip route add 10.1.0.0/16 via 10.1.23.1 dev team0.123; \
sudo ifconfig team0.123; \
sudo route -n'

echo "[INFO] Configuring clab-evpnl3gw-dc2-client1"
docker exec -it  clab-evpnl3gw-dc2-client1 /bin/sh -c "$CMD1"

echo "[INFO] Configuring clab-evpnl3gw-dc2-client2"
docker exec -it  clab-evpnl3gw-dc2-client2 /bin/sh -c "$CMD2"

echo "[INFO] Configuring clab-evpnl3gw-dc2-client3"
docker exec -it  clab-evpnl3gw-dc2-client3 /bin/sh -c "$CMD3"

echo "[INFO] Configuring clab-evpnl3gw-dc2-client4"
docker exec -it  clab-evpnl3gw-dc2-client4 /bin/sh -c "$CMD4"

echo "[INFO] Completed"

echo "Use [ docker exec -it clab-evpnl3gw-dc2-client<x> /bin/sh ] to login in host."