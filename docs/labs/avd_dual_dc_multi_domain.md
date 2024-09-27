# EVPN VXLAN Dual DC Multi-Domain

## Lab Overview

|                               |                                                                                  |
| ----------------------------- | -------------------------------------------------------------------------------- |
| **Name**                      | evpnmultidomain                                                                         |
| **Description**               | eBGP Overlay and eBGP Underlay                                                   |
| **Devices**                   | 2 Spines + 2 MLAG Leaf Pairs + 2 Border Leaves + 4 Clients (per DC)              |
| **Lab Directory**             | `avd-cEOS-Lab/labs/evpn/avd_dual_dc_multi_domain`                                       |

??? example "Reveal Topology"
    ![Figure avd_dual_dc_multi_domain](../images/evpn-dual-dc-lab-colored.png)

## Deploy Lab

* Navigate to the lab directory

```bash
cd avd-cEOS-Lab/labs/evpn/avd_dual_dc_multi_domain
```

* Deploy the cEOS-lab containers.

```bash
sudo containerlab deploy -t topology.yaml
```

* Build and deploy the configuration to the switches using eAPI.

```bash
ansible-playbook playbooks/fabric-deploy-config.yaml
```

* Configure the alpine-host clients in DC1

```bash
bash host_l3_config/dc1_l3_build.sh
```

* Configure the alpine-host clients in DC2

```bash
bash host_l3_config/dc2_l3_build.sh
```

???+ info
    For detailed deployment and validation steps please refer to the commands and example in the Getting Started [guide](../quickStart.md).
