# Getting Started

This section provides an overview of the lab files and step-by-step instructions for deploying the lab.

Follow the [installation](./install.md) guide and ensure all prerequisites are satisfied.

This demo will follow the deployment and configuration of the following lab

??? example "EVPN Symmetric IRB"
    eBGP Overlay and eBGP Underlay

    2 Spines + 2 MLAG Leaf Pairs + 2 L2 leafs + 4 Clients

    ![Figure avd_sym_irb](./images/avdirb_v2.png)

## Lab Files

* Navigate to the `avd-cEOS-Lab/labs/evpn/avd_sym_irb` directory.

```bash
cd avd-cEOS-Lab/labs/evpn/avd_sym_irb
```

* The following files are part of this lab

```bash
.
├── ansible.cfg
├── group_vars
│   ├── AVD_LAB.yaml
│   ├── DC1_CONNECTED_ENDPOINTS.yaml
│   ├── DC1_FABRIC.yaml
│   ├── DC1_L2_LEAFS.yaml
│   ├── DC1_L3_LEAFS.yaml
│   ├── DC1_NETWORK_SERVICES.yaml
│   └── DC1_SPINES.yaml
├── host_l3_config
│   └── l3_build.sh
├── inventory.yaml
├── Makefile
├── playbooks
│   └── fabric-deploy-config.yaml
└── topology.yaml
```

??? note "topology.yaml"

    ```yaml
    name: avdirb # (1)!

    topology:
      kinds:
        ceos:
          startup-config: ../../../ceos_lab_template/ceos.cfg.tpl # (2)!
          image: ceosimage:4.30.1F # (3)!
          exec: # (4)!
            - sleep 10
            - FastCli -p 15 -c 'security pki key generate rsa 4096 eAPI.key'
            - FastCli -p 15 -c 'security pki certificate generate self-signed eAPI.crt key eAPI.key generate rsa 4096 validity 30000 parameters common-name eAPI'
        linux:
          image: alpine-host
      nodes:
        spine1:
          kind: ceos
          mgmt-ipv4: 172.100.100.2
        spine2:
          kind: ceos
          mgmt-ipv4: 172.100.100.3
        leaf1a:
          kind: ceos
          mgmt-ipv4: 172.100.100.4
        leaf1b:
          kind: ceos
          mgmt-ipv4: 172.100.100.5
        svc2a:
          kind: ceos
          mgmt-ipv4: 172.100.100.6
        svc2b:
          kind: ceos
          mgmt-ipv4: 172.100.100.7
        l2leaf2a:
          kind: ceos
          mgmt-ipv4: 172.100.100.8
        l2leaf2b:
          kind: ceos
          mgmt-ipv4: 172.100.100.9
        client1:
          kind: linux
          mgmt-ipv4: 172.100.100.10
          env:
            TMODE: lacp # (5)!
        client2:
          kind: linux
          mgmt-ipv4: 172.100.100.11
          env:
            TMODE: lacp
        client3:
          kind: linux
          mgmt-ipv4: 172.100.100.12
          env:
            TMODE: lacp
        client4:
          kind: linux
          mgmt-ipv4: 172.100.100.13
          env:
            TMODE: lacp

      links: # (6)!
        - endpoints: ["leaf1a:eth1", "spine1:eth1"]
        - endpoints: ["leaf1b:eth1", "spine1:eth2"]
        - endpoints: ["svc2a:eth1", "spine1:eth3"]
        - endpoints: ["svc2b:eth1", "spine1:eth4"]
        - endpoints: ["leaf1a:eth2", "spine2:eth1"]
        - endpoints: ["leaf1b:eth2", "spine2:eth2"]
        - endpoints: ["svc2a:eth2", "spine2:eth3"]
        - endpoints: ["svc2b:eth2", "spine2:eth4"]
        - endpoints: ["leaf1a:eth3", "leaf1b:eth3"]
        - endpoints: ["leaf1a:eth4", "leaf1b:eth4"]
        - endpoints: ["svc2a:eth3", "svc2b:eth3"]
        - endpoints: ["svc2a:eth4", "svc2b:eth4"]
        - endpoints: ["svc2a:eth5", "l2leaf2a:eth1"]
        - endpoints: ["svc2a:eth6", "l2leaf2b:eth1"]
        - endpoints: ["svc2b:eth5", "l2leaf2a:eth2"]
        - endpoints: ["svc2b:eth6", "l2leaf2b:eth2"]
        - endpoints: ["l2leaf2a:eth3", "l2leaf2b:eth3"]
        - endpoints: ["l2leaf2a:eth4", "l2leaf2b:eth4"]
        - endpoints: ["leaf1a:eth5", "client1:eth1"]
        - endpoints: ["leaf1b:eth5", "client1:eth2"]
        - endpoints: ["leaf1a:eth6", "client2:eth1"]
        - endpoints: ["leaf1b:eth6", "client2:eth2"]
        - endpoints: ["l2leaf2a:eth5", "client3:eth1"]
        - endpoints: ["l2leaf2b:eth5", "client3:eth2"]
        - endpoints: ["l2leaf2a:eth6", "client4:eth1"]
        - endpoints: ["l2leaf2b:eth6", "client4:eth2"]

    mgmt: # (7)!
      network: ceos_clab
      ipv4-subnet: 172.100.100.0/24
      ipv6-subnet: 2001:172:100:100::/80
    ```

    1. containerlab toplogy name. The containers names will be generated using the following pattern: `clab-{{lab-name}}-{{node-name}}`
    2. Template that cEOS-Lab node will use to build the baseline startup configuration.
    3. ceosimage that cEOS-Lab node will use to boot
    4. commands to generate a self-signed certificate for eAPI access
    5. bonding mode to use on alpine-host clients. Available modes are `lacp` `static` `active-backup` `none (default)`. For more details see [Reference](./references.md)
    6. define connections between switches and with clients
    7. subnet for management IP allocation for the containers. Can be changed to avoid conflicts with host or multiple labs

??? note "inventory.yaml"

    ```yaml
    all:
      children:
        AVD_LAB:
          children:
            DC1_FABRIC:
              children:
                DC1_SPINES:
                  hosts:
                    DC1_SPINE1:
                      ansible_host: 172.100.100.2
                    DC1_SPINE2:
                      ansible_host: 172.100.100.3
                DC1_L3_LEAFS:
                  children:
                    DC1_LEAF1:
                      hosts:
                        DC1_LEAF1A:
                          ansible_host: 172.100.100.4
                        DC1_LEAF1B:
                          ansible_host: 172.100.100.5
                    DC1_SVC2:
                      hosts:
                        DC1_SVC2A:
                          ansible_host: 172.100.100.6
                        DC1_SVC2B:
                          ansible_host: 172.100.100.7
                DC1_L2_LEAFS:
                  children:
                    DC1_L2_LEAF:
                      hosts:
                        DC1_L2_LEAF2A:
                          ansible_host: 172.100.100.8
                        DC1_L2_LEAF2B:
                          ansible_host: 172.100.100.9
              vars:
                ansible_connection: httpapi # (1)!
                ansible_httpapi_use_ssl: true # (5)!
                ansible_httpapi_validate_certs: false # (4)!
                ansible_user: admin # (2)!
                ansible_password: admin
                ansible_become: true
                ansible_become_method: enable # (3)!
                ansible_network_os: eos
                ansible_httpapi_port: 443
                ansible_python_interpreter: $(which python3)
            DC1_NETWORK_SERVICES: # (6)!
              children:
                DC1_L3_LEAFS:
                DC1_L2_LEAFS:

            DC1_CONNECTED_ENDPOINTS: # (7)!
              children:
                DC1_L3_LEAFS:
                DC1_L2_LEAFS:
    ```

    1. Ansible host uses eAPI to connect to cEOS-Lab nodes
    2. Ansible username/password to connect to cEOS-Lab nodes
    3. How to escalate privileges to get write access
    4. Do not validate SSL certificates
    5. Use SSL
    6. Creates a group named `DC1_NETWORK_SERVICES` which is resolved to the group_vars file `group_vars/DC1_NETWORK_SERVICES.yaml` which contains VLANs and VRFs specifications.
    7. Creates a group named `DC1_CONNECTED_ENDPOINTS` which is resolved to the group_vars file `group_vars/DC1_CONNECTED_ENDPOINTS.yaml` which contains specifications of connected endpoints (servers/clients).

??? note "ansible.cfg"

    ```cfg
    [defaults]
    host_key_checking = False
    inventory=./inventory.yaml
    gathering=explicit
    retry_files_enabled = False
    collections_paths = ../ansible-cvp:../ansible-avd:~/.ansible/collections:/usr/share/ansible/collections
    jinja2_extensions =  jinja2.ext.loopcontrols,jinja2.ext.do,jinja2.ext.i18n
    duplicate_dict_key=error
    stdout_callback = yaml
    bin_ansible_callbacks = True
    deprecation_warnings=False

    [persistent_connection]
    connect_timeout = 300
    command_timeout = 300
    ```

??? note "Makefile"

    ```make
    .PHONY: help
    help: ## Display help message
      @grep -E '^[0-9a-zA-Z_-]+\.*[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

    .PHONY: deploy # (1)!
    deploy: ## Complete AVD & cEOS-Lab Deployment
      @echo -e "\n############### \e[1;30;42mStarting cEOS-Lab topology\e[0m ###############\n"
      @sudo containerlab deploy -t topology.yaml
      @echo -e "\n############### \e[1;30;42mGenerating and deploying switch configuration\e[0m ###############\n"
      @ansible-playbook playbooks/fabric-deploy-config.yaml --flush-cache
      @echo -e "\n############### \e[1;30;42mConfiguring client nodes\e[0m ###############\n"
      @bash host_l3_config/l3_build.sh
      @echo -e "\n############### \e[1;30;42mcEOS-Lab Topology\e[0m ###############\n"
      @sudo containerlab inspect -t topology.yaml
      @echo -e "\n############### \e[1;30;42mcEOS-Lab Deployment Complete\e[0m ###############\n"

    .PHONY: destroy # (2)!
    destroy: ## Delete cEOS-Lab Deployment and AVD generated config and documentation
      @echo -e "\n############### \e[1;30;42mWiping nodes and deleting AVD configuration\e[0m ###############\n"
      @sudo containerlab destroy -t topology.yaml --cleanup
      @rm -rf .topology.yaml.bak config_backup/ snapshots/ reports/ documentation/ intended/
    ```

    1. `make deploy`: Starts the containerlab topology, builds and deploys configuration using AVD and configures clients/servers.
    2. `make destroy`: Delete the lab and wipe all the AVD-generated configurations and artifacts.

??? note "host_l3_config/l3_build.sh"

    Configures bond interface and assigns IP, and default gateway on the alpine-host clients.

    ```bash
    #!/bin/bash

    CMD1='cat /etc/hostname; \
    sudo vconfig add team0 110; \
    sudo ifconfig team0.110 10.1.10.101 netmask 255.255.255.0;\
    sudo ip link set up team0.110; \
    sudo ip route add 10.1.0.0/16 via 10.1.10.1 dev team0.110; \
    sudo ifconfig team0.110; \
    sudo route -n
    '

    CMD2='cat /etc/hostname; \
    sudo vconfig add team0 111; \
    sudo ifconfig team0.111 10.1.11.102 netmask 255.255.255.0; \
    sudo ip link set up team0.111; \
    sudo ip route add 10.1.0.0/16 via 10.1.11.1 dev team0.111; \
    sudo ifconfig team0.111; \
    sudo route -n'

    CMD3='cat /etc/hostname; \
    sudo vconfig add team0 112; \
    sudo ifconfig team0.112 10.1.12.103 netmask 255.255.255.0; \
    sudo ip link set up team0.112; \
    sudo ip route add 10.1.0.0/16 via 10.1.12.1 dev team0.112; \
    sudo ifconfig team0.112; \
    sudo route -n
    '

    CMD4='cat /etc/hostname; \
    sudo vconfig add team0 113; \
    sudo ifconfig team0.113 10.1.13.104 netmask 255.255.255.0; \
    sudo ip link set up team0.113; \
    sudo ip route add 10.1.0.0/16 via 10.1.13.1 dev team0.113; \
    sudo ifconfig team0.113; \
    sudo route -n'

    echo "[INFO] Configuring clab-avdirb-client1"
    docker exec -it  clab-avdirb-client1 /bin/sh -c "$CMD1"

    echo "[INFO] Configuring clab-avdirb-client2"
    docker exec -it  clab-avdirb-client2 /bin/sh -c "$CMD2"

    echo "[INFO] Configuring clab-avdirb-client3"
    docker exec -it  clab-avdirb-client3 /bin/sh -c "$CMD3"

    echo "[INFO] Configuring clab-avdirb-client4"
    docker exec -it  clab-avdirb-client4 /bin/sh -c "$CMD4"

    echo "[INFO] Completed"

    echo "Use [ docker exec -it clab-avdirb-client<x> /bin/sh ] to login in host."
    ```

??? note "playbooks/fabric-deploy-config.yaml"

    ```yaml
    - name: Build cEOS EVPN Symmetric IRB Fabric (eBGP Overlay and eBGP Underlay)
      hosts: DC1_FABRIC
      tasks:
        - name: Generate EOS configuration Snapshots
          tags: [snapshot]
          import_role:
            name: arista.avd.eos_snapshot # (1)!

        - name: Generate AVD Structured Configurations and Fabric Documentation
          import_role:
            name: arista.avd.eos_designs # (2)!

        - name: Generate Switch Intended Configurations and Documentation
          import_role:
            name: arista.avd.eos_cli_config_gen # (3)!

        - name: Deploy generated configuration to devices
          tags: [deploy]
          import_role:
            name: arista.avd.eos_config_deploy_eapi # (4)!

        - name: Validate states on EOS devices
          tags: [verify, never]
          import_role:
            name: arista.avd.eos_validate_state # (5)!
    ```

    1. This task uses the role `arista.avd.eos_snapshot`, which is used to collect commands on Arista EOS devices and generate a report which is found in the `snapshots` folder.
    2. This task uses the role `arista.avd.eos_designs`, which generates structured configuration for each device. This structured configuration can be found in the `intended/structured_configs` folder.
    3. This task uses the role `arista.avd.eos_cli_config_gen`, which generates the Arista EOS CLI configurations found in the `intended/configs` folder, along with the device-specific and fabric wide documentation found in the `documentation` folder. It relies on the structured configuration generated by `arista.avd.eos_designs`.
    4. This task uses the `arista.avd.eos_config_deploy_eapi` role to deploy the configurations directly to EOS nodes that were generated by the `arista.avd.eos_cli_config_gen` role.
    5. This task uses the `arista.avd.eos_validate_state` role to validate the EOS operational state. This is done by comparing the structured configuration generated by `arista.avd.eos_designs` and operational states (actual state) from EOS device and generating a report stored under `reports` folder.

??? note "group_vars"

    === "AVD_LAB.yaml"

        ```yaml
        ---
        local_users: # (1)!
          - name: admin
            privilege: 15
            role: network-admin
            sha512_password: "$6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1"

        name_servers: # (2)!
          - 1.1.1.1
          - 8.8.8.8

        ntp: # (3)!
          servers:
          - name: time.google.com
            preferred: true
            vrf: MGMT
            iburst: true

        service_routing_protocols_model: multi-agent # (4)!

        custom_structured_configuration_spanning_tree: # (5)!
          mode: mstp

        ip_routing: true # (6)!

        # hardcoding management0 for cEOS lab compatibility (default: Management1)
        mgmt_interface: Management0 # (7)!
        mgmt_gateway: 172.100.100.1
        mgmt_interface_vrf: MGMT

        # Management eAPI | Required for this Lab
        custom_structured_configuration_management_api_http:
          https_ssl_profile: eAPI

        # Management security required for SSL profile with strong ciphers
        custom_structured_configuration_management_security: # (8)!
          ssl_profiles:
            - name: eAPI
              certificate:
                file: eAPI.crt
                key: eAPI.key
              cipher_list: 'HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL'
        ```

        1. Local user/password set to ansible user `admin` with password `admin` 
        2. DNS servers
        3. NTP servers
        4. Multi-agent routing protocol model required for EVPN
        5. STP
        6. IP routing enabled
        7. Management settings such as interface name, gateway and OOB VRF
        8. SSL profile for eAPI

    === "DC1_FABRIC.yaml"

        ```yaml
        ---
        fabric_name: DC1_FABRIC # (1)!

        underlay_routing_protocol: ebgp # (2)!

        overlay_routing_protocol: ebgp

        evpn_vlan_aware_bundles: true # (3)!

        # bgp peer groups passwords
        bgp_peer_groups: # (4)!
          ipv4_underlay_peers:
            password: "AQQvKeimxJu+uGQ/yYvv9w=="
          evpn_overlay_peers:
              password: "q+VNViP5i4rVjW1cxFv2wA=="
          mlag_ipv4_underlay_peer:
              password: "vnEaG8gMeQf3d3cN6PktXQ=="

        # BGP defaults
        bgp_default_ipv4_unicast: false # (5)!
        bgp_update_wait_install: false
        bgp_update_wait_for_convergence: false
        bgp_distance:
          external_routes: 20
          internal_routes: 200
          local_routes: 200

        spine:
          defaults:
            platform: cEOS-LAB
            bgp_as: '65001'
            loopback_ipv4_pool: 192.168.255.0/24 # (6)!
          nodes: # (7)!
            - name: DC1_SPINE1
              id: 1 # (8)!
              mgmt_ip: 172.100.100.2/24
            - name: DC1_SPINE2
              id: 2
              mgmt_ip: 172.100.100.3/24

        l3leaf:
          defaults:
            platform: cEOS-LAB
            bgp_as: '65100'
            uplink_switches: # (9)!
              - DC1_SPINE1
              - DC1_SPINE2
            uplink_interfaces: # (10)!
              - Ethernet1
              - Ethernet2
            mlag_interfaces: # (11)!
              - Ethernet3
              - Ethernet4
            virtual_router_mac_address: 00:00:00:00:00:01 # (12)!
            spanning_tree_mode: mstp # (13)!
            spanning_tree_priority: 4096 # (14)!
            loopback_ipv4_pool: 192.168.255.0/24 # (15)!
            loopback_ipv4_offset: 2 # (16)!
            vtep_loopback_ipv4_pool: 192.168.254.0/24 # (17)!
            uplink_ipv4_pool: 172.31.255.0/24 # (18)!
            mlag_peer_ipv4_pool: 10.255.252.0/24 # (19)!
            mlag_peer_l3_ipv4_pool: 10.255.251.0/24 # (20)!
          node_groups: # (21)!
            - group: DC1_LEAF1
              bgp_as: '65101'
              filter:
                tenants:
                  - Tenant_A
                tags:
                  - opzone_pod1
              nodes:
                - name: DC1_LEAF1A
                  id: 1
                  mgmt_ip: 172.100.100.4/24
                  uplink_switch_interfaces: # (22)!
                    - Ethernet1
                    - Ethernet1
                - name: DC1_LEAF1B
                  id: 2
                  mgmt_ip: 172.100.100.5/24
                  uplink_switch_interfaces:
                    - Ethernet2
                    - Ethernet2
            - group: DC1_SVC2
              bgp_as: '65102'
              filter:
                tenants:
                  - Tenant_A
                tags:
                  - opzone_pod2
              nodes:
                - name: DC1_SVC2A
                  id: 3
                  mgmt_ip: 172.100.100.6/24
                  uplink_switch_interfaces:
                    - Ethernet3
                    - Ethernet3
                - name: DC1_SVC2B
                  id: 4
                  mgmt_ip: 172.100.100.7/24
                  uplink_switch_interfaces:
                    - Ethernet4
                    - Ethernet4

        l2leaf:
          defaults:
            platform: cEOS-LAB
            uplink_switches:
              - DC1_SVC2A
              - DC1_SVC2B
            uplink_interfaces:
              - Ethernet1
              - Ethernet2
            mlag_interfaces:
              - Ethernet3
              - Ethernet4
            spanning_tree_mode: mstp
            spanning_tree_priority: 16384
            mlag_peer_ipv4_pool: 10.255.252.0/24
            mlag_peer_l3_ipv4_pool: 10.255.251.0/24
          node_groups:
            - group: DC1_L2_LEAF
              nodes:
                - name: DC1_L2_LEAF2A
                  id: 5
                  mgmt_ip: 172.100.100.8/24
                  uplink_switch_interfaces:
                    - Ethernet5
                    - Ethernet5
                - name: DC1_L2_LEAF2B
                  id: 6
                  mgmt_ip: 172.100.100.9/24
                  uplink_switch_interfaces:
                    - Ethernet6
                    - Ethernet6
        ```

        1. The name of the fabric for internal AVD use. This name must match the name of an Ansible Group (and therefore a corresponding group_vars file) covering all network devices.
        2. Routing protocols to use in the underlay and overlay
        3. Use EVPN VLAN aware bundles
        4. Underlay and overlay BGP peer groups and their passwords
        5. BGP defaults
        6. `loopback_ipv4_pool` defines the IP scope from which AVD assigns IPv4 addresses for Loopback0.
        7. `nodes` defines the actual spine switches, using the hostnames defined in the inventory.
        8. `id` is used to calculate the various IP addresses, for example, the IPv4 address for the Loopback0 interface. In this case, `DC1_SPINE1` will get the IPv4 address 192.168.255.1 assigned to the Loopback0 interface.
        9. `uplink_switches` defines the uplink switches, which are `DC1_SPINE1` and `DC1_SPINE2`. Note that the `uplink_interfaces` and `uplink_switches` are paired vertically.
        10. `uplink_interfaces` is used by the `l3leaf` nodes to connect to the spine switches.
        11. `mlag_interfaces` defines the MLAG interfaces used on each leaf switch.
        12. `virtual_router_mac_address` defines the MAC address used for the anycast gateway on the various subnets. This is the MAC address connected endpoints will learn when ARPing for their default gateway.
        13. STP mode which is here set to MSTP, which is the default. We can set it to other available modes based on requirements.
        14. `spanning_tree_priority` sets the STP priority. Since STP in an L3LS network is effectively only running locally on the switch, the same priority across all L3 leaf switches can be re-used.
        15. `loopback_ipv4_pool` defines the IP scope from which AVD assigns IPv4 addresses for Loopback0. Please note that this IP pool is identical to the one used for the spine switches in this example. To avoid setting the same IP addresses for several devices, we define the option `loopback_ipv4_offset`.
        16. `loopback_ipv4_offset` offsets all assigned loopback IP addresses counting from the beginning of the IP scope. This is required to avoid overlapping IPs when the same IP pool is used for two different node_types (like `spine` and `l3leaf` in this example). The offset is “2” because each spine switch uses one loopback address.
        17. `vtep_loopback_ipv4_pool` defines the IP scope from which AVD assigns IPv4 addresses for the VTEP (Loopback1).
        18. `uplink_ipv4_pool` defines the IP scope from which AVD assigns IPv4 addresses for the uplink interfaces.
        19. `mlag_peer_ipv4_pool` defines the IP scope from which AVD assigns IPv4 addresses for the MLAG peer-link interface `VLAN4094`.
        20. `mlag_peer_l3_ipv4_pool` defines the IP scope from which AVD assigns IPv4 addresses for the iBGP peering established between the two leaf switches via the SVI/IRB interface `VLAN4093`.
        21. `node_groups` defines settings common to more than one node. For example, when exactly two nodes are part of a node group for leaf switches, AVD will, by default, automatically generate MLAG configuration.
        22. `uplink_switch_interfaces` defines the interfaces used on the uplink switches (Ethernet1 on DC1_SPINE1 and DC1_SPINE2 in this example).
        23. 
    
    === "DC1_NETWORK_SERVICES.yaml"

        ```yaml
        ---
        tenants: # (1)!
          # Tenant A VRFs / VLANs
          - name: Tenant_A
            mac_vrf_vni_base: 10000 # (2)!
            vrfs: # (3)!
              - name: Tenant_A_OP_Zone
                vrf_vni: 10 # (4)!
                vtep_diagnostic: # (5)!
                  loopback: 100
                  loopback_ip_range: 10.255.1.0/24
                svis: # (6)!
                  - id: 110
                    name: Tenant_A_OP_Zone_1
                    tags: # (8)!
                      - opzone_pod1
                    enabled: true
                    ip_address_virtual: 10.1.10.1/24 # (7)!
                  - id: 111
                    name: Tenant_A_OP_Zone_2
                    tags:
                      - opzone_pod1
                    enabled: true
                    ip_address_virtual: 10.1.11.1/24
                  - id: 112
                    name: Tenant_A_OP_Zone_3
                    tags:
                      - opzone_pod2
                    enabled: true
                    ip_address_virtual: 10.1.12.1/24
                  - id: 113
                    name: Tenant_A_OP_Zone_4
                    tags:
                      - opzone_pod2
                    enabled: true
                    ip_address_virtual: 10.1.13.1/24
        ```

        24. An additional level of abstraction in addition to VRFs. In this example, just one tenant named `Tenant_A` is specified.
        25. The base number (`10000`) is used to generate the L2VNI numbers automatically, `L2VNI = base number + VLAN-id`. For example, L2VNI for VLAN11 = 10000 + 11 = 10011.
        26. VRF definitions inside the tenant
        27. VRF VNI definition
        28. Enable VTEP Network diagnostics. This will create a loopback with virtual source-nat to enable to perform diagnostics from the switch
        29. SVI definitions for all SVIs in this tenant
        30. IP anycast gateway to be used in the SVI in every leaf across the fabric.
        31. Tags leveraged for network services filtering. Here `opzone_pod1` is applied to `DC1_LEAF1` node group and `opzone_pod2` is applied to `DC1_SVC2` node group.
    
    === "DC1_CONNECTED_ENDPOINTS.yaml"

        ```yaml
        ---
        port_profiles: # (1)!
          - profile: Tenant_A_pod1_clientA
            mode: trunk
            vlans: '110'
          - profile: Tenant_A_pod1_clientB
            mode: trunk
            vlans: '111'
          - profile: Tenant_A_pod2_clientA
            mode: trunk
            vlans: '112'
          - profile: Tenant_A_pod2_clientB
            mode: trunk
            vlans: '113'
        
        servers:
          - name: server01 # (3)!
            rack: rack01 # (2)!
            adapters:
              - endpoint_ports: # (4)!
                  - Eth1
                  - Eth2
                switch_ports: # (5)!
                  - Ethernet5
                  - Ethernet5
                switches: # (6)!
                  - DC1_LEAF1A
                  - DC1_LEAF1B
                profile: Tenant_A_pod1_clientA # (7)!
                spanning_tree_portfast: edge # (8)!
                port_channel: # (9)!
                  description: PortChannel5
                  mode: active
          - name: server02
            rack: rack01
            adapters:
              - endpoint_ports:
                  - Eth1
                  - Eth2
                switch_ports:
                  - Ethernet6
                  - Ethernet6
                switches:
                  - DC1_LEAF1A
                  - DC1_LEAF1B
                profile: Tenant_A_pod1_clientB
                spanning_tree_portfast: edge
                port_channel:
                  description: PortChannel6
                  mode: active
          - name: server03
            rack: rack02
            adapters:
              - endpoint_ports:
                  - Eth1
                  - Eth2
                switch_ports:
                  - Ethernet5
                  - Ethernet5
                switches:
                  - DC1_L2_LEAF2A
                  - DC1_L2_LEAF2B
                profile: Tenant_A_pod2_clientA
                spanning_tree_portfast: edge
                port_channel:
                  description: PortChannel5
                  mode: active
          - name: server04
            rack: rack02
            adapters:
              - endpoint_ports:
                  - Eth1
                  - Eth2
                switch_ports:
                  - Ethernet6
                  - Ethernet6
                switches:
                  - DC1_L2_LEAF2A
                  - DC1_L2_LEAF2B
                profile: Tenant_A_pod2_clientB
                spanning_tree_portfast: edge
                port_channel:
                  description: PortChannel6
                  mode: active
        ```

        32. Optional profiles to share common settings for `connected_endpoints` and/or network_ports.
        33. Rack is used for documentation purposes only.
        34. The endpoint name will be used in the switch port description.
        35. `endpoint_ports` are defined for use in the interface descriptions on the switch. This does not configure anything on the server.
        36. `switch_ports` defines the interfaces used in the switches. In this example, the server is dual-connected to Ethernet5 and Ethernet5. These two ports exist on switch DC1_LEAF1A and DC1_LEAF1B defined in the following line.
        37. `switches` defines the switches used, in this case DC1_LEAF1A and DC1_LEAF1B. Note that the `endpoint_ports`, `switch_ports` and `switches` definitions are paired vertically.
        38. `profile` applies the profile configuration defined earlier in `port_profiles`.
        39. `spanning_tree_portfast` defines whether the switch port should be a spanning tree edge or network port.
        40. `port_channel` defines the description and mode for the port-channel.
    
    === "DC1_L2_LEAFS.yaml"

        ```yaml
        ---
        type: l2leaf
        ```
    
    === "DC1_L3_LEAFS.yaml"

        ```yaml
        ---
        type: l3leaf
        ```
    
    === "DC1_SPINES.yaml"

        ```yaml
        ---
        type: spine
        ```

