#!/bin/sh

UPLINK='eth'

# TMODE is expected to be set via the containerlab topology file prior to deployment
# Expected values are "lacp" or "static" or "active-backup" which will bond eth1 and eth2
if [ -z "$TMODE" ]; then
  TMODE='none'
fi

# TACTIVE and TBACKUP to be set via the containerlab topology file for active-backup runner
# expected values are "eth1" or "eth2" default is "eth1" active and "eth2" backup
if [ -z "$TACTIVE" ]; then
  TACTIVE='eth1'
  TBACKUP='eth2'
elif [ "$TACTIVE" == 'eth1' ]; then
  TBACKUP='eth2'
elif [ "$TACTIVE" == 'eth2' ]; then
  TBACKUP='eth1'
fi

echo "teaming mode is " $TMODE

#######################
# Re-run script as sudo
#######################

if [ "$(id -u)" != "0" ]; then
  exec sudo --preserve-env=TMODE,TACTIVE,TBACKUP "$0" "$@"
fi

##########################
# Check operation status 
##########################

check=$( cat /sys/class/net/eth1/operstate 2>/dev/null )

while [ "up" != "$check" ] ; do
    echo "waiting for interface to come up"
    check=$( cat /sys/class/net/eth1/operstate 2>/dev/null )
done

check=$( cat /sys/class/net/eth2/operstate 2>/dev/null )

while [ "up" != "$check" ] ; do
    echo "waiting for interface to come up"
    check=$( cat /sys/class/net/eth1/operstate 2>/dev/null )
done

cat /sys/class/net/eth1/operstate
cat /sys/class/net/eth1/operstate

###############
# Enabling LLDP
###############

lldpad -d
for i in `ls /sys/class/net/ | grep 'eth\|ens\|eno'`
do
    lldptool set-lldp -i $i adminStatus=rxtx
    lldptool -T -i $i -V sysName enableTx=yes
    lldptool -T -i $i -V portDesc enableTx=yes
    lldptool -T -i $i -V sysDesc enableTx=yes
done

################
# Teaming setup
################

cat << EOF > /home/alpine/teamd-lacp.conf
{
   "device": "team0",
   "runner": {
       "name": "lacp",
       "active": true,
       "fast_rate": true,
       "tx_hash": ["eth", "ipv4", "ipv6"]
   },
     "link_watch": {"name": "ethtool"},
     "ports": {"eth1": {}, "eth2": {}}
}
EOF

cat << EOF > /home/alpine/teamd-static.conf
{
 "device": "team0",
 "runner": {"name": "roundrobin"},
 "ports": {"eth1": {}, "eth2": {}}
}
EOF

cat << EOF > /home/alpine/teamd-active-backup.conf
{
  "device": "team0",
  "runner": {"name": "activebackup"},
  "link_watch": {"name": "ethtool"},
  "ports": {
    "$TACTIVE": {
      "prio": 100
    },
    "$TBACKUP": {
      "prio": -10
    }
  }
}
EOF

if [ "$TMODE" == 'lacp' ]; then
  TARG='/home/alpine/teamd-lacp.conf'
elif [ "$TMODE" == 'static' ]; then
  TARG='/home/alpine/teamd-static.conf'
elif [ "$TMODE" == 'active-backup' ]; then
  TARG='/home/alpine/teamd-active-backup.conf'
fi

if [ "$TMODE" == 'lacp' ] || [ "$TMODE" == 'static' ] || [ "$TMODE" == 'active-backup' ]; then
  teamd -v
  teamd -k -f $TARG 
  ip link set eth1 down
  ip link set eth2 down
  teamd -d -r -f $TARG

  ip link set team0 up
  UPLINK="team"
fi

#####################
# Enter sleeping loop
#####################

while sleep 3600; do :; done