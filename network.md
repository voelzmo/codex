[README](README.md) > **Network**

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

### Initialize the proto-BOSH Director

Once the infrastructure and network are ready, it's time to [initialize](initialize.md) the proto-BOSH Director that can be used to create and manage subsequent release BOSH environments.