## Deploying the lab

* Using `containerlab deploy` command we will deploy the cEOS-lab containers.

```bash
sudo containerlab deploy -t topology.yaml
```

* Within a few moments, a summary of the deployed nodes will become visible

??? note "Reveal Output"

    ```bash
    +----+----------------------+--------------+-------------------+-------+---------+-------------------+------------------------+
    | #  |         Name         | Container ID |       Image       | Kind  |  State  |   IPv4 Address    |      IPv6 Address      |
    +----+----------------------+--------------+-------------------+-------+---------+-------------------+------------------------+
    |  1 | clab-avdirb-client1  | 4d58d9fa2b7f | alpine-host       | linux | running | 172.100.100.10/24 | 2001:172:100:100::6/80 |
    |  2 | clab-avdirb-client2  | 8ab20c4d5bf8 | alpine-host       | linux | running | 172.100.100.11/24 | 2001:172:100:100::c/80 |
    |  3 | clab-avdirb-client3  | a26e8eecb6a4 | alpine-host       | linux | running | 172.100.100.12/24 | 2001:172:100:100::d/80 |
    |  4 | clab-avdirb-client4  | 384c133d3529 | alpine-host       | linux | running | 172.100.100.13/24 | 2001:172:100:100::a/80 |
    |  5 | clab-avdirb-l2leaf2a | 1f8572980b65 | ceosimage:4.30.1F | ceos  | running | 172.100.100.8/24  | 2001:172:100:100::3/80 |
    |  6 | clab-avdirb-l2leaf2b | b0451a085cea | ceosimage:4.30.1F | ceos  | running | 172.100.100.9/24  | 2001:172:100:100::8/80 |
    |  7 | clab-avdirb-leaf1a   | 7cfa319eddbb | ceosimage:4.30.1F | ceos  | running | 172.100.100.4/24  | 2001:172:100:100::4/80 |
    |  8 | clab-avdirb-leaf1b   | 0166c63d984f | ceosimage:4.30.1F | ceos  | running | 172.100.100.5/24  | 2001:172:100:100::9/80 |
    |  9 | clab-avdirb-spine1   | 72729fe862d6 | ceosimage:4.30.1F | ceos  | running | 172.100.100.2/24  | 2001:172:100:100::7/80 |
    | 10 | clab-avdirb-spine2   | dbbc44639d2b | ceosimage:4.30.1F | ceos  | running | 172.100.100.3/24  | 2001:172:100:100::2/80 |
    | 11 | clab-avdirb-svc2a    | b9874dbbdb33 | ceosimage:4.30.1F | ceos  | running | 172.100.100.6/24  | 2001:172:100:100::b/80 |
    | 12 | clab-avdirb-svc2b    | 9677f445be09 | ceosimage:4.30.1F | ceos  | running | 172.100.100.7/24  | 2001:172:100:100::5/80 |
    +----+----------------------+--------------+-------------------+-------+---------+-------------------+------------------------+
    ```

!!! tip

    The above lab summary can also be viewed using the following command

    ```bash
    sudo containerlab inspect -t topology.yaml
    ```

* Login to the cEOS-lab switch, observe it has been configured with a baseline configuration using the template file `avd-cEOS-Lab/ceos_lab_template/ceos.cfg.tpl`

=== "SSH"

    ```bash
    ssh admin@172.100.100.2
    ```

=== "docker exec"

    ```bash
    docker exec -it clab-avdirb-spine1 Cli
    ```

??? note "Reveal Output"

    ```bash hl_lines="5 27 33 35"
    $ ssh admin@172.100.100.2
    Password:
    Last login: Tue Dec  5 05:46:50 2023 from 172.100.100.1
    spine1>
    spine1>show version
    Arista cEOSLab
    Hardware version:
    Serial number: 62A5E80889120C7C6E3742392A42D0BF
    Hardware MAC address: 001c.735c.a7f6
    System MAC address: 001c.735c.a7f6

    Software image version: 4.30.1F-32308478.4301F (engineering build)
    Architecture: x86_64
    Internal build version: 4.30.1F-32308478.4301F
    Internal build ID: 43258559-02df-4fe8-9912-d332778f86da
    Image format version: 1.0
    Image optimization: None

    cEOS tools version: (unknown)
    Kernel version: 3.10.0-1160.11.1.el7.x86_64

    Uptime: 7 minutes
    Total memory: 32397092 kB
    Free memory: 18339616 kB

    spine1>
    spine1>show lldp neighbors | include Et
    Et1           leaf1a                   Ethernet1           120
    Et2           leaf1b                   Ethernet1           120
    Et3           svc2a                    Ethernet1           120
    Et4           svc2b                    Ethernet1           120
    spine1>
    spine1>enable
    spine1#
    spine1#show running-config | no-more
    ! Command: show running-config
    ! device: spine1 (cEOSLab, EOS-4.30.1F-32308478.4301F (engineering build))
    !
    no aaa root
    !
    username admin privilege 15 role network-admin secret sha512 $6$YK6LeKfDw8AMfeWp$uFpXW6TJDrub346aAowxilc6UXvEQnXWrEbA.gLfe33Dp0rwZzWC/3I1AidW8kaxg.rPmJo7GnwsZWXsfliCW0
    !
    transceiver qsfp default-mode 4x10G
    !
    service routing protocols model multi-agent
    !
    hostname spine1
    !
    spanning-tree mode mstp
    !
    system l1
       unsupported speed action error
       unsupported error-correction action error
    !
    vrf instance MGMT
    !
    management api http-commands
       protocol https ssl profile eAPI
       no shutdown
       !
       vrf MGMT
          no shutdown
    !
    management security
       ssl profile eAPI
          cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
          certificate eAPI.crt key eAPI.key
    !
    interface Ethernet1
    !
    interface Ethernet2
    !
    interface Ethernet3
    !
    interface Ethernet4
    !
    interface Management0
       description oob_management
       vrf MGMT
       ip address 172.100.100.2/24
       ipv6 address 2001:172:100:100::3/80
    !
    no ip routing
    no ip routing vrf MGMT
    !
    ip route vrf MGMT 0.0.0.0/0 172.100.100.1
    !
    ipv6 route vrf MGMT ::/0 2001:172:100:100::1
    !
    ```

## Deploying the configuration

* To build and deploy the configuration to the switches using eAPI, run the playbook `playbooks/fabric-deploy-config.yaml`

```bash
ansible-playbook playbooks/fabric-deploy-config.yaml
```

* Once the playbook run is completed, based on the first task which uses `arista.avd.eos_snapshot` we can see the snapshots under the `snapshots` folder.

??? note "Reveal Output"

    === "snapshots/"

        ```bash
        snapshots/
        ├── DC1_L2_LEAF2A
        │   ├── report.md
        │   ├── show\ interfaces\ description.txt
        │   ├── show\ ip\ interface\ brief.txt
        │   ├── show\ lldp\ neighbors.txt
        │   ├── show\ running-config.txt
        │   └── show\ version.txt
        ├── DC1_L2_LEAF2B
        │   ├── report.md
        │   ├── show\ interfaces\ description.txt
        │   ├── show\ ip\ interface\ brief.txt
        │   ├── show\ lldp\ neighbors.txt
        │   ├── show\ running-config.txt
        │   └── show\ version.txt
        ├── DC1_LEAF1A
        │   ├── report.md
        │   ├── show\ interfaces\ description.txt
        │   ├── show\ ip\ interface\ brief.txt
        │   ├── show\ lldp\ neighbors.txt
        │   ├── show\ running-config.txt
        │   └── show\ version.txt
        ├── DC1_LEAF1B
        │   ├── report.md
        │   ├── show\ interfaces\ description.txt
        │   ├── show\ ip\ interface\ brief.txt
        │   ├── show\ lldp\ neighbors.txt
        │   ├── show\ running-config.txt
        │   └── show\ version.txt
        ├── DC1_SPINE1
        │   ├── report.md
        │   ├── show\ interfaces\ description.txt
        │   ├── show\ ip\ interface\ brief.txt
        │   ├── show\ lldp\ neighbors.txt
        │   ├── show\ running-config.txt
        │   └── show\ version.txt
        ├── DC1_SPINE2
        │   ├── report.md
        │   ├── show\ interfaces\ description.txt
        │   ├── show\ ip\ interface\ brief.txt
        │   ├── show\ lldp\ neighbors.txt
        │   ├── show\ running-config.txt
        │   └── show\ version.txt
        ├── DC1_SVC2A
        │   ├── report.md
        │   ├── show\ interfaces\ description.txt
        │   ├── show\ ip\ interface\ brief.txt
        │   ├── show\ lldp\ neighbors.txt
        │   ├── show\ running-config.txt
        │   └── show\ version.txt
        └── DC1_SVC2B
            ├── report.md
            ├── show\ interfaces\ description.txt
            ├── show\ ip\ interface\ brief.txt
            ├── show\ lldp\ neighbors.txt
            ├── show\ running-config.txt
            └── show\ version.txt
        ```

* From the second task in the playbook which uses `arista.avd.eos_designs` we can see the structured YAML configuration per node is generated under `intended/structured_configs` directory.

