# Installation

## Pre-requisites

The following requirements must be satisfied to use the labs:

* The user should have `sudo` privileges
* A Linux host/server/VM
* [Python](https://www.python.org/downloads/) 3.8 or later
* Install [ansible-core](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) from **2.12.6** to **2.15.x** excluding **2.13.0**
* Install [arista.avd](https://avd.arista.com/stable/docs/installation/collection-installation.html#install-collection-from-ansible-galaxy) collection from Ansible Galaxy
* AVD additional Python [requirements](https://avd.arista.com/stable/docs/installation/collection-installation.html#python-requirements-installation)
* Docker
* [containerlab](https://containerlab.dev/install/)
* Git
* Arista cEOS-Lab image (*4.23.x or above*)
* Alpine-host image
* Clone the repository using `git clone`.

=== "HTTPS"

    ```shell
    git clone https://github.com/arista-netdevops-community/avd-cEOS-Lab.git
    ```

=== "SSH"

    ```shell
    git clone git@github.com:arista-netdevops-community/avd-cEOS-Lab.git
    ```

??? info

    * For Python3, docker and ansible-core installation please refer to the installation guides based on the host OS.
    * For arista.avd installation please refer to the [official](https://avd.arista.com/stable/docs/installation/collection-installation.html) documenation.
    * For containerlab installation please refer to the [official](https://containerlab.dev/install/) documentation.

??? warning "Note"

    * Containerlab topology definitions have changed starting v0.15 - [Release Notes](https://containerlab.dev/rn/0.15/). Latest [release](https://github.com/arista-netdevops-community/avd-cEOS-Lab/releases) of this repository is containerlab v0.15 (and above) compatible. For older containerlab compatible syntax download [v1.1.2](https://github.com/arista-netdevops-community/avd-cEOS-Lab/releases)
    * arista.avd v3.0.0 contains breaking changes to data models [Release Notes](https://avd.sh/en/latest/docs/release-notes/3.x.x.html). Latest release of this repository is arista.avd v3.0.0 and above compatible. For older avd compatible syntax download older [release](https://github.com/arista-netdevops-community/avd-cEOS-Lab/releases).
    * Starting Python 3.10 the default SSL/TLS ciphers have been [updated](https://bugs.python.org/issue43998). Latest [release](https://github.com/arista-netdevops-community/avd-cEOS-Lab/releases) of this repository updates the cipher suite on EOS via a security profile applied to eAPI to be compatible with Python 3.10.

---

### Installing Arista cEOS-Lab image

* Download the image from [www.arista.com](http://www.arista.com/) > Software Downloads > cEOS-Lab > EOS-4.2x.y > cEOS-lab-4.2x.y.tar.xz
* Copy the `cEOS-lab-4.2x.y.tar.xz` to the host/server/VM.
* Ensure Docker is already set up and running.

```shell
docker version
```

* Next, use the tar file to import the cEOS-Lab image using the following command

```shell
docker import cEOS-lab.tar.xz ceosimage:TAG
```

```shell title="Example"
docker import cEOS64-lab-4.26.1F.tar.xz ceosimage:4.26.1F
```

* Now you should be able to see the Arista cEOS-Lab image.

```shell
docker images | egrep "REPO|ceos"
```

??? note "Reveal Output"

    ```shell
    REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
    ceosimage             4.26.1F             41b309a15f5c        30 hours ago        1.71GB
    ```

---

### Installing the alpine-host image

!!! info

    You have the option to use Arista cEOS-Lab or any other Linux-based container as a client/host.
 
    In which case please update the `topology.yaml` in respective lab folders, as by default lab uses an alpine-host image for client/host containers

* Build the alpine-host image using the modified Dockerfile from [docker-topo](https://github.com/networkop/docker-topo/tree/master/topo-extra-files/host)
* Navigate to `alpine_host` directory in this repository

```shell
├── alpine_host
   ├── Dockerfile
   ├── README.md
   ├── build.sh
   └── entrypoint.sh
```

* Run the `build.sh` script

```shell
./build.sh
```

* Verify the alpine-host image is created

```shell
docker images | egrep "TAG|alpine"
```

??? note "Reveal Output"

    ```shell
    REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
    alpine-host           latest              eab21450c58c        30 hours ago        68.7MB
    ```

---

### cEOS-Lab containerlab template

!!! warning "Note"

    The below steps are no longer required for containerlab v0.15 and above.
    
    The v2.0.0 and above releases of this repository include this template in the `topology.yaml` itself.

    ***The Below steps are only required if using containerlab version less than v0.15***

Replace the containerlab cEOS default template with the `ceos.cfg.tpl` file from this repository.

```shell
ceos_lab_template
└── ceos.cfg.tpl
```

??? danger "Warning"

    If the default template is not replaced with the one from this repository, then for the initial AVD config replace you will observe a timeout error.

The default template can be usually found at `/etc/containerlab/templates/arista/ceos.cfg.tpl`

This is to ensure the containers by default come up with:

* [x] Multi agent routing model
* [x] MGMT vrf for management connectivity
* [x] eAPI enabled
