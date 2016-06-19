## Infrastructure

### Choosing a Provider

BOSH's cloud provider interface (CPI) list continues to grow.  Currently documented and supported are:

* AWS
* Azure
* OpenStack
* vSphere
* RackHD
* Warden/Garden
* VirtualBox

[Checkout this repo](https://github.com/cloudfoundry-community/aws-nat-bastion-bosh-cf) for how to setup BOSH and Cloud Foundry on AWS.

### Design a Network

Once you know where you're going to build, [setting up the network](network.md) will help when making decisions on building your management or release environments.