??? note "Reveal Output"

    === "DC1_SPINE1.yml"

        ```yaml
        hostname: DC1_SPINE1
        router_bgp:
          as: '65001'
          router_id: 192.168.255.1
          distance:
            external_routes: 20
            internal_routes: 200
            local_routes: 200
          bgp:
            default:
              ipv4_unicast: false
          maximum_paths:
            paths: 4
            ecmp: 4
          peer_groups:
          - name: IPv4-UNDERLAY-PEERS
            type: ipv4
            password: AQQvKeimxJu+uGQ/yYvv9w==
            maximum_routes: 12000
            send_community: all
          - name: EVPN-OVERLAY-PEERS
            type: evpn
            update_source: Loopback0
            bfd: true
            password: q+VNViP5i4rVjW1cxFv2wA==
            send_community: all
            maximum_routes: 0
            ebgp_multihop: 3
            next_hop_unchanged: true
          address_family_ipv4:
            peer_groups:
            - name: IPv4-UNDERLAY-PEERS
              activate: true
            - name: EVPN-OVERLAY-PEERS
              activate: false
          redistribute_routes:
          - source_protocol: connected
            route_map: RM-CONN-2-BGP
          neighbors:
          - ip_address: 172.31.255.1
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65101'
            description: DC1_LEAF1A_Ethernet1
          - ip_address: 172.31.255.5
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65101'
            description: DC1_LEAF1B_Ethernet1
          - ip_address: 172.31.255.9
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65102'
            description: DC1_SVC2A_Ethernet1
          - ip_address: 172.31.255.13
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65102'
            description: DC1_SVC2B_Ethernet1
          - ip_address: 192.168.255.3
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_LEAF1A
            remote_as: '65101'
          - ip_address: 192.168.255.4
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_LEAF1B
            remote_as: '65101'
          - ip_address: 192.168.255.5
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SVC2A
            remote_as: '65102'
          - ip_address: 192.168.255.6
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SVC2B
            remote_as: '65102'
          address_family_evpn:
            peer_groups:
            - name: EVPN-OVERLAY-PEERS
              activate: true
        static_routes:
        - vrf: MGMT
          destination_address_prefix: 0.0.0.0/0
          gateway: 172.100.100.1
        service_routing_protocols_model: multi-agent
        ip_routing: true
        vlan_internal_order:
          allocation: ascending
          range:
            beginning: 1006
            ending: 1199
        ip_name_servers:
        - ip_address: 1.1.1.1
          vrf: MGMT
        - ip_address: 8.8.8.8
          vrf: MGMT
        spanning_tree:
          mode: mstp
        local_users:
        - name: admin
          privilege: 15
          role: network-admin
          sha512_password: $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        vrfs:
        - name: MGMT
          ip_routing: false
        management_interfaces:
        - name: Management0
          description: oob_management
          shutdown: false
          vrf: MGMT
          ip_address: 172.100.100.2/24
          gateway: 172.100.100.1
          type: oob
        management_api_http:
          enable_vrfs:
          - name: MGMT
          enable_https: true
          https_ssl_profile: eAPI
        ethernet_interfaces:
        - name: Ethernet1
          peer: DC1_LEAF1A
          peer_interface: Ethernet1
          peer_type: l3leaf
          description: P2P_LINK_TO_DC1_LEAF1A_Ethernet1
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.0/31
        - name: Ethernet2
          peer: DC1_LEAF1B
          peer_interface: Ethernet1
          peer_type: l3leaf
          description: P2P_LINK_TO_DC1_LEAF1B_Ethernet1
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.4/31
        - name: Ethernet3
          peer: DC1_SVC2A
          peer_interface: Ethernet1
          peer_type: l3leaf
          description: P2P_LINK_TO_DC1_SVC2A_Ethernet1
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.8/31
        - name: Ethernet4
          peer: DC1_SVC2B
          peer_interface: Ethernet1
          peer_type: l3leaf
          description: P2P_LINK_TO_DC1_SVC2B_Ethernet1
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.12/31
        loopback_interfaces:
        - name: Loopback0
          description: EVPN_Overlay_Peering
          shutdown: false
          ip_address: 192.168.255.1/32
        prefix_lists:
        - name: PL-LOOPBACKS-EVPN-OVERLAY
          sequence_numbers:
          - sequence: 10
            action: permit 192.168.255.0/24 eq 32
        route_maps:
        - name: RM-CONN-2-BGP
          sequence_numbers:
          - sequence: 10
            type: permit
            match:
            - ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        router_bfd:
          multihop:
            interval: 300
            min_rx: 300
            multiplier: 3
        management_security:
          ssl_profiles:
          - name: eAPI
            certificate:
              file: eAPI.crt
              key: eAPI.key
            cipher_list: HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
        ```

    === "DC1_SPINE2.yml"

        ```yaml
        hostname: DC1_SPINE2
        router_bgp:
          as: '65001'
          router_id: 192.168.255.2
          distance:
            external_routes: 20
            internal_routes: 200
            local_routes: 200
          bgp:
            default:
              ipv4_unicast: false
          maximum_paths:
            paths: 4
            ecmp: 4
          peer_groups:
          - name: IPv4-UNDERLAY-PEERS
            type: ipv4
            password: AQQvKeimxJu+uGQ/yYvv9w==
            maximum_routes: 12000
            send_community: all
          - name: EVPN-OVERLAY-PEERS
            type: evpn
            update_source: Loopback0
            bfd: true
            password: q+VNViP5i4rVjW1cxFv2wA==
            send_community: all
            maximum_routes: 0
            ebgp_multihop: 3
            next_hop_unchanged: true
          address_family_ipv4:
            peer_groups:
            - name: IPv4-UNDERLAY-PEERS
              activate: true
            - name: EVPN-OVERLAY-PEERS
              activate: false
          redistribute_routes:
          - source_protocol: connected
            route_map: RM-CONN-2-BGP
          neighbors:
          - ip_address: 172.31.255.3
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65101'
            description: DC1_LEAF1A_Ethernet2
          - ip_address: 172.31.255.7
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65101'
            description: DC1_LEAF1B_Ethernet2
          - ip_address: 172.31.255.11
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65102'
            description: DC1_SVC2A_Ethernet2
          - ip_address: 172.31.255.15
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65102'
            description: DC1_SVC2B_Ethernet2
          - ip_address: 192.168.255.3
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_LEAF1A
            remote_as: '65101'
          - ip_address: 192.168.255.4
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_LEAF1B
            remote_as: '65101'
          - ip_address: 192.168.255.5
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SVC2A
            remote_as: '65102'
          - ip_address: 192.168.255.6
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SVC2B
            remote_as: '65102'
          address_family_evpn:
            peer_groups:
            - name: EVPN-OVERLAY-PEERS
              activate: true
        static_routes:
        - vrf: MGMT
          destination_address_prefix: 0.0.0.0/0
          gateway: 172.100.100.1
        service_routing_protocols_model: multi-agent
        ip_routing: true
        vlan_internal_order:
          allocation: ascending
          range:
            beginning: 1006
            ending: 1199
        ip_name_servers:
        - ip_address: 1.1.1.1
          vrf: MGMT
        - ip_address: 8.8.8.8
          vrf: MGMT
        spanning_tree:
          mode: mstp
        local_users:
        - name: admin
          privilege: 15
          role: network-admin
          sha512_password: $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        vrfs:
        - name: MGMT
          ip_routing: false
        management_interfaces:
        - name: Management0
          description: oob_management
          shutdown: false
          vrf: MGMT
          ip_address: 172.100.100.3/24
          gateway: 172.100.100.1
          type: oob
        management_api_http:
          enable_vrfs:
          - name: MGMT
          enable_https: true
          https_ssl_profile: eAPI
        ethernet_interfaces:
        - name: Ethernet1
          peer: DC1_LEAF1A
          peer_interface: Ethernet2
          peer_type: l3leaf
          description: P2P_LINK_TO_DC1_LEAF1A_Ethernet2
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.2/31
        - name: Ethernet2
          peer: DC1_LEAF1B
          peer_interface: Ethernet2
          peer_type: l3leaf
          description: P2P_LINK_TO_DC1_LEAF1B_Ethernet2
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.6/31
        - name: Ethernet3
          peer: DC1_SVC2A
          peer_interface: Ethernet2
          peer_type: l3leaf
          description: P2P_LINK_TO_DC1_SVC2A_Ethernet2
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.10/31
        - name: Ethernet4
          peer: DC1_SVC2B
          peer_interface: Ethernet2
          peer_type: l3leaf
          description: P2P_LINK_TO_DC1_SVC2B_Ethernet2
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.14/31
        loopback_interfaces:
        - name: Loopback0
          description: EVPN_Overlay_Peering
          shutdown: false
          ip_address: 192.168.255.2/32
        prefix_lists:
        - name: PL-LOOPBACKS-EVPN-OVERLAY
          sequence_numbers:
          - sequence: 10
            action: permit 192.168.255.0/24 eq 32
        route_maps:
        - name: RM-CONN-2-BGP
          sequence_numbers:
          - sequence: 10
            type: permit
            match:
            - ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        router_bfd:
          multihop:
            interval: 300
            min_rx: 300
            multiplier: 3
        management_security:
          ssl_profiles:
          - name: eAPI
            certificate:
              file: eAPI.crt
              key: eAPI.key
            cipher_list: HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
        ```

    === "DC1_LEAF1A.yml"

        ```yaml
        hostname: DC1_LEAF1A
        router_bgp:
          as: '65101'
          router_id: 192.168.255.3
          distance:
            external_routes: 20
            internal_routes: 200
            local_routes: 200
          bgp:
            default:
              ipv4_unicast: false
          maximum_paths:
            paths: 4
            ecmp: 4
          peer_groups:
          - name: MLAG-IPv4-UNDERLAY-PEER
            type: ipv4
            remote_as: '65101'
            next_hop_self: true
            description: DC1_LEAF1B
            password: vnEaG8gMeQf3d3cN6PktXQ==
            maximum_routes: 12000
            send_community: all
            route_map_in: RM-MLAG-PEER-IN
          - name: IPv4-UNDERLAY-PEERS
            type: ipv4
            password: AQQvKeimxJu+uGQ/yYvv9w==
            maximum_routes: 12000
            send_community: all
          - name: EVPN-OVERLAY-PEERS
            type: evpn
            update_source: Loopback0
            bfd: true
            password: q+VNViP5i4rVjW1cxFv2wA==
            send_community: all
            maximum_routes: 0
            ebgp_multihop: 3
          address_family_ipv4:
            peer_groups:
            - name: MLAG-IPv4-UNDERLAY-PEER
              activate: true
            - name: IPv4-UNDERLAY-PEERS
              activate: true
            - name: EVPN-OVERLAY-PEERS
              activate: false
          neighbors:
          - ip_address: 10.255.251.1
            peer_group: MLAG-IPv4-UNDERLAY-PEER
            description: DC1_LEAF1B
          - ip_address: 172.31.255.0
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65001'
            description: DC1_SPINE1_Ethernet1
          - ip_address: 172.31.255.2
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65001'
            description: DC1_SPINE2_Ethernet1
          - ip_address: 192.168.255.1
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SPINE1
            remote_as: '65001'
          - ip_address: 192.168.255.2
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SPINE2
            remote_as: '65001'
          redistribute_routes:
          - source_protocol: connected
            route_map: RM-CONN-2-BGP
          address_family_evpn:
            peer_groups:
            - name: EVPN-OVERLAY-PEERS
              activate: true
          vrfs:
          - name: Tenant_A_OP_Zone
            router_id: 192.168.255.3
            rd: 192.168.255.3:10
            route_targets:
              import:
              - address_family: evpn
                route_targets:
                - '10:10'
              export:
              - address_family: evpn
                route_targets:
                - '10:10'
            redistribute_routes:
            - source_protocol: connected
            neighbors:
            - ip_address: 10.255.251.1
              peer_group: MLAG-IPv4-UNDERLAY-PEER
          vlan_aware_bundles:
          - name: Tenant_A_OP_Zone
            rd: 192.168.255.3:10
            route_targets:
              both:
              - '10:10'
            redistribute_routes:
            - learned
            vlan: 110-111
        static_routes:
        - vrf: MGMT
          destination_address_prefix: 0.0.0.0/0
          gateway: 172.100.100.1
        service_routing_protocols_model: multi-agent
        ip_routing: true
        vlan_internal_order:
          allocation: ascending
          range:
            beginning: 1006
            ending: 1199
        ip_name_servers:
        - ip_address: 1.1.1.1
          vrf: MGMT
        - ip_address: 8.8.8.8
          vrf: MGMT
        spanning_tree:
          mode: mstp
          mst_instances:
          - id: '0'
            priority: 4096
          no_spanning_tree_vlan: 4093-4094
        local_users:
        - name: admin
          privilege: 15
          role: network-admin
          sha512_password: $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        vrfs:
        - name: MGMT
          ip_routing: false
        - name: Tenant_A_OP_Zone
          tenant: Tenant_A
          ip_routing: true
        management_interfaces:
        - name: Management0
          description: oob_management
          shutdown: false
          vrf: MGMT
          ip_address: 172.100.100.4/24
          gateway: 172.100.100.1
          type: oob
        management_api_http:
          enable_vrfs:
          - name: MGMT
          enable_https: true
          https_ssl_profile: eAPI
        vlans:
        - id: 4093
          tenant: system
          name: LEAF_PEER_L3
          trunk_groups:
          - LEAF_PEER_L3
        - id: 4094
          tenant: system
          name: MLAG_PEER
          trunk_groups:
          - MLAG
        - id: 110
          name: Tenant_A_OP_Zone_1
          tenant: Tenant_A
        - id: 111
          name: Tenant_A_OP_Zone_2
          tenant: Tenant_A
        - id: 3009
          name: MLAG_iBGP_Tenant_A_OP_Zone
          trunk_groups:
          - LEAF_PEER_L3
          tenant: Tenant_A
        vlan_interfaces:
        - name: Vlan4093
          description: MLAG_PEER_L3_PEERING
          shutdown: false
          mtu: 9214
          ip_address: 10.255.251.0/31
        - name: Vlan4094
          description: MLAG_PEER
          shutdown: false
          ip_address: 10.255.252.0/31
          no_autostate: true
          mtu: 9214
        - name: Vlan110
          tenant: Tenant_A
          tags:
          - opzone_pod1
          description: Tenant_A_OP_Zone_1
          shutdown: false
          ip_address_virtual: 10.1.10.1/24
          vrf: Tenant_A_OP_Zone
        - name: Vlan111
          tenant: Tenant_A
          tags:
          - opzone_pod1
          description: Tenant_A_OP_Zone_2
          shutdown: false
          ip_address_virtual: 10.1.11.1/24
          vrf: Tenant_A_OP_Zone
        - name: Vlan3009
          tenant: Tenant_A
          type: underlay_peering
          shutdown: false
          description: 'MLAG_PEER_L3_iBGP: vrf Tenant_A_OP_Zone'
          vrf: Tenant_A_OP_Zone
          mtu: 9214
          ip_address: 10.255.251.0/31
        port_channel_interfaces:
        - name: Port-Channel3
          description: MLAG_PEER_DC1_LEAF1B_Po3
          type: switched
          shutdown: false
          mode: trunk
          trunk_groups:
          - LEAF_PEER_L3
          - MLAG
        - name: Port-Channel5
          description: server01_PortChannel5
          type: switched
          shutdown: false
          mode: trunk
          vlans: '110'
          spanning_tree_portfast: edge
          mlag: 5
        - name: Port-Channel6
          description: server02_PortChannel6
          type: switched
          shutdown: false
          mode: trunk
          vlans: '111'
          spanning_tree_portfast: edge
          mlag: 6
        ethernet_interfaces:
        - name: Ethernet3
          peer: DC1_LEAF1B
          peer_interface: Ethernet3
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_LEAF1B_Ethernet3
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet4
          peer: DC1_LEAF1B
          peer_interface: Ethernet4
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_LEAF1B_Ethernet4
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet1
          peer: DC1_SPINE1
          peer_interface: Ethernet1
          peer_type: spine
          description: P2P_LINK_TO_DC1_SPINE1_Ethernet1
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.1/31
        - name: Ethernet2
          peer: DC1_SPINE2
          peer_interface: Ethernet1
          peer_type: spine
          description: P2P_LINK_TO_DC1_SPINE2_Ethernet1
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.3/31
        - name: Ethernet5
          peer: server01
          peer_interface: Eth1
          peer_type: server
          port_profile: Tenant_A_pod1_clientA
          description: server01_Eth1
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 5
            mode: active
        - name: Ethernet6
          peer: server02
          peer_interface: Eth1
          peer_type: server
          port_profile: Tenant_A_pod1_clientB
          description: server02_Eth1
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 6
            mode: active
        mlag_configuration:
          domain_id: DC1_LEAF1
          local_interface: Vlan4094
          peer_address: 10.255.252.1
          peer_link: Port-Channel3
          reload_delay_mlag: '300'
          reload_delay_non_mlag: '330'
        route_maps:
        - name: RM-MLAG-PEER-IN
          sequence_numbers:
          - sequence: 10
            type: permit
            set:
            - origin incomplete
            description: Make routes learned over MLAG Peer-link less preferred on spines to ensure optimal routing
        - name: RM-CONN-2-BGP
          sequence_numbers:
          - sequence: 10
            type: permit
            match:
            - ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        loopback_interfaces:
        - name: Loopback0
          description: EVPN_Overlay_Peering
          shutdown: false
          ip_address: 192.168.255.3/32
        - name: Loopback1
          description: VTEP_VXLAN_Tunnel_Source
          shutdown: false
          ip_address: 192.168.254.3/32
        - name: Loopback100
          description: Tenant_A_OP_Zone_VTEP_DIAGNOSTICS
          shutdown: false
          vrf: Tenant_A_OP_Zone
          ip_address: 10.255.1.3/32
        prefix_lists:
        - name: PL-LOOPBACKS-EVPN-OVERLAY
          sequence_numbers:
          - sequence: 10
            action: permit 192.168.255.0/24 eq 32
          - sequence: 20
            action: permit 192.168.254.0/24 eq 32
        router_bfd:
          multihop:
            interval: 300
            min_rx: 300
            multiplier: 3
        ip_igmp_snooping:
          globally_enabled: true
        ip_virtual_router_mac_address: 00:00:00:00:00:01
        vxlan_interface:
          Vxlan1:
            description: DC1_LEAF1A_VTEP
            vxlan:
              udp_port: 4789
              source_interface: Loopback1
              virtual_router_encapsulation_mac_address: mlag-system-id
              vlans:
              - id: 110
                vni: 10110
              - id: 111
                vni: 10111
              vrfs:
              - name: Tenant_A_OP_Zone
                vni: 10
        virtual_source_nat_vrfs:
        - name: Tenant_A_OP_Zone
          ip_address: 10.255.1.3
        management_security:
          ssl_profiles:
          - name: eAPI
            certificate:
              file: eAPI.crt
              key: eAPI.key
            cipher_list: HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
        ```
    
    === "DC1_LEAF1B.yml"

        ```yaml
        hostname: DC1_LEAF1B
        router_bgp:
          as: '65101'
          router_id: 192.168.255.4
          distance:
            external_routes: 20
            internal_routes: 200
            local_routes: 200
          bgp:
            default:
              ipv4_unicast: false
          maximum_paths:
            paths: 4
            ecmp: 4
          peer_groups:
          - name: MLAG-IPv4-UNDERLAY-PEER
            type: ipv4
            remote_as: '65101'
            next_hop_self: true
            description: DC1_LEAF1A
            password: vnEaG8gMeQf3d3cN6PktXQ==
            maximum_routes: 12000
            send_community: all
            route_map_in: RM-MLAG-PEER-IN
          - name: IPv4-UNDERLAY-PEERS
            type: ipv4
            password: AQQvKeimxJu+uGQ/yYvv9w==
            maximum_routes: 12000
            send_community: all
          - name: EVPN-OVERLAY-PEERS
            type: evpn
            update_source: Loopback0
            bfd: true
            password: q+VNViP5i4rVjW1cxFv2wA==
            send_community: all
            maximum_routes: 0
            ebgp_multihop: 3
          address_family_ipv4:
            peer_groups:
            - name: MLAG-IPv4-UNDERLAY-PEER
              activate: true
            - name: IPv4-UNDERLAY-PEERS
              activate: true
            - name: EVPN-OVERLAY-PEERS
              activate: false
          neighbors:
          - ip_address: 10.255.251.0
            peer_group: MLAG-IPv4-UNDERLAY-PEER
            description: DC1_LEAF1A
          - ip_address: 172.31.255.4
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65001'
            description: DC1_SPINE1_Ethernet2
          - ip_address: 172.31.255.6
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65001'
            description: DC1_SPINE2_Ethernet2
          - ip_address: 192.168.255.1
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SPINE1
            remote_as: '65001'
          - ip_address: 192.168.255.2
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SPINE2
            remote_as: '65001'
          redistribute_routes:
          - source_protocol: connected
            route_map: RM-CONN-2-BGP
          address_family_evpn:
            peer_groups:
            - name: EVPN-OVERLAY-PEERS
              activate: true
          vrfs:
          - name: Tenant_A_OP_Zone
            router_id: 192.168.255.4
            rd: 192.168.255.4:10
            route_targets:
              import:
              - address_family: evpn
                route_targets:
                - '10:10'
              export:
              - address_family: evpn
                route_targets:
                - '10:10'
            redistribute_routes:
            - source_protocol: connected
            neighbors:
            - ip_address: 10.255.251.0
              peer_group: MLAG-IPv4-UNDERLAY-PEER
          vlan_aware_bundles:
          - name: Tenant_A_OP_Zone
            rd: 192.168.255.4:10
            route_targets:
              both:
              - '10:10'
            redistribute_routes:
            - learned
            vlan: 110-111
        static_routes:
        - vrf: MGMT
          destination_address_prefix: 0.0.0.0/0
          gateway: 172.100.100.1
        service_routing_protocols_model: multi-agent
        ip_routing: true
        vlan_internal_order:
          allocation: ascending
          range:
            beginning: 1006
            ending: 1199
        ip_name_servers:
        - ip_address: 1.1.1.1
          vrf: MGMT
        - ip_address: 8.8.8.8
          vrf: MGMT
        spanning_tree:
          mode: mstp
          mst_instances:
          - id: '0'
            priority: 4096
          no_spanning_tree_vlan: 4093-4094
        local_users:
        - name: admin
          privilege: 15
          role: network-admin
          sha512_password: $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        vrfs:
        - name: MGMT
          ip_routing: false
        - name: Tenant_A_OP_Zone
          tenant: Tenant_A
          ip_routing: true
        management_interfaces:
        - name: Management0
          description: oob_management
          shutdown: false
          vrf: MGMT
          ip_address: 172.100.100.5/24
          gateway: 172.100.100.1
          type: oob
        management_api_http:
          enable_vrfs:
          - name: MGMT
          enable_https: true
          https_ssl_profile: eAPI
        vlans:
        - id: 4093
          tenant: system
          name: LEAF_PEER_L3
          trunk_groups:
          - LEAF_PEER_L3
        - id: 4094
          tenant: system
          name: MLAG_PEER
          trunk_groups:
          - MLAG
        - id: 110
          name: Tenant_A_OP_Zone_1
          tenant: Tenant_A
        - id: 111
          name: Tenant_A_OP_Zone_2
          tenant: Tenant_A
        - id: 3009
          name: MLAG_iBGP_Tenant_A_OP_Zone
          trunk_groups:
          - LEAF_PEER_L3
          tenant: Tenant_A
        vlan_interfaces:
        - name: Vlan4093
          description: MLAG_PEER_L3_PEERING
          shutdown: false
          mtu: 9214
          ip_address: 10.255.251.1/31
        - name: Vlan4094
          description: MLAG_PEER
          shutdown: false
          ip_address: 10.255.252.1/31
          no_autostate: true
          mtu: 9214
        - name: Vlan110
          tenant: Tenant_A
          tags:
          - opzone_pod1
          description: Tenant_A_OP_Zone_1
          shutdown: false
          ip_address_virtual: 10.1.10.1/24
          vrf: Tenant_A_OP_Zone
        - name: Vlan111
          tenant: Tenant_A
          tags:
          - opzone_pod1
          description: Tenant_A_OP_Zone_2
          shutdown: false
          ip_address_virtual: 10.1.11.1/24
          vrf: Tenant_A_OP_Zone
        - name: Vlan3009
          tenant: Tenant_A
          type: underlay_peering
          shutdown: false
          description: 'MLAG_PEER_L3_iBGP: vrf Tenant_A_OP_Zone'
          vrf: Tenant_A_OP_Zone
          mtu: 9214
          ip_address: 10.255.251.1/31
        port_channel_interfaces:
        - name: Port-Channel3
          description: MLAG_PEER_DC1_LEAF1A_Po3
          type: switched
          shutdown: false
          mode: trunk
          trunk_groups:
          - LEAF_PEER_L3
          - MLAG
        - name: Port-Channel5
          description: server01_PortChannel5
          type: switched
          shutdown: false
          mode: trunk
          vlans: '110'
          spanning_tree_portfast: edge
          mlag: 5
        - name: Port-Channel6
          description: server02_PortChannel6
          type: switched
          shutdown: false
          mode: trunk
          vlans: '111'
          spanning_tree_portfast: edge
          mlag: 6
        ethernet_interfaces:
        - name: Ethernet3
          peer: DC1_LEAF1A
          peer_interface: Ethernet3
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_LEAF1A_Ethernet3
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet4
          peer: DC1_LEAF1A
          peer_interface: Ethernet4
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_LEAF1A_Ethernet4
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet1
          peer: DC1_SPINE1
          peer_interface: Ethernet2
          peer_type: spine
          description: P2P_LINK_TO_DC1_SPINE1_Ethernet2
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.5/31
        - name: Ethernet2
          peer: DC1_SPINE2
          peer_interface: Ethernet2
          peer_type: spine
          description: P2P_LINK_TO_DC1_SPINE2_Ethernet2
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.7/31
        - name: Ethernet5
          peer: server01
          peer_interface: Eth2
          peer_type: server
          port_profile: Tenant_A_pod1_clientA
          description: server01_Eth2
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 5
            mode: active
        - name: Ethernet6
          peer: server02
          peer_interface: Eth2
          peer_type: server
          port_profile: Tenant_A_pod1_clientB
          description: server02_Eth2
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 6
            mode: active
        mlag_configuration:
          domain_id: DC1_LEAF1
          local_interface: Vlan4094
          peer_address: 10.255.252.0
          peer_link: Port-Channel3
          reload_delay_mlag: '300'
          reload_delay_non_mlag: '330'
        route_maps:
        - name: RM-MLAG-PEER-IN
          sequence_numbers:
          - sequence: 10
            type: permit
            set:
            - origin incomplete
            description: Make routes learned over MLAG Peer-link less preferred on spines to ensure optimal routing
        - name: RM-CONN-2-BGP
          sequence_numbers:
          - sequence: 10
            type: permit
            match:
            - ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        loopback_interfaces:
        - name: Loopback0
          description: EVPN_Overlay_Peering
          shutdown: false
          ip_address: 192.168.255.4/32
        - name: Loopback1
          description: VTEP_VXLAN_Tunnel_Source
          shutdown: false
          ip_address: 192.168.254.3/32
        - name: Loopback100
          description: Tenant_A_OP_Zone_VTEP_DIAGNOSTICS
          shutdown: false
          vrf: Tenant_A_OP_Zone
          ip_address: 10.255.1.4/32
        prefix_lists:
        - name: PL-LOOPBACKS-EVPN-OVERLAY
          sequence_numbers:
          - sequence: 10
            action: permit 192.168.255.0/24 eq 32
          - sequence: 20
            action: permit 192.168.254.0/24 eq 32
        router_bfd:
          multihop:
            interval: 300
            min_rx: 300
            multiplier: 3
        ip_igmp_snooping:
          globally_enabled: true
        ip_virtual_router_mac_address: 00:00:00:00:00:01
        vxlan_interface:
          Vxlan1:
            description: DC1_LEAF1B_VTEP
            vxlan:
              udp_port: 4789
              source_interface: Loopback1
              virtual_router_encapsulation_mac_address: mlag-system-id
              vlans:
              - id: 110
                vni: 10110
              - id: 111
                vni: 10111
              vrfs:
              - name: Tenant_A_OP_Zone
                vni: 10
        virtual_source_nat_vrfs:
        - name: Tenant_A_OP_Zone
          ip_address: 10.255.1.4
        management_security:
          ssl_profiles:
          - name: eAPI
            certificate:
              file: eAPI.crt
              key: eAPI.key
            cipher_list: HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
        ```

    === "DC1_SVC2A.yml"

        ```yaml
        hostname: DC1_SVC2A
        router_bgp:
          as: '65102'
          router_id: 192.168.255.5
          distance:
            external_routes: 20
            internal_routes: 200
            local_routes: 200
          bgp:
            default:
              ipv4_unicast: false
          maximum_paths:
            paths: 4
            ecmp: 4
          peer_groups:
          - name: MLAG-IPv4-UNDERLAY-PEER
            type: ipv4
            remote_as: '65102'
            next_hop_self: true
            description: DC1_SVC2B
            password: vnEaG8gMeQf3d3cN6PktXQ==
            maximum_routes: 12000
            send_community: all
            route_map_in: RM-MLAG-PEER-IN
          - name: IPv4-UNDERLAY-PEERS
            type: ipv4
            password: AQQvKeimxJu+uGQ/yYvv9w==
            maximum_routes: 12000
            send_community: all
          - name: EVPN-OVERLAY-PEERS
            type: evpn
            update_source: Loopback0
            bfd: true
            password: q+VNViP5i4rVjW1cxFv2wA==
            send_community: all
            maximum_routes: 0
            ebgp_multihop: 3
          address_family_ipv4:
            peer_groups:
            - name: MLAG-IPv4-UNDERLAY-PEER
              activate: true
            - name: IPv4-UNDERLAY-PEERS
              activate: true
            - name: EVPN-OVERLAY-PEERS
              activate: false
          neighbors:
          - ip_address: 10.255.251.5
            peer_group: MLAG-IPv4-UNDERLAY-PEER
            description: DC1_SVC2B
          - ip_address: 172.31.255.8
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65001'
            description: DC1_SPINE1_Ethernet3
          - ip_address: 172.31.255.10
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65001'
            description: DC1_SPINE2_Ethernet3
          - ip_address: 192.168.255.1
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SPINE1
            remote_as: '65001'
          - ip_address: 192.168.255.2
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SPINE2
            remote_as: '65001'
          redistribute_routes:
          - source_protocol: connected
            route_map: RM-CONN-2-BGP
          address_family_evpn:
            peer_groups:
            - name: EVPN-OVERLAY-PEERS
              activate: true
          vrfs:
          - name: Tenant_A_OP_Zone
            router_id: 192.168.255.5
            rd: 192.168.255.5:10
            route_targets:
              import:
              - address_family: evpn
                route_targets:
                - '10:10'
              export:
              - address_family: evpn
                route_targets:
                - '10:10'
            redistribute_routes:
            - source_protocol: connected
            neighbors:
            - ip_address: 10.255.251.5
              peer_group: MLAG-IPv4-UNDERLAY-PEER
          vlan_aware_bundles:
          - name: Tenant_A_OP_Zone
            rd: 192.168.255.5:10
            route_targets:
              both:
              - '10:10'
            redistribute_routes:
            - learned
            vlan: 112-113
        static_routes:
        - vrf: MGMT
          destination_address_prefix: 0.0.0.0/0
          gateway: 172.100.100.1
        service_routing_protocols_model: multi-agent
        ip_routing: true
        vlan_internal_order:
          allocation: ascending
          range:
            beginning: 1006
            ending: 1199
        ip_name_servers:
        - ip_address: 1.1.1.1
          vrf: MGMT
        - ip_address: 8.8.8.8
          vrf: MGMT
        spanning_tree:
          mode: mstp
          mst_instances:
          - id: '0'
            priority: 4096
          no_spanning_tree_vlan: 4093-4094
        local_users:
        - name: admin
          privilege: 15
          role: network-admin
          sha512_password: $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        vrfs:
        - name: MGMT
          ip_routing: false
        - name: Tenant_A_OP_Zone
          tenant: Tenant_A
          ip_routing: true
        management_interfaces:
        - name: Management0
          description: oob_management
          shutdown: false
          vrf: MGMT
          ip_address: 172.100.100.6/24
          gateway: 172.100.100.1
          type: oob
        management_api_http:
          enable_vrfs:
          - name: MGMT
          enable_https: true
          https_ssl_profile: eAPI
        vlans:
        - id: 4093
          tenant: system
          name: LEAF_PEER_L3
          trunk_groups:
          - LEAF_PEER_L3
        - id: 4094
          tenant: system
          name: MLAG_PEER
          trunk_groups:
          - MLAG
        - id: 112
          name: Tenant_A_OP_Zone_3
          tenant: Tenant_A
        - id: 113
          name: Tenant_A_OP_Zone_4
          tenant: Tenant_A
        - id: 3009
          name: MLAG_iBGP_Tenant_A_OP_Zone
          trunk_groups:
          - LEAF_PEER_L3
          tenant: Tenant_A
        vlan_interfaces:
        - name: Vlan4093
          description: MLAG_PEER_L3_PEERING
          shutdown: false
          mtu: 9214
          ip_address: 10.255.251.4/31
        - name: Vlan4094
          description: MLAG_PEER
          shutdown: false
          ip_address: 10.255.252.4/31
          no_autostate: true
          mtu: 9214
        - name: Vlan112
          tenant: Tenant_A
          tags:
          - opzone_pod2
          description: Tenant_A_OP_Zone_3
          shutdown: false
          ip_address_virtual: 10.1.12.1/24
          vrf: Tenant_A_OP_Zone
        - name: Vlan113
          tenant: Tenant_A
          tags:
          - opzone_pod2
          description: Tenant_A_OP_Zone_4
          shutdown: false
          ip_address_virtual: 10.1.13.1/24
          vrf: Tenant_A_OP_Zone
        - name: Vlan3009
          tenant: Tenant_A
          type: underlay_peering
          shutdown: false
          description: 'MLAG_PEER_L3_iBGP: vrf Tenant_A_OP_Zone'
          vrf: Tenant_A_OP_Zone
          mtu: 9214
          ip_address: 10.255.251.4/31
        port_channel_interfaces:
        - name: Port-Channel3
          description: MLAG_PEER_DC1_SVC2B_Po3
          type: switched
          shutdown: false
          mode: trunk
          trunk_groups:
          - LEAF_PEER_L3
          - MLAG
        - name: Port-Channel5
          description: DC1_L2_LEAF_Po1
          type: switched
          shutdown: false
          mode: trunk
          vlans: 112-113
          mlag: 5
        ethernet_interfaces:
        - name: Ethernet3
          peer: DC1_SVC2B
          peer_interface: Ethernet3
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_SVC2B_Ethernet3
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet4
          peer: DC1_SVC2B
          peer_interface: Ethernet4
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_SVC2B_Ethernet4
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet1
          peer: DC1_SPINE1
          peer_interface: Ethernet3
          peer_type: spine
          description: P2P_LINK_TO_DC1_SPINE1_Ethernet3
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.9/31
        - name: Ethernet2
          peer: DC1_SPINE2
          peer_interface: Ethernet3
          peer_type: spine
          description: P2P_LINK_TO_DC1_SPINE2_Ethernet3
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.11/31
        - name: Ethernet5
          peer: DC1_L2_LEAF2A
          peer_interface: Ethernet1
          peer_type: l2leaf
          description: DC1_L2_LEAF2A_Ethernet1
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 5
            mode: active
        - name: Ethernet6
          peer: DC1_L2_LEAF2B
          peer_interface: Ethernet1
          peer_type: l2leaf
          description: DC1_L2_LEAF2B_Ethernet1
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 5
            mode: active
        mlag_configuration:
          domain_id: DC1_SVC2
          local_interface: Vlan4094
          peer_address: 10.255.252.5
          peer_link: Port-Channel3
          reload_delay_mlag: '300'
          reload_delay_non_mlag: '330'
        route_maps:
        - name: RM-MLAG-PEER-IN
          sequence_numbers:
          - sequence: 10
            type: permit
            set:
            - origin incomplete
            description: Make routes learned over MLAG Peer-link less preferred on spines to ensure optimal routing
        - name: RM-CONN-2-BGP
          sequence_numbers:
          - sequence: 10
            type: permit
            match:
            - ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        loopback_interfaces:
        - name: Loopback0
          description: EVPN_Overlay_Peering
          shutdown: false
          ip_address: 192.168.255.5/32
        - name: Loopback1
          description: VTEP_VXLAN_Tunnel_Source
          shutdown: false
          ip_address: 192.168.254.5/32
        - name: Loopback100
          description: Tenant_A_OP_Zone_VTEP_DIAGNOSTICS
          shutdown: false
          vrf: Tenant_A_OP_Zone
          ip_address: 10.255.1.5/32
        prefix_lists:
        - name: PL-LOOPBACKS-EVPN-OVERLAY
          sequence_numbers:
          - sequence: 10
            action: permit 192.168.255.0/24 eq 32
          - sequence: 20
            action: permit 192.168.254.0/24 eq 32
        router_bfd:
          multihop:
            interval: 300
            min_rx: 300
            multiplier: 3
        ip_igmp_snooping:
          globally_enabled: true
        ip_virtual_router_mac_address: 00:00:00:00:00:01
        vxlan_interface:
          Vxlan1:
            description: DC1_SVC2A_VTEP
            vxlan:
              udp_port: 4789
              source_interface: Loopback1
              virtual_router_encapsulation_mac_address: mlag-system-id
              vlans:
              - id: 112
                vni: 10112
              - id: 113
                vni: 10113
              vrfs:
              - name: Tenant_A_OP_Zone
                vni: 10
        virtual_source_nat_vrfs:
        - name: Tenant_A_OP_Zone
          ip_address: 10.255.1.5
        management_security:
          ssl_profiles:
          - name: eAPI
            certificate:
              file: eAPI.crt
              key: eAPI.key
            cipher_list: HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
        ```

    === "DC1_SVC2B.yaml"

        ```yaml
        hostname: DC1_SVC2B
        router_bgp:
          as: '65102'
          router_id: 192.168.255.6
          distance:
            external_routes: 20
            internal_routes: 200
            local_routes: 200
          bgp:
            default:
              ipv4_unicast: false
          maximum_paths:
            paths: 4
            ecmp: 4
          peer_groups:
          - name: MLAG-IPv4-UNDERLAY-PEER
            type: ipv4
            remote_as: '65102'
            next_hop_self: true
            description: DC1_SVC2A
            password: vnEaG8gMeQf3d3cN6PktXQ==
            maximum_routes: 12000
            send_community: all
            route_map_in: RM-MLAG-PEER-IN
          - name: IPv4-UNDERLAY-PEERS
            type: ipv4
            password: AQQvKeimxJu+uGQ/yYvv9w==
            maximum_routes: 12000
            send_community: all
          - name: EVPN-OVERLAY-PEERS
            type: evpn
            update_source: Loopback0
            bfd: true
            password: q+VNViP5i4rVjW1cxFv2wA==
            send_community: all
            maximum_routes: 0
            ebgp_multihop: 3
          address_family_ipv4:
            peer_groups:
            - name: MLAG-IPv4-UNDERLAY-PEER
              activate: true
            - name: IPv4-UNDERLAY-PEERS
              activate: true
            - name: EVPN-OVERLAY-PEERS
              activate: false
          neighbors:
          - ip_address: 10.255.251.4
            peer_group: MLAG-IPv4-UNDERLAY-PEER
            description: DC1_SVC2A
          - ip_address: 172.31.255.12
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65001'
            description: DC1_SPINE1_Ethernet4
          - ip_address: 172.31.255.14
            peer_group: IPv4-UNDERLAY-PEERS
            remote_as: '65001'
            description: DC1_SPINE2_Ethernet4
          - ip_address: 192.168.255.1
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SPINE1
            remote_as: '65001'
          - ip_address: 192.168.255.2
            peer_group: EVPN-OVERLAY-PEERS
            description: DC1_SPINE2
            remote_as: '65001'
          redistribute_routes:
          - source_protocol: connected
            route_map: RM-CONN-2-BGP
          address_family_evpn:
            peer_groups:
            - name: EVPN-OVERLAY-PEERS
              activate: true
          vrfs:
          - name: Tenant_A_OP_Zone
            router_id: 192.168.255.6
            rd: 192.168.255.6:10
            route_targets:
              import:
              - address_family: evpn
                route_targets:
                - '10:10'
              export:
              - address_family: evpn
                route_targets:
                - '10:10'
            redistribute_routes:
            - source_protocol: connected
            neighbors:
            - ip_address: 10.255.251.4
              peer_group: MLAG-IPv4-UNDERLAY-PEER
          vlan_aware_bundles:
          - name: Tenant_A_OP_Zone
            rd: 192.168.255.6:10
            route_targets:
              both:
              - '10:10'
            redistribute_routes:
            - learned
            vlan: 112-113
        static_routes:
        - vrf: MGMT
          destination_address_prefix: 0.0.0.0/0
          gateway: 172.100.100.1
        service_routing_protocols_model: multi-agent
        ip_routing: true
        vlan_internal_order:
          allocation: ascending
          range:
            beginning: 1006
            ending: 1199
        ip_name_servers:
        - ip_address: 1.1.1.1
          vrf: MGMT
        - ip_address: 8.8.8.8
          vrf: MGMT
        spanning_tree:
          mode: mstp
          mst_instances:
          - id: '0'
            priority: 4096
          no_spanning_tree_vlan: 4093-4094
        local_users:
        - name: admin
          privilege: 15
          role: network-admin
          sha512_password: $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        vrfs:
        - name: MGMT
          ip_routing: false
        - name: Tenant_A_OP_Zone
          tenant: Tenant_A
          ip_routing: true
        management_interfaces:
        - name: Management0
          description: oob_management
          shutdown: false
          vrf: MGMT
          ip_address: 172.100.100.7/24
          gateway: 172.100.100.1
          type: oob
        management_api_http:
          enable_vrfs:
          - name: MGMT
          enable_https: true
          https_ssl_profile: eAPI
        vlans:
        - id: 4093
          tenant: system
          name: LEAF_PEER_L3
          trunk_groups:
          - LEAF_PEER_L3
        - id: 4094
          tenant: system
          name: MLAG_PEER
          trunk_groups:
          - MLAG
        - id: 112
          name: Tenant_A_OP_Zone_3
          tenant: Tenant_A
        - id: 113
          name: Tenant_A_OP_Zone_4
          tenant: Tenant_A
        - id: 3009
          name: MLAG_iBGP_Tenant_A_OP_Zone
          trunk_groups:
          - LEAF_PEER_L3
          tenant: Tenant_A
        vlan_interfaces:
        - name: Vlan4093
          description: MLAG_PEER_L3_PEERING
          shutdown: false
          mtu: 9214
          ip_address: 10.255.251.5/31
        - name: Vlan4094
          description: MLAG_PEER
          shutdown: false
          ip_address: 10.255.252.5/31
          no_autostate: true
          mtu: 9214
        - name: Vlan112
          tenant: Tenant_A
          tags:
          - opzone_pod2
          description: Tenant_A_OP_Zone_3
          shutdown: false
          ip_address_virtual: 10.1.12.1/24
          vrf: Tenant_A_OP_Zone
        - name: Vlan113
          tenant: Tenant_A
          tags:
          - opzone_pod2
          description: Tenant_A_OP_Zone_4
          shutdown: false
          ip_address_virtual: 10.1.13.1/24
          vrf: Tenant_A_OP_Zone
        - name: Vlan3009
          tenant: Tenant_A
          type: underlay_peering
          shutdown: false
          description: 'MLAG_PEER_L3_iBGP: vrf Tenant_A_OP_Zone'
          vrf: Tenant_A_OP_Zone
          mtu: 9214
          ip_address: 10.255.251.5/31
        port_channel_interfaces:
        - name: Port-Channel3
          description: MLAG_PEER_DC1_SVC2A_Po3
          type: switched
          shutdown: false
          mode: trunk
          trunk_groups:
          - LEAF_PEER_L3
          - MLAG
        - name: Port-Channel5
          description: DC1_L2_LEAF_Po1
          type: switched
          shutdown: false
          mode: trunk
          vlans: 112-113
          mlag: 5
        ethernet_interfaces:
        - name: Ethernet3
          peer: DC1_SVC2A
          peer_interface: Ethernet3
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_SVC2A_Ethernet3
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet4
          peer: DC1_SVC2A
          peer_interface: Ethernet4
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_SVC2A_Ethernet4
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet1
          peer: DC1_SPINE1
          peer_interface: Ethernet4
          peer_type: spine
          description: P2P_LINK_TO_DC1_SPINE1_Ethernet4
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.13/31
        - name: Ethernet2
          peer: DC1_SPINE2
          peer_interface: Ethernet4
          peer_type: spine
          description: P2P_LINK_TO_DC1_SPINE2_Ethernet4
          shutdown: false
          mtu: 9214
          type: routed
          ip_address: 172.31.255.15/31
        - name: Ethernet5
          peer: DC1_L2_LEAF2A
          peer_interface: Ethernet2
          peer_type: l2leaf
          description: DC1_L2_LEAF2A_Ethernet2
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 5
            mode: active
        - name: Ethernet6
          peer: DC1_L2_LEAF2B
          peer_interface: Ethernet2
          peer_type: l2leaf
          description: DC1_L2_LEAF2B_Ethernet2
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 5
            mode: active
        mlag_configuration:
          domain_id: DC1_SVC2
          local_interface: Vlan4094
          peer_address: 10.255.252.4
          peer_link: Port-Channel3
          reload_delay_mlag: '300'
          reload_delay_non_mlag: '330'
        route_maps:
        - name: RM-MLAG-PEER-IN
          sequence_numbers:
          - sequence: 10
            type: permit
            set:
            - origin incomplete
            description: Make routes learned over MLAG Peer-link less preferred on spines to ensure optimal routing
        - name: RM-CONN-2-BGP
          sequence_numbers:
          - sequence: 10
            type: permit
            match:
            - ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        loopback_interfaces:
        - name: Loopback0
          description: EVPN_Overlay_Peering
          shutdown: false
          ip_address: 192.168.255.6/32
        - name: Loopback1
          description: VTEP_VXLAN_Tunnel_Source
          shutdown: false
          ip_address: 192.168.254.5/32
        - name: Loopback100
          description: Tenant_A_OP_Zone_VTEP_DIAGNOSTICS
          shutdown: false
          vrf: Tenant_A_OP_Zone
          ip_address: 10.255.1.6/32
        prefix_lists:
        - name: PL-LOOPBACKS-EVPN-OVERLAY
          sequence_numbers:
          - sequence: 10
            action: permit 192.168.255.0/24 eq 32
          - sequence: 20
            action: permit 192.168.254.0/24 eq 32
        router_bfd:
          multihop:
            interval: 300
            min_rx: 300
            multiplier: 3
        ip_igmp_snooping:
          globally_enabled: true
        ip_virtual_router_mac_address: 00:00:00:00:00:01
        vxlan_interface:
          Vxlan1:
            description: DC1_SVC2B_VTEP
            vxlan:
              udp_port: 4789
              source_interface: Loopback1
              virtual_router_encapsulation_mac_address: mlag-system-id
              vlans:
              - id: 112
                vni: 10112
              - id: 113
                vni: 10113
              vrfs:
              - name: Tenant_A_OP_Zone
                vni: 10
        virtual_source_nat_vrfs:
        - name: Tenant_A_OP_Zone
          ip_address: 10.255.1.6
        management_security:
          ssl_profiles:
          - name: eAPI
            certificate:
              file: eAPI.crt
              key: eAPI.key
            cipher_list: HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
        ```

    === "DC1_L2_LEAF2A.yaml"

        ```yaml
        hostname: DC1_L2_LEAF2A
        static_routes:
        - vrf: MGMT
          destination_address_prefix: 0.0.0.0/0
          gateway: 172.100.100.1
        service_routing_protocols_model: multi-agent
        vlan_internal_order:
          allocation: ascending
          range:
            beginning: 1006
            ending: 1199
        ip_name_servers:
        - ip_address: 1.1.1.1
          vrf: MGMT
        - ip_address: 8.8.8.8
          vrf: MGMT
        spanning_tree:
          mode: mstp
          mst_instances:
          - id: '0'
            priority: 16384
          no_spanning_tree_vlan: '4094'
        local_users:
        - name: admin
          privilege: 15
          role: network-admin
          sha512_password: $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        vrfs:
        - name: MGMT
          ip_routing: false
        management_interfaces:
        - name: Management0
          description: oob_management
          shutdown: false
          vrf: MGMT
          ip_address: 172.100.100.8/24
          gateway: 172.100.100.1
          type: oob
        management_api_http:
          enable_vrfs:
          - name: MGMT
          enable_https: true
          https_ssl_profile: eAPI
        vlans:
        - id: 4094
          tenant: system
          name: MLAG_PEER
          trunk_groups:
          - MLAG
        - id: 112
          name: Tenant_A_OP_Zone_3
          tenant: Tenant_A
        - id: 113
          name: Tenant_A_OP_Zone_4
          tenant: Tenant_A
        vlan_interfaces:
        - name: Vlan4094
          description: MLAG_PEER
          shutdown: false
          ip_address: 10.255.252.8/31
          no_autostate: true
          mtu: 9214
        port_channel_interfaces:
        - name: Port-Channel3
          description: MLAG_PEER_DC1_L2_LEAF2B_Po3
          type: switched
          shutdown: false
          mode: trunk
          trunk_groups:
          - MLAG
        - name: Port-Channel1
          description: DC1_SVC2_Po5
          type: switched
          shutdown: false
          mode: trunk
          vlans: 112-113
          mlag: 1
        - name: Port-Channel5
          description: server03_PortChannel5
          type: switched
          shutdown: false
          mode: trunk
          vlans: '112'
          spanning_tree_portfast: edge
          mlag: 5
        - name: Port-Channel6
          description: server04_PortChannel6
          type: switched
          shutdown: false
          mode: trunk
          vlans: '113'
          spanning_tree_portfast: edge
          mlag: 6
        ethernet_interfaces:
        - name: Ethernet3
          peer: DC1_L2_LEAF2B
          peer_interface: Ethernet3
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_L2_LEAF2B_Ethernet3
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet4
          peer: DC1_L2_LEAF2B
          peer_interface: Ethernet4
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_L2_LEAF2B_Ethernet4
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet1
          peer: DC1_SVC2A
          peer_interface: Ethernet5
          peer_type: l3leaf
          description: DC1_SVC2A_Ethernet5
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 1
            mode: active
        - name: Ethernet2
          peer: DC1_SVC2B
          peer_interface: Ethernet5
          peer_type: l3leaf
          description: DC1_SVC2B_Ethernet5
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 1
            mode: active
        - name: Ethernet5
          peer: server03
          peer_interface: Eth1
          peer_type: server
          port_profile: Tenant_A_pod2_clientA
          description: server03_Eth1
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 5
            mode: active
        - name: Ethernet6
          peer: server04
          peer_interface: Eth1
          peer_type: server
          port_profile: Tenant_A_pod2_clientB
          description: server04_Eth1
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 6
            mode: active
        mlag_configuration:
          domain_id: DC1_L2_LEAF
          local_interface: Vlan4094
          peer_address: 10.255.252.9
          peer_link: Port-Channel3
          reload_delay_mlag: '300'
          reload_delay_non_mlag: '330'
        ip_igmp_snooping:
          globally_enabled: true
        management_security:
          ssl_profiles:
          - name: eAPI
            certificate:
              file: eAPI.crt
              key: eAPI.key
            cipher_list: HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
        ```

    === "DC1_L2_LEAF2B.yaml"

        ```yaml
        hostname: DC1_L2_LEAF2B
        static_routes:
        - vrf: MGMT
          destination_address_prefix: 0.0.0.0/0
          gateway: 172.100.100.1
        service_routing_protocols_model: multi-agent
        vlan_internal_order:
          allocation: ascending
          range:
            beginning: 1006
            ending: 1199
        ip_name_servers:
        - ip_address: 1.1.1.1
          vrf: MGMT
        - ip_address: 8.8.8.8
          vrf: MGMT
        spanning_tree:
          mode: mstp
          mst_instances:
          - id: '0'
            priority: 16384
          no_spanning_tree_vlan: '4094'
        local_users:
        - name: admin
          privilege: 15
          role: network-admin
          sha512_password: $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        vrfs:
        - name: MGMT
          ip_routing: false
        management_interfaces:
        - name: Management0
          description: oob_management
          shutdown: false
          vrf: MGMT
          ip_address: 172.100.100.9/24
          gateway: 172.100.100.1
          type: oob
        management_api_http:
          enable_vrfs:
          - name: MGMT
          enable_https: true
          https_ssl_profile: eAPI
        vlans:
        - id: 4094
          tenant: system
          name: MLAG_PEER
          trunk_groups:
          - MLAG
        - id: 112
          name: Tenant_A_OP_Zone_3
          tenant: Tenant_A
        - id: 113
          name: Tenant_A_OP_Zone_4
          tenant: Tenant_A
        vlan_interfaces:
        - name: Vlan4094
          description: MLAG_PEER
          shutdown: false
          ip_address: 10.255.252.9/31
          no_autostate: true
          mtu: 9214
        port_channel_interfaces:
        - name: Port-Channel3
          description: MLAG_PEER_DC1_L2_LEAF2A_Po3
          type: switched
          shutdown: false
          mode: trunk
          trunk_groups:
          - MLAG
        - name: Port-Channel1
          description: DC1_SVC2_Po5
          type: switched
          shutdown: false
          mode: trunk
          vlans: 112-113
          mlag: 1
        - name: Port-Channel5
          description: server03_PortChannel5
          type: switched
          shutdown: false
          mode: trunk
          vlans: '112'
          spanning_tree_portfast: edge
          mlag: 5
        - name: Port-Channel6
          description: server04_PortChannel6
          type: switched
          shutdown: false
          mode: trunk
          vlans: '113'
          spanning_tree_portfast: edge
          mlag: 6
        ethernet_interfaces:
        - name: Ethernet3
          peer: DC1_L2_LEAF2A
          peer_interface: Ethernet3
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_L2_LEAF2A_Ethernet3
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet4
          peer: DC1_L2_LEAF2A
          peer_interface: Ethernet4
          peer_type: mlag_peer
          description: MLAG_PEER_DC1_L2_LEAF2A_Ethernet4
          type: port-channel-member
          shutdown: false
          channel_group:
            id: 3
            mode: active
        - name: Ethernet1
          peer: DC1_SVC2A
          peer_interface: Ethernet6
          peer_type: l3leaf
          description: DC1_SVC2A_Ethernet6
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 1
            mode: active
        - name: Ethernet2
          peer: DC1_SVC2B
          peer_interface: Ethernet6
          peer_type: l3leaf
          description: DC1_SVC2B_Ethernet6
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 1
            mode: active
        - name: Ethernet5
          peer: server03
          peer_interface: Eth2
          peer_type: server
          port_profile: Tenant_A_pod2_clientA
          description: server03_Eth2
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 5
            mode: active
        - name: Ethernet6
          peer: server04
          peer_interface: Eth2
          peer_type: server
          port_profile: Tenant_A_pod2_clientB
          description: server04_Eth2
          shutdown: false
          type: port-channel-member
          channel_group:
            id: 6
            mode: active
        mlag_configuration:
          domain_id: DC1_L2_LEAF
          local_interface: Vlan4094
          peer_address: 10.255.252.8
          peer_link: Port-Channel3
          reload_delay_mlag: '300'
          reload_delay_non_mlag: '330'
        ip_igmp_snooping:
          globally_enabled: true
        management_security:
          ssl_profiles:
          - name: eAPI
            certificate:
              file: eAPI.crt
              key: eAPI.key
            cipher_list: HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
        ```

