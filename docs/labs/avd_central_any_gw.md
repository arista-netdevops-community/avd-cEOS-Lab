# EVPN Centralized Anycast Gateway

## Lab Overview

|                               |                                                                                  |
| ----------------------------- | -------------------------------------------------------------------------------- |
| **Name**                      | avdcentralgw                                                                     |
| **Description**               | eBGP Overlay and eBGP Underlay                                                   |
| **Devices**                   | 2 Spines + 1 MLAG Compute leaf pairs + 1 MLAG Service Leaf pair + 4 Clients      |
| **Lab Directory**             | `avd-cEOS-Lab/labs/evpn/avd_central_any_gw`                                      |

??? example "Reveal Topology"
    ![Figure avd_sym_irb](../images/avdcentralgw_v2.png)

## Deploy Lab

* Navigate to the lab directory

```bash
cd avd-cEOS-Lab/labs/evpn/avd_central_any_gw
```

* Deploy the cEOS-lab containers

```bash
sudo containerlab deploy -t topology.yaml
```

* Build and deploy the configuration to the switches using eAPI

```bash
ansible-playbook playbooks/fabric-deploy-config.yaml
```

* Configure the alpine-host clients

```bash
bash host_l3_config/l3_build.sh
```

???+ info
    For detailed deployment and validation steps please refer to the commands and example in the Getting Started [guide](../quickStart.md).
