## Infrastructure

### Choosing a Provider

BOSH's cloud provider interface (CPI) list continues to grow.  Currently documented and supported are:

* AWS (here's a [Terrraform configuration](iaas/aws.md))
* Azure
* OpenStack
* vSphere
* RackHD
* Warden/Garden
* VirtualBox

### Design a Network

Once you know where you're going to build, [setting up the network](network.md) will help when making decisions on building your management or release environments.