* From the third task in the playbook which uses `arista.avd.eos_cli_config_gen` we can see the intended EOS configuration per node is generated under `intended/configs` directory.

??? note "Reveal Output"

    === "DC1_SPINE1.cfg"

        ```bash
        !RANCID-CONTENT-TYPE: arista
        !
        vlan internal order ascending range 1006 1199
        !
        transceiver qsfp default-mode 4x10G
        !
        service routing protocols model multi-agent
        !
        hostname DC1_SPINE1
        ip name-server vrf MGMT 1.1.1.1
        ip name-server vrf MGMT 8.8.8.8
        !
        ntp server vrf MGMT time.google.com prefer iburst
        !
        spanning-tree mode mstp
        !
        no enable password
        no aaa root
        !
        username admin privilege 15 role network-admin secret sha512 $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        !
        vrf instance MGMT
        !
        interface Ethernet1
           description P2P_LINK_TO_DC1_LEAF1A_Ethernet1
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.0/31
        !
        interface Ethernet2
           description P2P_LINK_TO_DC1_LEAF1B_Ethernet1
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.4/31
        !
        interface Ethernet3
           description P2P_LINK_TO_DC1_SVC2A_Ethernet1
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.8/31
        !
        interface Ethernet4
           description P2P_LINK_TO_DC1_SVC2B_Ethernet1
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.12/31
        !
        interface Loopback0
           description EVPN_Overlay_Peering
           no shutdown
           ip address 192.168.255.1/32
        !
        interface Management0
           description oob_management
           no shutdown
           vrf MGMT
           ip address 172.100.100.2/24
        !
        ip routing
        no ip routing vrf MGMT
        !
        ip prefix-list PL-LOOPBACKS-EVPN-OVERLAY
           seq 10 permit 192.168.255.0/24 eq 32
        !
        ip route vrf MGMT 0.0.0.0/0 172.100.100.1
        !
        route-map RM-CONN-2-BGP permit 10
           match ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        !
        router bfd
           multihop interval 300 min-rx 300 multiplier 3
        !
        router bgp 65001
           router-id 192.168.255.1
           distance bgp 20 200 200
           maximum-paths 4 ecmp 4
           no bgp default ipv4-unicast
           neighbor EVPN-OVERLAY-PEERS peer group
           neighbor EVPN-OVERLAY-PEERS next-hop-unchanged
           neighbor EVPN-OVERLAY-PEERS update-source Loopback0
           neighbor EVPN-OVERLAY-PEERS bfd
           neighbor EVPN-OVERLAY-PEERS ebgp-multihop 3
           neighbor EVPN-OVERLAY-PEERS password 7 q+VNViP5i4rVjW1cxFv2wA==
           neighbor EVPN-OVERLAY-PEERS send-community
           neighbor EVPN-OVERLAY-PEERS maximum-routes 0
           neighbor IPv4-UNDERLAY-PEERS peer group
           neighbor IPv4-UNDERLAY-PEERS password 7 AQQvKeimxJu+uGQ/yYvv9w==
           neighbor IPv4-UNDERLAY-PEERS send-community
           neighbor IPv4-UNDERLAY-PEERS maximum-routes 12000
           neighbor 172.31.255.1 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.1 remote-as 65101
           neighbor 172.31.255.1 description DC1_LEAF1A_Ethernet1
           neighbor 172.31.255.5 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.5 remote-as 65101
           neighbor 172.31.255.5 description DC1_LEAF1B_Ethernet1
           neighbor 172.31.255.9 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.9 remote-as 65102
           neighbor 172.31.255.9 description DC1_SVC2A_Ethernet1
           neighbor 172.31.255.13 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.13 remote-as 65102
           neighbor 172.31.255.13 description DC1_SVC2B_Ethernet1
           neighbor 192.168.255.3 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.3 remote-as 65101
           neighbor 192.168.255.3 description DC1_LEAF1A
           neighbor 192.168.255.4 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.4 remote-as 65101
           neighbor 192.168.255.4 description DC1_LEAF1B
           neighbor 192.168.255.5 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.5 remote-as 65102
           neighbor 192.168.255.5 description DC1_SVC2A
           neighbor 192.168.255.6 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.6 remote-as 65102
           neighbor 192.168.255.6 description DC1_SVC2B
           redistribute connected route-map RM-CONN-2-BGP
           !
           address-family evpn
              neighbor EVPN-OVERLAY-PEERS activate
           !
           address-family ipv4
              no neighbor EVPN-OVERLAY-PEERS activate
              neighbor IPv4-UNDERLAY-PEERS activate
        !
        management api http-commands
           protocol https
           protocol https ssl profile eAPI
           no shutdown
           !
           vrf MGMT
              no shutdown
        !
        management security
           ssl profile eAPI
              cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
              certificate eAPI.crt key eAPI.key
        !
        end
        ```

    === "DC1_SPINE2.cfg"

        ```bash
        !RANCID-CONTENT-TYPE: arista
        !
        vlan internal order ascending range 1006 1199
        !
        transceiver qsfp default-mode 4x10G
        !
        service routing protocols model multi-agent
        !
        hostname DC1_SPINE2
        ip name-server vrf MGMT 1.1.1.1
        ip name-server vrf MGMT 8.8.8.8
        !
        ntp server vrf MGMT time.google.com prefer iburst
        !
        spanning-tree mode mstp
        !
        no enable password
        no aaa root
        !
        username admin privilege 15 role network-admin secret sha512 $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        !
        vrf instance MGMT
        !
        interface Ethernet1
           description P2P_LINK_TO_DC1_LEAF1A_Ethernet2
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.2/31
        !
        interface Ethernet2
           description P2P_LINK_TO_DC1_LEAF1B_Ethernet2
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.6/31
        !
        interface Ethernet3
           description P2P_LINK_TO_DC1_SVC2A_Ethernet2
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.10/31
        !
        interface Ethernet4
           description P2P_LINK_TO_DC1_SVC2B_Ethernet2
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.14/31
        !
        interface Loopback0
           description EVPN_Overlay_Peering
           no shutdown
           ip address 192.168.255.2/32
        !
        interface Management0
           description oob_management
           no shutdown
           vrf MGMT
           ip address 172.100.100.3/24
        !
        ip routing
        no ip routing vrf MGMT
        !
        ip prefix-list PL-LOOPBACKS-EVPN-OVERLAY
           seq 10 permit 192.168.255.0/24 eq 32
        !
        ip route vrf MGMT 0.0.0.0/0 172.100.100.1
        !
        route-map RM-CONN-2-BGP permit 10
           match ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        !
        router bfd
           multihop interval 300 min-rx 300 multiplier 3
        !
        router bgp 65001
           router-id 192.168.255.2
           distance bgp 20 200 200
           maximum-paths 4 ecmp 4
           no bgp default ipv4-unicast
           neighbor EVPN-OVERLAY-PEERS peer group
           neighbor EVPN-OVERLAY-PEERS next-hop-unchanged
           neighbor EVPN-OVERLAY-PEERS update-source Loopback0
           neighbor EVPN-OVERLAY-PEERS bfd
           neighbor EVPN-OVERLAY-PEERS ebgp-multihop 3
           neighbor EVPN-OVERLAY-PEERS password 7 q+VNViP5i4rVjW1cxFv2wA==
           neighbor EVPN-OVERLAY-PEERS send-community
           neighbor EVPN-OVERLAY-PEERS maximum-routes 0
           neighbor IPv4-UNDERLAY-PEERS peer group
           neighbor IPv4-UNDERLAY-PEERS password 7 AQQvKeimxJu+uGQ/yYvv9w==
           neighbor IPv4-UNDERLAY-PEERS send-community
           neighbor IPv4-UNDERLAY-PEERS maximum-routes 12000
           neighbor 172.31.255.3 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.3 remote-as 65101
           neighbor 172.31.255.3 description DC1_LEAF1A_Ethernet2
           neighbor 172.31.255.7 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.7 remote-as 65101
           neighbor 172.31.255.7 description DC1_LEAF1B_Ethernet2
           neighbor 172.31.255.11 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.11 remote-as 65102
           neighbor 172.31.255.11 description DC1_SVC2A_Ethernet2
           neighbor 172.31.255.15 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.15 remote-as 65102
           neighbor 172.31.255.15 description DC1_SVC2B_Ethernet2
           neighbor 192.168.255.3 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.3 remote-as 65101
           neighbor 192.168.255.3 description DC1_LEAF1A
           neighbor 192.168.255.4 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.4 remote-as 65101
           neighbor 192.168.255.4 description DC1_LEAF1B
           neighbor 192.168.255.5 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.5 remote-as 65102
           neighbor 192.168.255.5 description DC1_SVC2A
           neighbor 192.168.255.6 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.6 remote-as 65102
           neighbor 192.168.255.6 description DC1_SVC2B
           redistribute connected route-map RM-CONN-2-BGP
           !
           address-family evpn
              neighbor EVPN-OVERLAY-PEERS activate
           !
           address-family ipv4
              no neighbor EVPN-OVERLAY-PEERS activate
              neighbor IPv4-UNDERLAY-PEERS activate
        !
        management api http-commands
           protocol https
           protocol https ssl profile eAPI
           no shutdown
           !
           vrf MGMT
              no shutdown
        !
        management security
           ssl profile eAPI
              cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
              certificate eAPI.crt key eAPI.key
        !
        end
        ```

    === "DC1_LEAF1A.cfg"

        ```bash
        !RANCID-CONTENT-TYPE: arista
        !
        vlan internal order ascending range 1006 1199
        !
        transceiver qsfp default-mode 4x10G
        !
        service routing protocols model multi-agent
        !
        hostname DC1_LEAF1A
        ip name-server vrf MGMT 1.1.1.1
        ip name-server vrf MGMT 8.8.8.8
        !
        ntp server vrf MGMT time.google.com prefer iburst
        !
        spanning-tree mode mstp
        no spanning-tree vlan-id 4093-4094
        spanning-tree mst 0 priority 4096
        !
        no enable password
        no aaa root
        !
        username admin privilege 15 role network-admin secret sha512 $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        !
        vlan 110
           name Tenant_A_OP_Zone_1
        !
        vlan 111
           name Tenant_A_OP_Zone_2
        !
        vlan 3009
           name MLAG_iBGP_Tenant_A_OP_Zone
           trunk group LEAF_PEER_L3
        !
        vlan 4093
           name LEAF_PEER_L3
           trunk group LEAF_PEER_L3
        !
        vlan 4094
           name MLAG_PEER
           trunk group MLAG
        !
        vrf instance MGMT
        !
        vrf instance Tenant_A_OP_Zone
        !
        interface Port-Channel3
           description MLAG_PEER_DC1_LEAF1B_Po3
           no shutdown
           switchport
           switchport mode trunk
           switchport trunk group LEAF_PEER_L3
           switchport trunk group MLAG
        !
        interface Port-Channel5
           description server01_PortChannel5
           no shutdown
           switchport
           switchport trunk allowed vlan 110
           switchport mode trunk
           mlag 5
           spanning-tree portfast
        !
        interface Port-Channel6
           description server02_PortChannel6
           no shutdown
           switchport
           switchport trunk allowed vlan 111
           switchport mode trunk
           mlag 6
           spanning-tree portfast
        !
        interface Ethernet1
           description P2P_LINK_TO_DC1_SPINE1_Ethernet1
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.1/31
        !
        interface Ethernet2
           description P2P_LINK_TO_DC1_SPINE2_Ethernet1
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.3/31
        !
        interface Ethernet3
           description MLAG_PEER_DC1_LEAF1B_Ethernet3
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet4
           description MLAG_PEER_DC1_LEAF1B_Ethernet4
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet5
           description server01_Eth1
           no shutdown
           channel-group 5 mode active
        !
        interface Ethernet6
           description server02_Eth1
           no shutdown
           channel-group 6 mode active
        !
        interface Loopback0
           description EVPN_Overlay_Peering
           no shutdown
           ip address 192.168.255.3/32
        !
        interface Loopback1
           description VTEP_VXLAN_Tunnel_Source
           no shutdown
           ip address 192.168.254.3/32
        !
        interface Loopback100
           description Tenant_A_OP_Zone_VTEP_DIAGNOSTICS
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address 10.255.1.3/32
        !
        interface Management0
           description oob_management
           no shutdown
           vrf MGMT
           ip address 172.100.100.4/24
        !
        interface Vlan110
           description Tenant_A_OP_Zone_1
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address virtual 10.1.10.1/24
        !
        interface Vlan111
           description Tenant_A_OP_Zone_2
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address virtual 10.1.11.1/24
        !
        interface Vlan3009
           description MLAG_PEER_L3_iBGP: vrf Tenant_A_OP_Zone
           no shutdown
           mtu 9214
           vrf Tenant_A_OP_Zone
           ip address 10.255.251.0/31
        !
        interface Vlan4093
           description MLAG_PEER_L3_PEERING
           no shutdown
           mtu 9214
           ip address 10.255.251.0/31
        !
        interface Vlan4094
           description MLAG_PEER
           no shutdown
           mtu 9214
           no autostate
           ip address 10.255.252.0/31
        !
        interface Vxlan1
           description DC1_LEAF1A_VTEP
           vxlan source-interface Loopback1
           vxlan virtual-router encapsulation mac-address mlag-system-id
           vxlan udp-port 4789
           vxlan vlan 110 vni 10110
           vxlan vlan 111 vni 10111
           vxlan vrf Tenant_A_OP_Zone vni 10
        !
        ip virtual-router mac-address 00:00:00:00:00:01
        !
        ip address virtual source-nat vrf Tenant_A_OP_Zone address 10.255.1.3
        !
        ip routing
        no ip routing vrf MGMT
        ip routing vrf Tenant_A_OP_Zone
        !
        ip prefix-list PL-LOOPBACKS-EVPN-OVERLAY
           seq 10 permit 192.168.255.0/24 eq 32
           seq 20 permit 192.168.254.0/24 eq 32
        !
        mlag configuration
           domain-id DC1_LEAF1
           local-interface Vlan4094
           peer-address 10.255.252.1
           peer-link Port-Channel3
           reload-delay mlag 300
           reload-delay non-mlag 330
        !
        ip route vrf MGMT 0.0.0.0/0 172.100.100.1
        !
        route-map RM-CONN-2-BGP permit 10
           match ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        !
        route-map RM-MLAG-PEER-IN permit 10
           description Make routes learned over MLAG Peer-link less preferred on spines to ensure optimal routing
           set origin incomplete
        !
        router bfd
           multihop interval 300 min-rx 300 multiplier 3
        !
        router bgp 65101
           router-id 192.168.255.3
           distance bgp 20 200 200
           maximum-paths 4 ecmp 4
           no bgp default ipv4-unicast
           neighbor EVPN-OVERLAY-PEERS peer group
           neighbor EVPN-OVERLAY-PEERS update-source Loopback0
           neighbor EVPN-OVERLAY-PEERS bfd
           neighbor EVPN-OVERLAY-PEERS ebgp-multihop 3
           neighbor EVPN-OVERLAY-PEERS password 7 q+VNViP5i4rVjW1cxFv2wA==
           neighbor EVPN-OVERLAY-PEERS send-community
           neighbor EVPN-OVERLAY-PEERS maximum-routes 0
           neighbor IPv4-UNDERLAY-PEERS peer group
           neighbor IPv4-UNDERLAY-PEERS password 7 AQQvKeimxJu+uGQ/yYvv9w==
           neighbor IPv4-UNDERLAY-PEERS send-community
           neighbor IPv4-UNDERLAY-PEERS maximum-routes 12000
           neighbor MLAG-IPv4-UNDERLAY-PEER peer group
           neighbor MLAG-IPv4-UNDERLAY-PEER remote-as 65101
           neighbor MLAG-IPv4-UNDERLAY-PEER next-hop-self
           neighbor MLAG-IPv4-UNDERLAY-PEER description DC1_LEAF1B
           neighbor MLAG-IPv4-UNDERLAY-PEER password 7 vnEaG8gMeQf3d3cN6PktXQ==
           neighbor MLAG-IPv4-UNDERLAY-PEER send-community
           neighbor MLAG-IPv4-UNDERLAY-PEER maximum-routes 12000
           neighbor MLAG-IPv4-UNDERLAY-PEER route-map RM-MLAG-PEER-IN in
           neighbor 10.255.251.1 peer group MLAG-IPv4-UNDERLAY-PEER
           neighbor 10.255.251.1 description DC1_LEAF1B
           neighbor 172.31.255.0 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.0 remote-as 65001
           neighbor 172.31.255.0 description DC1_SPINE1_Ethernet1
           neighbor 172.31.255.2 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.2 remote-as 65001
           neighbor 172.31.255.2 description DC1_SPINE2_Ethernet1
           neighbor 192.168.255.1 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.1 remote-as 65001
           neighbor 192.168.255.1 description DC1_SPINE1
           neighbor 192.168.255.2 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.2 remote-as 65001
           neighbor 192.168.255.2 description DC1_SPINE2
           redistribute connected route-map RM-CONN-2-BGP
           !
           vlan-aware-bundle Tenant_A_OP_Zone
              rd 192.168.255.3:10
              route-target both 10:10
              redistribute learned
              vlan 110-111
           !
           address-family evpn
              neighbor EVPN-OVERLAY-PEERS activate
           !
           address-family ipv4
              no neighbor EVPN-OVERLAY-PEERS activate
              neighbor IPv4-UNDERLAY-PEERS activate
              neighbor MLAG-IPv4-UNDERLAY-PEER activate
           !
           vrf Tenant_A_OP_Zone
              rd 192.168.255.3:10
              route-target import evpn 10:10
              route-target export evpn 10:10
              router-id 192.168.255.3
              neighbor 10.255.251.1 peer group MLAG-IPv4-UNDERLAY-PEER
              redistribute connected
        !
        management api http-commands
           protocol https
           protocol https ssl profile eAPI
           no shutdown
           !
           vrf MGMT
              no shutdown
        !
        management security
           ssl profile eAPI
              cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
              certificate eAPI.crt key eAPI.key
        !
        end
        ```

    === "DC1_LEAF1B.cfg"

        ```bash
        !RANCID-CONTENT-TYPE: arista
        !
        vlan internal order ascending range 1006 1199
        !
        transceiver qsfp default-mode 4x10G
        !
        service routing protocols model multi-agent
        !
        hostname DC1_LEAF1B
        ip name-server vrf MGMT 1.1.1.1
        ip name-server vrf MGMT 8.8.8.8
        !
        ntp server vrf MGMT time.google.com prefer iburst
        !
        spanning-tree mode mstp
        no spanning-tree vlan-id 4093-4094
        spanning-tree mst 0 priority 4096
        !
        no enable password
        no aaa root
        !
        username admin privilege 15 role network-admin secret sha512 $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        !
        vlan 110
           name Tenant_A_OP_Zone_1
        !
        vlan 111
           name Tenant_A_OP_Zone_2
        !
        vlan 3009
           name MLAG_iBGP_Tenant_A_OP_Zone
           trunk group LEAF_PEER_L3
        !
        vlan 4093
           name LEAF_PEER_L3
           trunk group LEAF_PEER_L3
        !
        vlan 4094
           name MLAG_PEER
           trunk group MLAG
        !
        vrf instance MGMT
        !
        vrf instance Tenant_A_OP_Zone
        !
        interface Port-Channel3
           description MLAG_PEER_DC1_LEAF1A_Po3
           no shutdown
           switchport
           switchport mode trunk
           switchport trunk group LEAF_PEER_L3
           switchport trunk group MLAG
        !
        interface Port-Channel5
           description server01_PortChannel5
           no shutdown
           switchport
           switchport trunk allowed vlan 110
           switchport mode trunk
           mlag 5
           spanning-tree portfast
        !
        interface Port-Channel6
           description server02_PortChannel6
           no shutdown
           switchport
           switchport trunk allowed vlan 111
           switchport mode trunk
           mlag 6
           spanning-tree portfast
        !
        interface Ethernet1
           description P2P_LINK_TO_DC1_SPINE1_Ethernet2
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.5/31
        !
        interface Ethernet2
           description P2P_LINK_TO_DC1_SPINE2_Ethernet2
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.7/31
        !
        interface Ethernet3
           description MLAG_PEER_DC1_LEAF1A_Ethernet3
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet4
           description MLAG_PEER_DC1_LEAF1A_Ethernet4
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet5
           description server01_Eth2
           no shutdown
           channel-group 5 mode active
        !
        interface Ethernet6
           description server02_Eth2
           no shutdown
           channel-group 6 mode active
        !
        interface Loopback0
           description EVPN_Overlay_Peering
           no shutdown
           ip address 192.168.255.4/32
        !
        interface Loopback1
           description VTEP_VXLAN_Tunnel_Source
           no shutdown
           ip address 192.168.254.3/32
        !
        interface Loopback100
           description Tenant_A_OP_Zone_VTEP_DIAGNOSTICS
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address 10.255.1.4/32
        !
        interface Management0
           description oob_management
           no shutdown
           vrf MGMT
           ip address 172.100.100.5/24
        !
        interface Vlan110
           description Tenant_A_OP_Zone_1
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address virtual 10.1.10.1/24
        !
        interface Vlan111
           description Tenant_A_OP_Zone_2
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address virtual 10.1.11.1/24
        !
        interface Vlan3009
           description MLAG_PEER_L3_iBGP: vrf Tenant_A_OP_Zone
           no shutdown
           mtu 9214
           vrf Tenant_A_OP_Zone
           ip address 10.255.251.1/31
        !
        interface Vlan4093
           description MLAG_PEER_L3_PEERING
           no shutdown
           mtu 9214
           ip address 10.255.251.1/31
        !
        interface Vlan4094
           description MLAG_PEER
           no shutdown
           mtu 9214
           no autostate
           ip address 10.255.252.1/31
        !
        interface Vxlan1
           description DC1_LEAF1B_VTEP
           vxlan source-interface Loopback1
           vxlan virtual-router encapsulation mac-address mlag-system-id
           vxlan udp-port 4789
           vxlan vlan 110 vni 10110
           vxlan vlan 111 vni 10111
           vxlan vrf Tenant_A_OP_Zone vni 10
        !
        ip virtual-router mac-address 00:00:00:00:00:01
        !
        ip address virtual source-nat vrf Tenant_A_OP_Zone address 10.255.1.4
        !
        ip routing
        no ip routing vrf MGMT
        ip routing vrf Tenant_A_OP_Zone
        !
        ip prefix-list PL-LOOPBACKS-EVPN-OVERLAY
           seq 10 permit 192.168.255.0/24 eq 32
           seq 20 permit 192.168.254.0/24 eq 32
        !
        mlag configuration
           domain-id DC1_LEAF1
           local-interface Vlan4094
           peer-address 10.255.252.0
           peer-link Port-Channel3
           reload-delay mlag 300
           reload-delay non-mlag 330
        !
        ip route vrf MGMT 0.0.0.0/0 172.100.100.1
        !
        route-map RM-CONN-2-BGP permit 10
           match ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        !
        route-map RM-MLAG-PEER-IN permit 10
           description Make routes learned over MLAG Peer-link less preferred on spines to ensure optimal routing
           set origin incomplete
        !
        router bfd
           multihop interval 300 min-rx 300 multiplier 3
        !
        router bgp 65101
           router-id 192.168.255.4
           distance bgp 20 200 200
           maximum-paths 4 ecmp 4
           no bgp default ipv4-unicast
           neighbor EVPN-OVERLAY-PEERS peer group
           neighbor EVPN-OVERLAY-PEERS update-source Loopback0
           neighbor EVPN-OVERLAY-PEERS bfd
           neighbor EVPN-OVERLAY-PEERS ebgp-multihop 3
           neighbor EVPN-OVERLAY-PEERS password 7 q+VNViP5i4rVjW1cxFv2wA==
           neighbor EVPN-OVERLAY-PEERS send-community
           neighbor EVPN-OVERLAY-PEERS maximum-routes 0
           neighbor IPv4-UNDERLAY-PEERS peer group
           neighbor IPv4-UNDERLAY-PEERS password 7 AQQvKeimxJu+uGQ/yYvv9w==
           neighbor IPv4-UNDERLAY-PEERS send-community
           neighbor IPv4-UNDERLAY-PEERS maximum-routes 12000
           neighbor MLAG-IPv4-UNDERLAY-PEER peer group
           neighbor MLAG-IPv4-UNDERLAY-PEER remote-as 65101
           neighbor MLAG-IPv4-UNDERLAY-PEER next-hop-self
           neighbor MLAG-IPv4-UNDERLAY-PEER description DC1_LEAF1A
           neighbor MLAG-IPv4-UNDERLAY-PEER password 7 vnEaG8gMeQf3d3cN6PktXQ==
           neighbor MLAG-IPv4-UNDERLAY-PEER send-community
           neighbor MLAG-IPv4-UNDERLAY-PEER maximum-routes 12000
           neighbor MLAG-IPv4-UNDERLAY-PEER route-map RM-MLAG-PEER-IN in
           neighbor 10.255.251.0 peer group MLAG-IPv4-UNDERLAY-PEER
           neighbor 10.255.251.0 description DC1_LEAF1A
           neighbor 172.31.255.4 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.4 remote-as 65001
           neighbor 172.31.255.4 description DC1_SPINE1_Ethernet2
           neighbor 172.31.255.6 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.6 remote-as 65001
           neighbor 172.31.255.6 description DC1_SPINE2_Ethernet2
           neighbor 192.168.255.1 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.1 remote-as 65001
           neighbor 192.168.255.1 description DC1_SPINE1
           neighbor 192.168.255.2 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.2 remote-as 65001
           neighbor 192.168.255.2 description DC1_SPINE2
           redistribute connected route-map RM-CONN-2-BGP
           !
           vlan-aware-bundle Tenant_A_OP_Zone
              rd 192.168.255.4:10
              route-target both 10:10
              redistribute learned
              vlan 110-111
           !
           address-family evpn
              neighbor EVPN-OVERLAY-PEERS activate
           !
           address-family ipv4
              no neighbor EVPN-OVERLAY-PEERS activate
              neighbor IPv4-UNDERLAY-PEERS activate
              neighbor MLAG-IPv4-UNDERLAY-PEER activate
           !
           vrf Tenant_A_OP_Zone
              rd 192.168.255.4:10
              route-target import evpn 10:10
              route-target export evpn 10:10
              router-id 192.168.255.4
              neighbor 10.255.251.0 peer group MLAG-IPv4-UNDERLAY-PEER
              redistribute connected
        !
        management api http-commands
           protocol https
           protocol https ssl profile eAPI
           no shutdown
           !
           vrf MGMT
              no shutdown
        !
        management security
           ssl profile eAPI
              cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
              certificate eAPI.crt key eAPI.key
        !
        end
        ```

    === "DC1_SVC2A.cfg"

        ```bash
        !RANCID-CONTENT-TYPE: arista
        !
        vlan internal order ascending range 1006 1199
        !
        transceiver qsfp default-mode 4x10G
        !
        service routing protocols model multi-agent
        !
        hostname DC1_SVC2A
        ip name-server vrf MGMT 1.1.1.1
        ip name-server vrf MGMT 8.8.8.8
        !
        ntp server vrf MGMT time.google.com prefer iburst
        !
        spanning-tree mode mstp
        no spanning-tree vlan-id 4093-4094
        spanning-tree mst 0 priority 4096
        !
        no enable password
        no aaa root
        !
        username admin privilege 15 role network-admin secret sha512 $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        !
        vlan 112
           name Tenant_A_OP_Zone_3
        !
        vlan 113
           name Tenant_A_OP_Zone_4
        !
        vlan 3009
           name MLAG_iBGP_Tenant_A_OP_Zone
           trunk group LEAF_PEER_L3
        !
        vlan 4093
           name LEAF_PEER_L3
           trunk group LEAF_PEER_L3
        !
        vlan 4094
           name MLAG_PEER
           trunk group MLAG
        !
        vrf instance MGMT
        !
        vrf instance Tenant_A_OP_Zone
        !
        interface Port-Channel3
           description MLAG_PEER_DC1_SVC2B_Po3
           no shutdown
           switchport
           switchport mode trunk
           switchport trunk group LEAF_PEER_L3
           switchport trunk group MLAG
        !
        interface Port-Channel5
           description DC1_L2_LEAF_Po1
           no shutdown
           switchport
           switchport trunk allowed vlan 112-113
           switchport mode trunk
           mlag 5
        !
        interface Ethernet1
           description P2P_LINK_TO_DC1_SPINE1_Ethernet3
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.9/31
        !
        interface Ethernet2
           description P2P_LINK_TO_DC1_SPINE2_Ethernet3
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.11/31
        !
        interface Ethernet3
           description MLAG_PEER_DC1_SVC2B_Ethernet3
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet4
           description MLAG_PEER_DC1_SVC2B_Ethernet4
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet5
           description DC1_L2_LEAF2A_Ethernet1
           no shutdown
           channel-group 5 mode active
        !
        interface Ethernet6
           description DC1_L2_LEAF2B_Ethernet1
           no shutdown
           channel-group 5 mode active
        !
        interface Loopback0
           description EVPN_Overlay_Peering
           no shutdown
           ip address 192.168.255.5/32
        !
        interface Loopback1
           description VTEP_VXLAN_Tunnel_Source
           no shutdown
           ip address 192.168.254.5/32
        !
        interface Loopback100
           description Tenant_A_OP_Zone_VTEP_DIAGNOSTICS
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address 10.255.1.5/32
        !
        interface Management0
           description oob_management
           no shutdown
           vrf MGMT
           ip address 172.100.100.6/24
        !
        interface Vlan112
           description Tenant_A_OP_Zone_3
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address virtual 10.1.12.1/24
        !
        interface Vlan113
           description Tenant_A_OP_Zone_4
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address virtual 10.1.13.1/24
        !
        interface Vlan3009
           description MLAG_PEER_L3_iBGP: vrf Tenant_A_OP_Zone
           no shutdown
           mtu 9214
           vrf Tenant_A_OP_Zone
           ip address 10.255.251.4/31
        !
        interface Vlan4093
           description MLAG_PEER_L3_PEERING
           no shutdown
           mtu 9214
           ip address 10.255.251.4/31
        !
        interface Vlan4094
           description MLAG_PEER
           no shutdown
           mtu 9214
           no autostate
           ip address 10.255.252.4/31
        !
        interface Vxlan1
           description DC1_SVC2A_VTEP
           vxlan source-interface Loopback1
           vxlan virtual-router encapsulation mac-address mlag-system-id
           vxlan udp-port 4789
           vxlan vlan 112 vni 10112
           vxlan vlan 113 vni 10113
           vxlan vrf Tenant_A_OP_Zone vni 10
        !
        ip virtual-router mac-address 00:00:00:00:00:01
        !
        ip address virtual source-nat vrf Tenant_A_OP_Zone address 10.255.1.5
        !
        ip routing
        no ip routing vrf MGMT
        ip routing vrf Tenant_A_OP_Zone
        !
        ip prefix-list PL-LOOPBACKS-EVPN-OVERLAY
           seq 10 permit 192.168.255.0/24 eq 32
           seq 20 permit 192.168.254.0/24 eq 32
        !
        mlag configuration
           domain-id DC1_SVC2
           local-interface Vlan4094
           peer-address 10.255.252.5
           peer-link Port-Channel3
           reload-delay mlag 300
           reload-delay non-mlag 330
        !
        ip route vrf MGMT 0.0.0.0/0 172.100.100.1
        !
        route-map RM-CONN-2-BGP permit 10
           match ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        !
        route-map RM-MLAG-PEER-IN permit 10
           description Make routes learned over MLAG Peer-link less preferred on spines to ensure optimal routing
           set origin incomplete
        !
        router bfd
           multihop interval 300 min-rx 300 multiplier 3
        !
        router bgp 65102
           router-id 192.168.255.5
           distance bgp 20 200 200
           maximum-paths 4 ecmp 4
           no bgp default ipv4-unicast
           neighbor EVPN-OVERLAY-PEERS peer group
           neighbor EVPN-OVERLAY-PEERS update-source Loopback0
           neighbor EVPN-OVERLAY-PEERS bfd
           neighbor EVPN-OVERLAY-PEERS ebgp-multihop 3
           neighbor EVPN-OVERLAY-PEERS password 7 q+VNViP5i4rVjW1cxFv2wA==
           neighbor EVPN-OVERLAY-PEERS send-community
           neighbor EVPN-OVERLAY-PEERS maximum-routes 0
           neighbor IPv4-UNDERLAY-PEERS peer group
           neighbor IPv4-UNDERLAY-PEERS password 7 AQQvKeimxJu+uGQ/yYvv9w==
           neighbor IPv4-UNDERLAY-PEERS send-community
           neighbor IPv4-UNDERLAY-PEERS maximum-routes 12000
           neighbor MLAG-IPv4-UNDERLAY-PEER peer group
           neighbor MLAG-IPv4-UNDERLAY-PEER remote-as 65102
           neighbor MLAG-IPv4-UNDERLAY-PEER next-hop-self
           neighbor MLAG-IPv4-UNDERLAY-PEER description DC1_SVC2B
           neighbor MLAG-IPv4-UNDERLAY-PEER password 7 vnEaG8gMeQf3d3cN6PktXQ==
           neighbor MLAG-IPv4-UNDERLAY-PEER send-community
           neighbor MLAG-IPv4-UNDERLAY-PEER maximum-routes 12000
           neighbor MLAG-IPv4-UNDERLAY-PEER route-map RM-MLAG-PEER-IN in
           neighbor 10.255.251.5 peer group MLAG-IPv4-UNDERLAY-PEER
           neighbor 10.255.251.5 description DC1_SVC2B
           neighbor 172.31.255.8 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.8 remote-as 65001
           neighbor 172.31.255.8 description DC1_SPINE1_Ethernet3
           neighbor 172.31.255.10 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.10 remote-as 65001
           neighbor 172.31.255.10 description DC1_SPINE2_Ethernet3
           neighbor 192.168.255.1 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.1 remote-as 65001
           neighbor 192.168.255.1 description DC1_SPINE1
           neighbor 192.168.255.2 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.2 remote-as 65001
           neighbor 192.168.255.2 description DC1_SPINE2
           redistribute connected route-map RM-CONN-2-BGP
           !
           vlan-aware-bundle Tenant_A_OP_Zone
              rd 192.168.255.5:10
              route-target both 10:10
              redistribute learned
              vlan 112-113
           !
           address-family evpn
              neighbor EVPN-OVERLAY-PEERS activate
           !
           address-family ipv4
              no neighbor EVPN-OVERLAY-PEERS activate
              neighbor IPv4-UNDERLAY-PEERS activate
              neighbor MLAG-IPv4-UNDERLAY-PEER activate
           !
           vrf Tenant_A_OP_Zone
              rd 192.168.255.5:10
              route-target import evpn 10:10
              route-target export evpn 10:10
              router-id 192.168.255.5
              neighbor 10.255.251.5 peer group MLAG-IPv4-UNDERLAY-PEER
              redistribute connected
        !
        management api http-commands
           protocol https
           protocol https ssl profile eAPI
           no shutdown
           !
           vrf MGMT
              no shutdown
        !
        management security
           ssl profile eAPI
              cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
              certificate eAPI.crt key eAPI.key
        !
        end
        ```

    === "DC1_SVC2B.cfg"

        ```bash
        !RANCID-CONTENT-TYPE: arista
        !
        vlan internal order ascending range 1006 1199
        !
        transceiver qsfp default-mode 4x10G
        !
        service routing protocols model multi-agent
        !
        hostname DC1_SVC2B
        ip name-server vrf MGMT 1.1.1.1
        ip name-server vrf MGMT 8.8.8.8
        !
        ntp server vrf MGMT time.google.com prefer iburst
        !
        spanning-tree mode mstp
        no spanning-tree vlan-id 4093-4094
        spanning-tree mst 0 priority 4096
        !
        no enable password
        no aaa root
        !
        username admin privilege 15 role network-admin secret sha512 $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        !
        vlan 112
           name Tenant_A_OP_Zone_3
        !
        vlan 113
           name Tenant_A_OP_Zone_4
        !
        vlan 3009
           name MLAG_iBGP_Tenant_A_OP_Zone
           trunk group LEAF_PEER_L3
        !
        vlan 4093
           name LEAF_PEER_L3
           trunk group LEAF_PEER_L3
        !
        vlan 4094
           name MLAG_PEER
           trunk group MLAG
        !
        vrf instance MGMT
        !
        vrf instance Tenant_A_OP_Zone
        !
        interface Port-Channel3
           description MLAG_PEER_DC1_SVC2A_Po3
           no shutdown
           switchport
           switchport mode trunk
           switchport trunk group LEAF_PEER_L3
           switchport trunk group MLAG
        !
        interface Port-Channel5
           description DC1_L2_LEAF_Po1
           no shutdown
           switchport
           switchport trunk allowed vlan 112-113
           switchport mode trunk
           mlag 5
        !
        interface Ethernet1
           description P2P_LINK_TO_DC1_SPINE1_Ethernet4
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.13/31
        !
        interface Ethernet2
           description P2P_LINK_TO_DC1_SPINE2_Ethernet4
           no shutdown
           mtu 9214
           no switchport
           ip address 172.31.255.15/31
        !
        interface Ethernet3
           description MLAG_PEER_DC1_SVC2A_Ethernet3
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet4
           description MLAG_PEER_DC1_SVC2A_Ethernet4
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet5
           description DC1_L2_LEAF2A_Ethernet2
           no shutdown
           channel-group 5 mode active
        !
        interface Ethernet6
           description DC1_L2_LEAF2B_Ethernet2
           no shutdown
           channel-group 5 mode active
        !
        interface Loopback0
           description EVPN_Overlay_Peering
           no shutdown
           ip address 192.168.255.6/32
        !
        interface Loopback1
           description VTEP_VXLAN_Tunnel_Source
           no shutdown
           ip address 192.168.254.5/32
        !
        interface Loopback100
           description Tenant_A_OP_Zone_VTEP_DIAGNOSTICS
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address 10.255.1.6/32
        !
        interface Management0
           description oob_management
           no shutdown
           vrf MGMT
           ip address 172.100.100.7/24
        !
        interface Vlan112
           description Tenant_A_OP_Zone_3
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address virtual 10.1.12.1/24
        !
        interface Vlan113
           description Tenant_A_OP_Zone_4
           no shutdown
           vrf Tenant_A_OP_Zone
           ip address virtual 10.1.13.1/24
        !
        interface Vlan3009
           description MLAG_PEER_L3_iBGP: vrf Tenant_A_OP_Zone
           no shutdown
           mtu 9214
           vrf Tenant_A_OP_Zone
           ip address 10.255.251.5/31
        !
        interface Vlan4093
           description MLAG_PEER_L3_PEERING
           no shutdown
           mtu 9214
           ip address 10.255.251.5/31
        !
        interface Vlan4094
           description MLAG_PEER
           no shutdown
           mtu 9214
           no autostate
           ip address 10.255.252.5/31
        !
        interface Vxlan1
           description DC1_SVC2B_VTEP
           vxlan source-interface Loopback1
           vxlan virtual-router encapsulation mac-address mlag-system-id
           vxlan udp-port 4789
           vxlan vlan 112 vni 10112
           vxlan vlan 113 vni 10113
           vxlan vrf Tenant_A_OP_Zone vni 10
        !
        ip virtual-router mac-address 00:00:00:00:00:01
        !
        ip address virtual source-nat vrf Tenant_A_OP_Zone address 10.255.1.6
        !
        ip routing
        no ip routing vrf MGMT
        ip routing vrf Tenant_A_OP_Zone
        !
        ip prefix-list PL-LOOPBACKS-EVPN-OVERLAY
           seq 10 permit 192.168.255.0/24 eq 32
           seq 20 permit 192.168.254.0/24 eq 32
        !
        mlag configuration
           domain-id DC1_SVC2
           local-interface Vlan4094
           peer-address 10.255.252.4
           peer-link Port-Channel3
           reload-delay mlag 300
           reload-delay non-mlag 330
        !
        ip route vrf MGMT 0.0.0.0/0 172.100.100.1
        !
        route-map RM-CONN-2-BGP permit 10
           match ip address prefix-list PL-LOOPBACKS-EVPN-OVERLAY
        !
        route-map RM-MLAG-PEER-IN permit 10
           description Make routes learned over MLAG Peer-link less preferred on spines to ensure optimal routing
           set origin incomplete
        !
        router bfd
           multihop interval 300 min-rx 300 multiplier 3
        !
        router bgp 65102
           router-id 192.168.255.6
           distance bgp 20 200 200
           maximum-paths 4 ecmp 4
           no bgp default ipv4-unicast
           neighbor EVPN-OVERLAY-PEERS peer group
           neighbor EVPN-OVERLAY-PEERS update-source Loopback0
           neighbor EVPN-OVERLAY-PEERS bfd
           neighbor EVPN-OVERLAY-PEERS ebgp-multihop 3
           neighbor EVPN-OVERLAY-PEERS password 7 q+VNViP5i4rVjW1cxFv2wA==
           neighbor EVPN-OVERLAY-PEERS send-community
           neighbor EVPN-OVERLAY-PEERS maximum-routes 0
           neighbor IPv4-UNDERLAY-PEERS peer group
           neighbor IPv4-UNDERLAY-PEERS password 7 AQQvKeimxJu+uGQ/yYvv9w==
           neighbor IPv4-UNDERLAY-PEERS send-community
           neighbor IPv4-UNDERLAY-PEERS maximum-routes 12000
           neighbor MLAG-IPv4-UNDERLAY-PEER peer group
           neighbor MLAG-IPv4-UNDERLAY-PEER remote-as 65102
           neighbor MLAG-IPv4-UNDERLAY-PEER next-hop-self
           neighbor MLAG-IPv4-UNDERLAY-PEER description DC1_SVC2A
           neighbor MLAG-IPv4-UNDERLAY-PEER password 7 vnEaG8gMeQf3d3cN6PktXQ==
           neighbor MLAG-IPv4-UNDERLAY-PEER send-community
           neighbor MLAG-IPv4-UNDERLAY-PEER maximum-routes 12000
           neighbor MLAG-IPv4-UNDERLAY-PEER route-map RM-MLAG-PEER-IN in
           neighbor 10.255.251.4 peer group MLAG-IPv4-UNDERLAY-PEER
           neighbor 10.255.251.4 description DC1_SVC2A
           neighbor 172.31.255.12 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.12 remote-as 65001
           neighbor 172.31.255.12 description DC1_SPINE1_Ethernet4
           neighbor 172.31.255.14 peer group IPv4-UNDERLAY-PEERS
           neighbor 172.31.255.14 remote-as 65001
           neighbor 172.31.255.14 description DC1_SPINE2_Ethernet4
           neighbor 192.168.255.1 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.1 remote-as 65001
           neighbor 192.168.255.1 description DC1_SPINE1
           neighbor 192.168.255.2 peer group EVPN-OVERLAY-PEERS
           neighbor 192.168.255.2 remote-as 65001
           neighbor 192.168.255.2 description DC1_SPINE2
           redistribute connected route-map RM-CONN-2-BGP
           !
           vlan-aware-bundle Tenant_A_OP_Zone
              rd 192.168.255.6:10
              route-target both 10:10
              redistribute learned
              vlan 112-113
           !
           address-family evpn
              neighbor EVPN-OVERLAY-PEERS activate
           !
           address-family ipv4
              no neighbor EVPN-OVERLAY-PEERS activate
              neighbor IPv4-UNDERLAY-PEERS activate
              neighbor MLAG-IPv4-UNDERLAY-PEER activate
           !
           vrf Tenant_A_OP_Zone
              rd 192.168.255.6:10
              route-target import evpn 10:10
              route-target export evpn 10:10
              router-id 192.168.255.6
              neighbor 10.255.251.4 peer group MLAG-IPv4-UNDERLAY-PEER
              redistribute connected
        !
        management api http-commands
           protocol https
           protocol https ssl profile eAPI
           no shutdown
           !
           vrf MGMT
              no shutdown
        !
        management security
           ssl profile eAPI
              cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
              certificate eAPI.crt key eAPI.key
        !
        end
        ```

    === "DC1_L2_LEAF2A.cfg"

        ```bash
        !RANCID-CONTENT-TYPE: arista
        !
        vlan internal order ascending range 1006 1199
        !
        transceiver qsfp default-mode 4x10G
        !
        service routing protocols model multi-agent
        !
        hostname DC1_L2_LEAF2A
        ip name-server vrf MGMT 1.1.1.1
        ip name-server vrf MGMT 8.8.8.8
        !
        ntp server vrf MGMT time.google.com prefer iburst
        !
        spanning-tree mode mstp
        no spanning-tree vlan-id 4094
        spanning-tree mst 0 priority 16384
        !
        no enable password
        no aaa root
        !
        username admin privilege 15 role network-admin secret sha512 $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        !
        vlan 112
           name Tenant_A_OP_Zone_3
        !
        vlan 113
           name Tenant_A_OP_Zone_4
        !
        vlan 4094
           name MLAG_PEER
           trunk group MLAG
        !
        vrf instance MGMT
        !
        interface Port-Channel1
           description DC1_SVC2_Po5
           no shutdown
           switchport
           switchport trunk allowed vlan 112-113
           switchport mode trunk
           mlag 1
        !
        interface Port-Channel3
           description MLAG_PEER_DC1_L2_LEAF2B_Po3
           no shutdown
           switchport
           switchport mode trunk
           switchport trunk group MLAG
        !
        interface Port-Channel5
           description server03_PortChannel5
           no shutdown
           switchport
           switchport trunk allowed vlan 112
           switchport mode trunk
           mlag 5
           spanning-tree portfast
        !
        interface Port-Channel6
           description server04_PortChannel6
           no shutdown
           switchport
           switchport trunk allowed vlan 113
           switchport mode trunk
           mlag 6
           spanning-tree portfast
        !
        interface Ethernet1
           description DC1_SVC2A_Ethernet5
           no shutdown
           channel-group 1 mode active
        !
        interface Ethernet2
           description DC1_SVC2B_Ethernet5
           no shutdown
           channel-group 1 mode active
        !
        interface Ethernet3
           description MLAG_PEER_DC1_L2_LEAF2B_Ethernet3
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet4
           description MLAG_PEER_DC1_L2_LEAF2B_Ethernet4
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet5
           description server03_Eth1
           no shutdown
           channel-group 5 mode active
        !
        interface Ethernet6
           description server04_Eth1
           no shutdown
           channel-group 6 mode active
        !
        interface Management0
           description oob_management
           no shutdown
           vrf MGMT
           ip address 172.100.100.8/24
        !
        interface Vlan4094
           description MLAG_PEER
           no shutdown
           mtu 9214
           no autostate
           ip address 10.255.252.8/31
        !
        ip routing
        no ip routing vrf MGMT
        !
        mlag configuration
           domain-id DC1_L2_LEAF
           local-interface Vlan4094
           peer-address 10.255.252.9
           peer-link Port-Channel3
           reload-delay mlag 300
           reload-delay non-mlag 330
        !
        ip route vrf MGMT 0.0.0.0/0 172.100.100.1
        !
        management api http-commands
           protocol https
           protocol https ssl profile eAPI
           no shutdown
           !
           vrf MGMT
              no shutdown
        !
        management security
           ssl profile eAPI
              cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
              certificate eAPI.crt key eAPI.key
        !
        end
        ```

    === "DC1_L2_LEAF2B.cfg"

        ```bash
        !RANCID-CONTENT-TYPE: arista
        !
        vlan internal order ascending range 1006 1199
        !
        transceiver qsfp default-mode 4x10G
        !
        service routing protocols model multi-agent
        !
        hostname DC1_L2_LEAF2B
        ip name-server vrf MGMT 1.1.1.1
        ip name-server vrf MGMT 8.8.8.8
        !
        ntp server vrf MGMT time.google.com prefer iburst
        !
        spanning-tree mode mstp
        no spanning-tree vlan-id 4094
        spanning-tree mst 0 priority 16384
        !
        no enable password
        no aaa root
        !
        username admin privilege 15 role network-admin secret sha512 $6$7GTxsrRjnwheeKfR$zhJ8qycVjAJz41rf5JRSfWIzp93IL5WL7sMS/Taz1yfShz.MAnoajCf7R2n1/EZW7PN5QA3Huayl0lVQesBYN1
        !
        vlan 112
           name Tenant_A_OP_Zone_3
        !
        vlan 113
           name Tenant_A_OP_Zone_4
        !
        vlan 4094
           name MLAG_PEER
           trunk group MLAG
        !
        vrf instance MGMT
        !
        interface Port-Channel1
           description DC1_SVC2_Po5
           no shutdown
           switchport
           switchport trunk allowed vlan 112-113
           switchport mode trunk
           mlag 1
        !
        interface Port-Channel3
           description MLAG_PEER_DC1_L2_LEAF2A_Po3
           no shutdown
           switchport
           switchport mode trunk
           switchport trunk group MLAG
        !
        interface Port-Channel5
           description server03_PortChannel5
           no shutdown
           switchport
           switchport trunk allowed vlan 112
           switchport mode trunk
           mlag 5
           spanning-tree portfast
        !
        interface Port-Channel6
           description server04_PortChannel6
           no shutdown
           switchport
           switchport trunk allowed vlan 113
           switchport mode trunk
           mlag 6
           spanning-tree portfast
        !
        interface Ethernet1
           description DC1_SVC2A_Ethernet6
           no shutdown
           channel-group 1 mode active
        !
        interface Ethernet2
           description DC1_SVC2B_Ethernet6
           no shutdown
           channel-group 1 mode active
        !
        interface Ethernet3
           description MLAG_PEER_DC1_L2_LEAF2A_Ethernet3
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet4
           description MLAG_PEER_DC1_L2_LEAF2A_Ethernet4
           no shutdown
           channel-group 3 mode active
        !
        interface Ethernet5
           description server03_Eth2
           no shutdown
           channel-group 5 mode active
        !
        interface Ethernet6
           description server04_Eth2
           no shutdown
           channel-group 6 mode active
        !
        interface Management0
           description oob_management
           no shutdown
           vrf MGMT
           ip address 172.100.100.9/24
        !
        interface Vlan4094
           description MLAG_PEER
           no shutdown
           mtu 9214
           no autostate
           ip address 10.255.252.9/31
        !
        ip routing
        no ip routing vrf MGMT
        !
        mlag configuration
           domain-id DC1_L2_LEAF
           local-interface Vlan4094
           peer-address 10.255.252.8
           peer-link Port-Channel3
           reload-delay mlag 300
           reload-delay non-mlag 330
        !
        ip route vrf MGMT 0.0.0.0/0 172.100.100.1
        !
        management api http-commands
           protocol https
           protocol https ssl profile eAPI
           no shutdown
           !
           vrf MGMT
              no shutdown
        !
        management security
           ssl profile eAPI
              cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
              certificate eAPI.crt key eAPI.key
        !
        end
        ```

