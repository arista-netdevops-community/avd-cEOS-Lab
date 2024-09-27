# Arista Validated Designs with cEOS-lab

![lab-version](https://img.shields.io/github/v/release/arista-netdevops-community/avd-cEOS-Lab?color=brightgreen&logo=appveyor&style=for-the-badge)
![cEOS-AVD](https://img.shields.io/badge/AVD-cEOS-brightgreen?logo=appveyor&style=for-the-badge)

---

This repository contains labs with examples to quickly deploy:

* Arista cEOS-Lab (*virtual*) based Leaf Spine topology using [containerlab](https://containerlab.dev/).
* Configure the Leaf Spine topology using [Arista Validated Designs (AVD)](https://avd.arista.com/) role.

---

The repository currently contains the following prebuilt labs.

??? example "EVPN Symmetric IRB"
    eBGP Overlay and eBGP Underlay

    2 Spines + 2 MLAG Leaf Pairs + 2 L2 leafs + 4 Clients

    ![Figure avd_sym_irb](./images/avdirb_v2.png)

??? example "EVPN Symmetric IRB"
    iBGP Overlay and OSFP Underlay

    2 Spines + 2 MLAG Leaf Pairs + 4 Clients

    ![Figure avd_sym_irb_ibgp](./images/avdirb-ibgp-ospf_v2.png)

??? example "EVPN Asymmetric IRB"
    eBGP Overlay and eBGP Underlay

    2 Spines + 2 MLAG Leaf Pairs + 4 Clients

    ![Figure avd_asym_irb](./images/avdasymirb_v2.png)

??? example "EVPN Centralized Anycast Gateway"
    eBGP Overlay and eBGP Underlay

    2 Spines + 1 MLAG Compute leaf pairs + 1 MLAG Service Leaf pair + 4 Clients

    ![Figure avd_central_any_gw](./images/avdcentralgw_v2.png)

??? example "EVPN VXLAN All-active Multi-homing IRB"
    eBGP Overlay and eBGP Underlay

    2 Spines + 4 PEs + 4 Clients

    ![Figure avd_asym_multihoming](./images/aa_asym_mh_v2.png)

??? example "EVPN Single-Active Multihoming Symmetric IRB"
    eBGP Overlay and eBGP Underlay

    2 Spines + 4 PEs + 4 Clients

    ![Figure avd_asym_multihoming](./images/sa_sym_mh_v2.png)

??? example "EVPN VXLAN Dual DC L3 Gateway"
    eBGP Overlay and eBGP Underlay

    2 Spines + 2 MLAG Leaf Pairs + 2 Border Leaves + 4 Clients (per DC)

    ![Figure avd_dual_dc_l3_gw](./images/evpn-dual-dc-lab-colored.png)

??? example "EVPN VXLAN Dual DC Multi-Domain"
    eBGP Overlay and eBGP Underlay

    2 Spines + 2 MLAG Leaf Pairs + 2 Border Leaves + 4 Clients (per DC)

    ![Figure avd_dual_dc_multi_domain](./images/evpn-dual-dc-lab-colored.png)

??? example "EVPN MPLS LDP All-Active Multihoming (L2EVPN)"
    iBGP Overlay and MPLS Underlay

    2 Ps + 4 PEs + 4 Clients

    {==using eos_cli_config_gen==}

    ![Figure avd_asym_multihoming](./images/mpls_v2.png)

??? example "EVPN All-Active Multihoming IRB with MPLS Underlay"
    iBGP Overlay and MPLS Underlay

    2 Ps + 4 PEs + 4 Clients

    {==using eos_cli_config_gen==}

    ![Figure avd_asym_multihoming](./images/mpls_v2.png)
