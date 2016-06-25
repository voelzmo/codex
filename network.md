[README](../README.md) > **Network**

## Network

### Network IP Ranges

Determine how to map IP address ranges for concerns like below:

  * Overall Network
  * NAT gateway / bastion host
  * BOSH (proto-BOSH and site-BOSHes)
  * proto-BOSH Infrastructure (SHIELD / Bolo / Concourse / Vault)
  * SHIELD
  * Bolo
  * Concourse
  * Vault

For each Release Environment we need at least:

* Bosh Director IP
* Cloud Foundry Platform
* Cloud Foundry Services

TODO: Could use some love with regard to a "generic" version with CIDR ranges that can be recommended regardless of infrastructure.

### Infrastructure Specific Tips

* [AWS](network/aws.md)
* Azure
* OpenStack
* RackHD
* Warden/Garden
* VirtualBox
* vSphere

### Setup the management environment

Once the infrastructure and network are readNow it's time to setup the [management environment](management_environment.md) that will enable each release environment to be more resilient and flexible.