* From the fourth task in the playbook which uses `arista.avd.eos_config_deploy_eapi` the configuration is deployed directly to cEOS-lab nodes using eAPI.

## Configuring end hosts

???+ info
    The below steps are only applicable if using default alpine-host containers as clients / end hosts.

* Run the `host_l3_config/l3_build.sh` script to configure the following on the alpine-host end clients.
    * [x] bond interface
    * [x] Client IP address
    * [x] Gateway IP and static route

```bash
bash host_l3_config/l3_build.sh
```

??? "Reveal Output"

    ```bash
    [INFO] Configuring clab-avdirb-client1
    client1
    team0.110 Link encap:Ethernet  HWaddr AA:C1:AB:27:F2:6C
              inet addr:10.1.10.101  Bcast:10.1.10.255  Mask:255.255.255.0
              inet6 addr: fe80::a8c1:abff:fe27:f26c/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:1 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:90 (90.0 B)

    Kernel IP routing table
    Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
    0.0.0.0         172.100.100.1   0.0.0.0         UG    0      0        0 eth0
    10.1.0.0        10.1.10.1       255.255.0.0     UG    0      0        0 team0.110
    10.1.10.0       0.0.0.0         255.255.255.0   U     0      0        0 team0.110
    172.100.100.0   0.0.0.0         255.255.255.0   U     0      0        0 eth0
    [INFO] Configuring clab-avdirb-client2
    client2
    team0.111 Link encap:Ethernet  HWaddr AA:C1:AB:72:02:D1
              inet addr:10.1.11.102  Bcast:10.1.11.255  Mask:255.255.255.0
              inet6 addr: fe80::a8c1:abff:fe72:2d1/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:1 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:90 (90.0 B)

    Kernel IP routing table
    Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
    0.0.0.0         172.100.100.1   0.0.0.0         UG    0      0        0 eth0
    10.1.0.0        10.1.11.1       255.255.0.0     UG    0      0        0 team0.111
    10.1.11.0       0.0.0.0         255.255.255.0   U     0      0        0 team0.111
    172.100.100.0   0.0.0.0         255.255.255.0   U     0      0        0 eth0
    [INFO] Configuring clab-avdirb-client3
    client3
    team0.112 Link encap:Ethernet  HWaddr AA:C1:AB:E6:20:F5
              inet addr:10.1.12.103  Bcast:10.1.12.255  Mask:255.255.255.0
              inet6 addr: fe80::a8c1:abff:fee6:20f5/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:1 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:90 (90.0 B)

    Kernel IP routing table
    Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
    0.0.0.0         172.100.100.1   0.0.0.0         UG    0      0        0 eth0
    10.1.0.0        10.1.12.1       255.255.0.0     UG    0      0        0 team0.112
    10.1.12.0       0.0.0.0         255.255.255.0   U     0      0        0 team0.112
    172.100.100.0   0.0.0.0         255.255.255.0   U     0      0        0 eth0
    [INFO] Configuring clab-avdirb-client4
    client4
    team0.113 Link encap:Ethernet  HWaddr AA:C1:AB:0E:06:7D
              inet addr:10.1.13.104  Bcast:10.1.13.255  Mask:255.255.255.0
              inet6 addr: fe80::a8c1:abff:fe0e:67d/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:1 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:90 (90.0 B)

    Kernel IP routing table
    Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
    0.0.0.0         172.100.100.1   0.0.0.0         UG    0      0        0 eth0
    10.1.0.0        10.1.13.1       255.255.0.0     UG    0      0        0 team0.113
    10.1.13.0       0.0.0.0         255.255.255.0   U     0      0        0 team0.113
    172.100.100.0   0.0.0.0         255.255.255.0   U     0      0        0 eth0
    [INFO] Completed
    Use [ docker exec -it clab-avdirb-client<x> /bin/sh ] to login in host.
    ```

## Deployment Validation

* Once the configuration is complete, let's validate the states of the devices in the topology.
* Login to the cEOS-lab node using SSH or `docker exec`

=== "SSH"

    ```bash
    ssh admin@172.100.100.2
    ```

=== "docker exec"

    ```bash
    docker exec -it clab-avdirb-spine1 Cli
    ```

??? success "Underlay BGP Peering"

    === "DC1_SPINE1"

        ```bash
        DC1_SPINE1#show ip bgp summary
        BGP summary information for VRF default
        Router identifier 192.168.255.1, local AS number 65001
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor      V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_LEAF1A_Ethernet1     172.31.255.1  4 65101            133       130    0    0 01:46:04 Estab   3      3
          DC1_LEAF1B_Ethernet1     172.31.255.5  4 65101            130       134    0    0 01:46:02 Estab   3      3
          DC1_SVC2A_Ethernet1      172.31.255.9  4 65102            131       134    0    0 01:46:02 Estab   3      3
          DC1_SVC2B_Ethernet1      172.31.255.13 4 65102            131       130    0    0 01:46:02 Estab   3      3
        ```

    === "DC1_SPINE2"

        ```bash
        DC1_SPINE2#show ip bgp summary
        BGP summary information for VRF default
        Router identifier 192.168.255.2, local AS number 65001
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor      V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_LEAF1A_Ethernet2     172.31.255.3  4 65101            132       133    0    0 01:46:55 Estab   3      3
          DC1_LEAF1B_Ethernet2     172.31.255.7  4 65101            133       133    0    0 01:46:52 Estab   3      3
          DC1_SVC2A_Ethernet2      172.31.255.11 4 65102            133       133    0    0 01:46:52 Estab   3      3
          DC1_SVC2B_Ethernet2      172.31.255.15 4 65102            134       132    0    0 01:46:52 Estab   3      3
        ```

    === "DC1_LEAF1A"

        ```bash
        DC1_LEAF1A#show ip bgp summary
        BGP summary information for VRF default
        Router identifier 192.168.255.3, local AS number 65101
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor     V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_LEAF1B               10.255.251.1 4 65101            132       133    0    0 01:48:20 Estab   7      7
          DC1_SPINE1_Ethernet1     172.31.255.0 4 65001            133       136    0    0 01:48:24 Estab   4      4
          DC1_SPINE2_Ethernet1     172.31.255.2 4 65001            135       134    0    0 01:48:25 Estab   4      4
        ```
    
    === "DC1_LEAF1B"

        ```bash
        DC1_LEAF1B#show ip bgp summary
        BGP summary information for VRF default
        Router identifier 192.168.255.4, local AS number 65101
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor     V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_LEAF1A               10.255.251.0 4 65101            134       134    0    0 01:49:18 Estab   7      7
          DC1_SPINE1_Ethernet2     172.31.255.4 4 65001            137       134    0    0 01:49:20 Estab   4      4
          DC1_SPINE2_Ethernet2     172.31.255.6 4 65001            136       136    0    0 01:49:20 Estab   4      4
        ```
    
    === "DC1_SVC2A"

        ```bash
        DC1_SVC2A#show ip bgp summary
        BGP summary information for VRF default
        Router identifier 192.168.255.5, local AS number 65102
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor      V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_SVC2B                10.255.251.5  4 65102            134       136    0    0 01:49:44 Estab   7      7
          DC1_SPINE1_Ethernet3     172.31.255.8  4 65001            138       136    0    0 01:49:47 Estab   4      4
          DC1_SPINE2_Ethernet3     172.31.255.10 4 65001            137       136    0    0 01:49:47 Estab   4      4
        ```

    === "DC1_SVC2B"

        ```bash
        DC1_SVC2B#show ip bgp summary
        BGP summary information for VRF default
        Router identifier 192.168.255.6, local AS number 65102
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor      V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_SVC2A                10.255.251.4  4 65102            137       134    0    0 01:49:54 Estab   7      7
          DC1_SPINE1_Ethernet4     172.31.255.12 4 65001            135       135    0    0 01:49:57 Estab   4      4
          DC1_SPINE2_Ethernet4     172.31.255.14 4 65001            136       138    0    0 01:49:57 Estab   4      4
        ```

??? success "Overlay EVPN Peering"

    === "DC1_SPINE1"

        ```bash
        DC1_SPINE1>show bgp evpn summary
        BGP summary information for VRF default
        Router identifier 192.168.255.1, local AS number 65001
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor      V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_LEAF1A               192.168.255.3 4 65101            162       166    0    0 01:48:35 Estab   7      7
          DC1_LEAF1B               192.168.255.4 4 65101            163       166    0    0 01:48:31 Estab   7      7
          DC1_SVC2A                192.168.255.5 4 65102            159       167    0    0 01:48:31 Estab   7      7
          DC1_SVC2B                192.168.255.6 4 65102            160       164    0    0 01:48:31 Estab   7      7
        ```

    === "DC1_SPINE2"

        ```bash
        DC1_SPINE2>show bgp evpn summary
        BGP summary information for VRF default
        Router identifier 192.168.255.2, local AS number 65001
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor      V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_LEAF1A               192.168.255.3 4 65101            162       165    0    0 01:48:59 Estab   7      7
          DC1_LEAF1B               192.168.255.4 4 65101            159       166    0    0 01:48:55 Estab   7      7
          DC1_SVC2A                192.168.255.5 4 65102            154       164    0    0 01:48:55 Estab   7      7
          DC1_SVC2B                192.168.255.6 4 65102            153       164    0    0 01:48:55 Estab   7      7
        ```

    === "DC1_LEAF1A"

        ```bash
        DC1_LEAF1A>show bgp evpn summary
        BGP summary information for VRF default
        Router identifier 192.168.255.3, local AS number 65101
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor      V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_SPINE1               192.168.255.1 4 65001            166       163    0    0 01:49:19 Estab   14     14
          DC1_SPINE2               192.168.255.2 4 65001            166       163    0    0 01:49:20 Estab   14     14
        ```
    
    === "DC1_LEAF1B"

        ```bash
        DC1_LEAF1B>show bgp evpn summary
        BGP summary information for VRF default
        Router identifier 192.168.255.4, local AS number 65101
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor      V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_SPINE1               192.168.255.1 4 65001            167       165    0    0 01:49:39 Estab   14     14
          DC1_SPINE2               192.168.255.2 4 65001            167       160    0    0 01:49:39 Estab   14     14
        ```
    
    === "DC1_SVC2A"

        ```bash
        DC1_SVC2A>show bgp evpn summary
        BGP summary information for VRF default
        Router identifier 192.168.255.5, local AS number 65102
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor      V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_SPINE1               192.168.255.1 4 65001            169       161    0    0 01:50:05 Estab   14     14
          DC1_SPINE2               192.168.255.2 4 65001            165       155    0    0 01:50:05 Estab   14     14
        ```

    === "DC1_SVC2B"

        ```bash
        DC1_SVC2B>show bgp evpn summary
        BGP summary information for VRF default
        Router identifier 192.168.255.6, local AS number 65102
        Neighbor Status Codes: m - Under maintenance
          Description              Neighbor      V AS           MsgRcvd   MsgSent  InQ OutQ  Up/Down State   PfxRcd PfxAcc
          DC1_SPINE1               192.168.255.1 4 65001            166       162    0    0 01:50:22 Estab   14     14
          DC1_SPINE2               192.168.255.2 4 65001            166       155    0    0 01:50:22 Estab   14     14
        ```

??? success "MLAG"

    === "DC1_LEAF1A"

        ```bash hl_lines="1 26"
        DC1_LEAF1A>show mlag
        MLAG Configuration:
        domain-id                          :           DC1_LEAF1
        local-interface                    :            Vlan4094
        peer-address                       :        10.255.252.1
        peer-link                          :       Port-Channel3
        peer-config                        :          consistent
        
        MLAG Status:
        state                              :              Active
        negotiation status                 :           Connected
        peer-link status                   :                  Up
        local-int status                   :                  Up
        system-id                          :   02:1c:73:57:aa:63
        dual-primary detection             :            Disabled
        dual-primary interface errdisabled :               False
        
        MLAG Ports:
        Disabled                           :                   0
        Configured                         :                   0
        Inactive                           :                   0
        Active-partial                     :                   0
        Active-full                        :                   2
        
        DC1_LEAF1A>
        DC1_LEAF1A>show mlag interfaces
                                                                                          local/remote
           mlag       desc                              state       local       remote          status
        ---------- --------------------------- ----------------- ----------- ------------ ------------
              5       server01_PortChannel5       active-full         Po5          Po5           up/up
              6       server02_PortChannel6       active-full         Po6          Po6           up/up
        ```
    
    === "DC1_LEAF1B"

        ```bash hl_lines="1 26"
        DC1_LEAF1B>show mlag
        MLAG Configuration:
        domain-id                          :           DC1_LEAF1
        local-interface                    :            Vlan4094
        peer-address                       :        10.255.252.0
        peer-link                          :       Port-Channel3
        peer-config                        :          consistent

        MLAG Status:
        state                              :              Active
        negotiation status                 :           Connected
        peer-link status                   :                  Up
        local-int status                   :                  Up
        system-id                          :   02:1c:73:57:aa:63
        dual-primary detection             :            Disabled
        dual-primary interface errdisabled :               False

        MLAG Ports:
        Disabled                           :                   0
        Configured                         :                   0
        Inactive                           :                   0
        Active-partial                     :                   0
        Active-full                        :                   2

        DC1_LEAF1B>
        DC1_LEAF1B>show mlag interfaces
                                                                                          local/remote
           mlag       desc                              state       local       remote          status
        ---------- --------------------------- ----------------- ----------- ------------ ------------
              5       server01_PortChannel5       active-full         Po5          Po5           up/up
              6       server02_PortChannel6       active-full         Po6          Po6           up/up
        ```
    
    === "DC1_SVC2A"

        ```bash hl_lines="1 26"
        DC1_SVC2A>show mlag
        MLAG Configuration:
        domain-id                          :            DC1_SVC2
        local-interface                    :            Vlan4094
        peer-address                       :        10.255.252.5
        peer-link                          :       Port-Channel3
        peer-config                        :          consistent

        MLAG Status:
        state                              :              Active
        negotiation status                 :           Connected
        peer-link status                   :                  Up
        local-int status                   :                  Up
        system-id                          :   02:1c:73:01:0d:2d
        dual-primary detection             :            Disabled
        dual-primary interface errdisabled :               False

        MLAG Ports:
        Disabled                           :                   0
        Configured                         :                   0
        Inactive                           :                   0
        Active-partial                     :                   0
        Active-full                        :                   1

        DC1_SVC2A>
        DC1_SVC2A>show mlag interfaces
                                                                                    local/remote
           mlag       desc                        state       local       remote          status
        ---------- --------------------- ----------------- ----------- ------------ ------------
              5       DC1_L2_LEAF_Po1       active-full         Po5          Po5           up/up
        ```

    === "DC1_SVC2B"

        ```bash hl_lines="1 26"
        DC1_SVC2B>show mlag
        MLAG Configuration:
        domain-id                          :            DC1_SVC2
        local-interface                    :            Vlan4094
        peer-address                       :        10.255.252.4
        peer-link                          :       Port-Channel3
        peer-config                        :          consistent

        MLAG Status:
        state                              :              Active
        negotiation status                 :           Connected
        peer-link status                   :                  Up
        local-int status                   :                  Up
        system-id                          :   02:1c:73:01:0d:2d
        dual-primary detection             :            Disabled
        dual-primary interface errdisabled :               False

        MLAG Ports:
        Disabled                           :                   0
        Configured                         :                   0
        Inactive                           :                   0
        Active-partial                     :                   0
        Active-full                        :                   1

        DC1_SVC2B>
        DC1_SVC2B>show mlag interfaces
                                                                                    local/remote
           mlag       desc                        state       local       remote          status
        ---------- --------------------- ----------------- ----------- ------------ ------------
              5       DC1_L2_LEAF_Po1       active-full         Po5          Po5           up/up
        ```

    === "DC1_L2_LEAF2A"

        ```bash hl_lines="1 26"
        DC1_L2_LEAF2A>show mlag
        MLAG Configuration:
        domain-id                          :         DC1_L2_LEAF
        local-interface                    :            Vlan4094
        peer-address                       :        10.255.252.9
        peer-link                          :       Port-Channel3
        peer-config                        :          consistent

        MLAG Status:
        state                              :              Active
        negotiation status                 :           Connected
        peer-link status                   :                  Up
        local-int status                   :                  Up
        system-id                          :   02:1c:73:b1:62:4c
        dual-primary detection             :            Disabled
        dual-primary interface errdisabled :               False

        MLAG Ports:
        Disabled                           :                   0
        Configured                         :                   0
        Inactive                           :                   0
        Active-partial                     :                   0
        Active-full                        :                   3

        DC1_L2_LEAF2A>
        DC1_L2_LEAF2A>show mlag interfaces
                                                                                          local/remote
           mlag       desc                              state       local       remote          status
        ---------- --------------------------- ----------------- ----------- ------------ ------------
              1       DC1_SVC2_Po5                active-full         Po1          Po1           up/up
              5       server03_PortChannel5       active-full         Po5          Po5           up/up
              6       server04_PortChannel6       active-full         Po6          Po6           up/up
        ```

    === "DC1_L2_LEAF2B"

        ```bash hl_lines="1 26"
        DC1_L2_LEAF2B>show mlag
        MLAG Configuration:
        domain-id                          :         DC1_L2_LEAF
        local-interface                    :            Vlan4094
        peer-address                       :        10.255.252.8
        peer-link                          :       Port-Channel3
        peer-config                        :          consistent

        MLAG Status:
        state                              :              Active
        negotiation status                 :           Connected
        peer-link status                   :                  Up
        local-int status                   :                  Up
        system-id                          :   02:1c:73:b1:62:4c
        dual-primary detection             :            Disabled
        dual-primary interface errdisabled :               False

        MLAG Ports:
        Disabled                           :                   0
        Configured                         :                   0
        Inactive                           :                   0
        Active-partial                     :                   0
        Active-full                        :                   3

        DC1_L2_LEAF2B>
        DC1_L2_LEAF2B>show mlag interfaces
                                                                                          local/remote
           mlag       desc                              state       local       remote          status
        ---------- --------------------------- ----------------- ----------- ------------ ------------
              1       DC1_SVC2_Po5                active-full         Po1          Po1           up/up
              5       server03_PortChannel5       active-full         Po5          Po5           up/up
              6       server04_PortChannel6       active-full         Po6          Po6           up/up
        ```

??? success "VXLAN, VLAN to VNI Mappings, L3VNI and VRF Mappings"

    === "DC1_LEAF1A"

        ```bash hl_lines="1"
        DC1_LEAF1A>show interfaces Vxlan 1
        Vxlan1 is up, line protocol is up (connected)
          Hardware is Vxlan
          Description: DC1_LEAF1A_VTEP
          Source interface is Loopback1 and is active with 192.168.254.3
          Listening on UDP port 4789
          Replication/Flood Mode is headend with Flood List Source: EVPN
          Remote MAC learning via EVPN
          VNI mapping to VLANs
          Static VLAN to VNI mapping is
            [110, 10110]      [111, 10111]
          Dynamic VLAN to VNI mapping for 'evpn' is
            [1199, 10]
          Note: All Dynamic VLANs used by VCS are internal VLANs.
                Use 'show vxlan vni' for details.
          Static VRF to VNI mapping is
           [Tenant_A_OP_Zone, 10]
          MLAG Shared Router MAC is 021c.7357.aa63
        ```
    
    === "DC1_LEAF1B"

        ```bash hl_lines="1"
        DC1_LEAF1B>show interfaces Vxlan 1
        Vxlan1 is up, line protocol is up (connected)
          Hardware is Vxlan
          Description: DC1_LEAF1B_VTEP
          Source interface is Loopback1 and is active with 192.168.254.3
          Listening on UDP port 4789
          Replication/Flood Mode is headend with Flood List Source: EVPN
          Remote MAC learning via EVPN
          VNI mapping to VLANs
          Static VLAN to VNI mapping is
            [110, 10110]      [111, 10111]
          Dynamic VLAN to VNI mapping for 'evpn' is
            [1199, 10]
          Note: All Dynamic VLANs used by VCS are internal VLANs.
                Use 'show vxlan vni' for details.
          Static VRF to VNI mapping is
           [Tenant_A_OP_Zone, 10]
          MLAG Shared Router MAC is 021c.7357.aa63
        ```
    
    === "DC1_SVC2A"

        ```bash hl_lines="1"
        DC1_SVC2A>show interfaces Vxlan 1
        Vxlan1 is up, line protocol is up (connected)
          Hardware is Vxlan
          Description: DC1_SVC2A_VTEP
          Source interface is Loopback1 and is active with 192.168.254.5
          Listening on UDP port 4789
          Replication/Flood Mode is headend with Flood List Source: EVPN
          Remote MAC learning via EVPN
          VNI mapping to VLANs
          Static VLAN to VNI mapping is
            [112, 10112]      [113, 10113]
          Dynamic VLAN to VNI mapping for 'evpn' is
            [1199, 10]
          Note: All Dynamic VLANs used by VCS are internal VLANs.
                Use 'show vxlan vni' for details.
          Static VRF to VNI mapping is
           [Tenant_A_OP_Zone, 10]
          MLAG Shared Router MAC is 021c.7301.0d2d
        ```

    === "DC1_SVC2B"

        ```bash hl_lines="1"
        DC1_SVC2B>show interfaces Vxlan 1
        Vxlan1 is up, line protocol is up (connected)
          Hardware is Vxlan
          Description: DC1_SVC2B_VTEP
          Source interface is Loopback1 and is active with 192.168.254.5
          Listening on UDP port 4789
          Replication/Flood Mode is headend with Flood List Source: EVPN
          Remote MAC learning via EVPN
          VNI mapping to VLANs
          Static VLAN to VNI mapping is
            [112, 10112]      [113, 10113]
          Dynamic VLAN to VNI mapping for 'evpn' is
            [1199, 10]
          Note: All Dynamic VLANs used by VCS are internal VLANs.
                Use 'show vxlan vni' for details.
          Static VRF to VNI mapping is
           [Tenant_A_OP_Zone, 10]
          MLAG Shared Router MAC is 021c.7301.0d2d
        ```

* Login to the alpine-host clients using `docker exec`

```bash
docker exec -it clab-avdirb-client1 /bin/sh
```

??? success "Ping to gateway & Remote hosts"

    === "client1"

        ```bash hl_lines="1 10 23 36 49"
        / $ ip addr show team0.110
        3: team0.110@team0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP qlen 1000
            link/ether aa:c1:ab:27:f2:6c brd ff:ff:ff:ff:ff:ff
            inet 10.1.10.101/24 brd 10.1.10.255 scope global team0.110
               valid_lft forever preferred_lft forever
            inet6 fe80::a8c1:abff:fe27:f26c/64 scope link
               valid_lft forever preferred_lft forever
        / $
        / $ # Ping to Gateway
        / $ sudo ping -c 5 10.1.10.1
        PING 10.1.10.1 (10.1.10.1): 56 data bytes
        64 bytes from 10.1.10.1: seq=0 ttl=64 time=6.177 ms
        64 bytes from 10.1.10.1: seq=1 ttl=64 time=2.834 ms
        64 bytes from 10.1.10.1: seq=2 ttl=64 time=1.498 ms
        64 bytes from 10.1.10.1: seq=3 ttl=64 time=1.372 ms
        64 bytes from 10.1.10.1: seq=4 ttl=64 time=1.504 ms

        --- 10.1.10.1 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 1.372/2.677/6.177 ms
        / $
        / $ # Ping to client2
        / $ sudo ping -c 5 10.1.11.102
        PING 10.1.11.102 (10.1.11.102): 56 data bytes
        64 bytes from 10.1.11.102: seq=0 ttl=63 time=3.794 ms
        64 bytes from 10.1.11.102: seq=1 ttl=63 time=2.010 ms
        64 bytes from 10.1.11.102: seq=2 ttl=63 time=1.918 ms
        64 bytes from 10.1.11.102: seq=3 ttl=63 time=1.409 ms
        64 bytes from 10.1.11.102: seq=4 ttl=63 time=1.811 ms

        --- 10.1.11.102 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 1.409/2.188/3.794 ms
        / $
        / $ # Ping to client3
        / $ sudo ping -c 5 10.1.12.103
        PING 10.1.12.103 (10.1.12.103): 56 data bytes
        64 bytes from 10.1.12.103: seq=0 ttl=62 time=19.187 ms
        64 bytes from 10.1.12.103: seq=1 ttl=62 time=7.130 ms
        64 bytes from 10.1.12.103: seq=2 ttl=62 time=5.741 ms
        64 bytes from 10.1.12.103: seq=3 ttl=62 time=6.358 ms
        64 bytes from 10.1.12.103: seq=4 ttl=62 time=4.065 ms

        --- 10.1.12.103 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 4.065/8.496/19.187 ms
        / $
        / $ # Ping to client4
        / $ sudo ping -c 5 10.1.13.104
        PING 10.1.13.104 (10.1.13.104): 56 data bytes
        64 bytes from 10.1.13.104: seq=0 ttl=62 time=17.055 ms
        64 bytes from 10.1.13.104: seq=1 ttl=62 time=4.802 ms
        64 bytes from 10.1.13.104: seq=2 ttl=62 time=6.559 ms
        64 bytes from 10.1.13.104: seq=3 ttl=62 time=6.602 ms
        64 bytes from 10.1.13.104: seq=4 ttl=62 time=5.060 ms

        --- 10.1.13.104 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 4.802/8.015/17.055 ms
        ```
    
    === "client2"

        ```bash hl_lines="1 10 23 36 49"
        / $ ip addr show team0.111
        3: team0.111@team0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP qlen 1000
            link/ether aa:c1:ab:72:02:d1 brd ff:ff:ff:ff:ff:ff
            inet 10.1.11.102/24 brd 10.1.11.255 scope global team0.111
               valid_lft forever preferred_lft forever
            inet6 fe80::a8c1:abff:fe72:2d1/64 scope link
               valid_lft forever preferred_lft forever
        / $
        / $ # Ping to Gateway
        / $ sudo ping -c 5 10.1.11.1
        PING 10.1.11.1 (10.1.11.1): 56 data bytes
        64 bytes from 10.1.11.1: seq=0 ttl=64 time=3.545 ms
        64 bytes from 10.1.11.1: seq=1 ttl=64 time=1.333 ms
        64 bytes from 10.1.11.1: seq=2 ttl=64 time=1.245 ms
        64 bytes from 10.1.11.1: seq=3 ttl=64 time=0.901 ms
        64 bytes from 10.1.11.1: seq=4 ttl=64 time=0.819 ms

        --- 10.1.11.1 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 0.819/1.568/3.545 ms
        / $
        / $ # Ping to client1
        / $ sudo ping -c 5 10.1.10.101
        PING 10.1.10.101 (10.1.10.101): 56 data bytes
        64 bytes from 10.1.10.101: seq=0 ttl=63 time=2.660 ms
        64 bytes from 10.1.10.101: seq=1 ttl=63 time=2.101 ms
        64 bytes from 10.1.10.101: seq=2 ttl=63 time=1.395 ms
        64 bytes from 10.1.10.101: seq=3 ttl=63 time=2.134 ms
        64 bytes from 10.1.10.101: seq=4 ttl=63 time=1.882 ms

        --- 10.1.10.101 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 1.395/2.034/2.660 ms
        / $
        / $ # Ping to client3
        / $ sudo ping -c 5 10.1.12.103
        PING 10.1.12.103 (10.1.12.103): 56 data bytes
        64 bytes from 10.1.12.103: seq=0 ttl=62 time=17.315 ms
        64 bytes from 10.1.12.103: seq=1 ttl=62 time=5.343 ms
        64 bytes from 10.1.12.103: seq=2 ttl=62 time=6.110 ms
        64 bytes from 10.1.12.103: seq=3 ttl=62 time=5.370 ms
        64 bytes from 10.1.12.103: seq=4 ttl=62 time=5.957 ms

        --- 10.1.12.103 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 5.343/8.019/17.315 ms
        / $
        / $ # Ping to client4
        / $ sudo ping -c 5 10.1.13.104
        PING 10.1.13.104 (10.1.13.104): 56 data bytes
        64 bytes from 10.1.13.104: seq=0 ttl=62 time=9.082 ms
        64 bytes from 10.1.13.104: seq=1 ttl=62 time=5.016 ms
        64 bytes from 10.1.13.104: seq=2 ttl=62 time=5.797 ms
        64 bytes from 10.1.13.104: seq=3 ttl=62 time=3.430 ms
        64 bytes from 10.1.13.104: seq=4 ttl=62 time=4.376 ms

        --- 10.1.13.104 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 3.430/5.540/9.082 ms
        ```
    
    === "client3"

        ```bash hl_lines="1 10 23 36 49"
        / $ ip addr show team0.112
        3: team0.112@team0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP qlen 1000
            link/ether aa:c1:ab:e6:20:f5 brd ff:ff:ff:ff:ff:ff
            inet 10.1.12.103/24 brd 10.1.12.255 scope global team0.112
               valid_lft forever preferred_lft forever
            inet6 fe80::a8c1:abff:fee6:20f5/64 scope link
               valid_lft forever preferred_lft forever
        / $
        / $ # Ping to Gateway
        / $ sudo ping -c 5 10.1.12.1
        PING 10.1.12.1 (10.1.12.1): 56 data bytes
        64 bytes from 10.1.12.1: seq=0 ttl=64 time=2.343 ms
        64 bytes from 10.1.12.1: seq=1 ttl=64 time=2.243 ms
        64 bytes from 10.1.12.1: seq=2 ttl=64 time=2.383 ms
        64 bytes from 10.1.12.1: seq=3 ttl=64 time=1.583 ms
        64 bytes from 10.1.12.1: seq=4 ttl=64 time=2.322 ms

        --- 10.1.12.1 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 1.583/2.174/2.383 ms
        / $
        / $ # Ping to client1
        / $ sudo ping -c 5 10.1.10.101
        PING 10.1.10.101 (10.1.10.101): 56 data bytes
        64 bytes from 10.1.10.101: seq=0 ttl=62 time=15.835 ms
        64 bytes from 10.1.10.101: seq=1 ttl=62 time=5.165 ms
        64 bytes from 10.1.10.101: seq=2 ttl=62 time=5.067 ms
        64 bytes from 10.1.10.101: seq=3 ttl=62 time=6.425 ms
        64 bytes from 10.1.10.101: seq=4 ttl=62 time=4.345 ms

        --- 10.1.10.101 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 4.345/7.367/15.835 ms
        / $
        / $ # Ping to client2
        / $ sudo ping -c 5 10.1.11.102
        PING 10.1.11.102 (10.1.11.102): 56 data bytes
        64 bytes from 10.1.11.102: seq=0 ttl=62 time=8.623 ms
        64 bytes from 10.1.11.102: seq=1 ttl=62 time=6.560 ms
        64 bytes from 10.1.11.102: seq=2 ttl=62 time=5.666 ms
        64 bytes from 10.1.11.102: seq=3 ttl=62 time=4.498 ms
        64 bytes from 10.1.11.102: seq=4 ttl=62 time=5.077 ms

        --- 10.1.11.102 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 4.498/6.084/8.623 ms
        / $
        / $ # Ping to client4
        / $ sudo ping -c 5 10.1.13.104
        PING 10.1.13.104 (10.1.13.104): 56 data bytes
        64 bytes from 10.1.13.104: seq=0 ttl=63 time=5.768 ms
        64 bytes from 10.1.13.104: seq=1 ttl=63 time=3.087 ms
        64 bytes from 10.1.13.104: seq=2 ttl=63 time=4.001 ms
        64 bytes from 10.1.13.104: seq=3 ttl=63 time=4.115 ms
        64 bytes from 10.1.13.104: seq=4 ttl=63 time=3.755 ms

        --- 10.1.13.104 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 3.087/4.145/5.768 ms
        ```

    === "client4"

        ```bash hl_lines="1 10 23 36 49"
        / $ ip addr show team0.113
        3: team0.113@team0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP qlen 1000
            link/ether aa:c1:ab:0e:06:7d brd ff:ff:ff:ff:ff:ff
            inet 10.1.13.104/24 brd 10.1.13.255 scope global team0.113
               valid_lft forever preferred_lft forever
            inet6 fe80::a8c1:abff:fe0e:67d/64 scope link
               valid_lft forever preferred_lft forever
        / $
        / $ # Ping to Gateway
        / $ sudo ping -c 5 10.1.13.1
        PING 10.1.13.1 (10.1.13.1): 56 data bytes
        64 bytes from 10.1.13.1: seq=0 ttl=64 time=9.897 ms
        64 bytes from 10.1.13.1: seq=1 ttl=64 time=4.338 ms
        64 bytes from 10.1.13.1: seq=2 ttl=64 time=2.396 ms
        64 bytes from 10.1.13.1: seq=3 ttl=64 time=2.683 ms
        64 bytes from 10.1.13.1: seq=4 ttl=64 time=2.481 ms
        
        --- 10.1.13.1 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 2.396/4.359/9.897 ms
        / $
        / $ # Ping to client1
        / $ sudo ping -c 5 10.1.10.101
        PING 10.1.10.101 (10.1.10.101): 56 data bytes
        64 bytes from 10.1.10.101: seq=0 ttl=62 time=8.414 ms
        64 bytes from 10.1.10.101: seq=1 ttl=62 time=7.919 ms
        64 bytes from 10.1.10.101: seq=2 ttl=62 time=3.955 ms
        64 bytes from 10.1.10.101: seq=3 ttl=62 time=7.085 ms
        64 bytes from 10.1.10.101: seq=4 ttl=62 time=6.127 ms
        
        --- 10.1.10.101 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 3.955/6.700/8.414 ms
        / $
        / $ # Ping to client2
        / $ sudo ping -c 5 10.1.11.102
        PING 10.1.11.102 (10.1.11.102): 56 data bytes
        64 bytes from 10.1.11.102: seq=0 ttl=62 time=6.925 ms
        64 bytes from 10.1.11.102: seq=1 ttl=62 time=7.298 ms
        64 bytes from 10.1.11.102: seq=2 ttl=62 time=6.092 ms
        64 bytes from 10.1.11.102: seq=3 ttl=62 time=7.421 ms
        64 bytes from 10.1.11.102: seq=4 ttl=62 time=7.135 ms
        
        --- 10.1.11.102 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 6.092/6.974/7.421 ms
        / $
        / $ # Ping to client3
        / $ sudo ping -c 5 10.1.12.103
        PING 10.1.12.103 (10.1.12.103): 56 data bytes
        64 bytes from 10.1.12.103: seq=0 ttl=63 time=5.357 ms
        64 bytes from 10.1.12.103: seq=1 ttl=63 time=14.148 ms
        64 bytes from 10.1.12.103: seq=2 ttl=63 time=4.379 ms
        64 bytes from 10.1.12.103: seq=3 ttl=63 time=5.095 ms
        64 bytes from 10.1.12.103: seq=4 ttl=63 time=4.964 ms
        
        --- 10.1.12.103 ping statistics ---
        5 packets transmitted, 5 packets received, 0% packet loss
        round-trip min/avg/max = 4.379/6.788/14.148 ms
        ```

* Using `arista.avd.eos_validate_state` to validate the actual / operational state as compared to the desired state. It generates CSV and Markdown reports of the result, which are stored under the `reports` directory.

```bash
ansible-playbook playbooks/fabric-deploy-config.yaml --tags=verify
```

??? "Reveal Output"

    ```shell
    reports/
    ├── DC1_FABRIC-state.csv
    └── DC1_FABRIC-state.md
    ```

## Destroying the lab

Use the `containerlab destroy` command to destroy the lab.

```bash
sudo containerlab destroy -t topology.yaml
```

???+ tip

    * Use the `destroy` command with the `--cleanup` flag, to remove the containerlab lab directory and all its contents.
    * Without this flag containerlab will preserve the lab directory in the current working directory.
    * The lab directory name follows the `clab-<lab_name>` template, which in this example is `clab-avdirb` directory.
    * This includes the contents of `/mnt/flash` such as `startup-config` etc and other containerlab artifacts.
    * If the directory `clab-<lab_name>`, already exists, containerlab will initialize nodes using configuration files saved from the prior execution of the lab.
