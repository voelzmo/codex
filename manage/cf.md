[README](../README.md) > [Management Environment](../manage.md) > manage/**cf**

## Setup Cloud Foundry


Cloud Foundry uses Consul by Hashicorp for various purposes, but its
distributed datacenter high availability that needs some extra explanation.
Many high availability software packages allows you to run with a single
node cluster for its degraded mode. Consul does not. Consul defines an available cluster by having a quorum of nodes defined by the following formula (nodes/2) + 1 >= 2
If you do not have at least two nodes in your cluster, your cluster does
not have a quorum and your cluster is marked unavailable.

Even in a two node configuration, you do not have high availability
since one node going down means you do not have a quorum and thus no cluster.
So you need at least three nodes to have high availability. Consul's degraded mode is a two node cluster.

What does mean for running cloud foundry on Amazon Web Services?
You will want to have three availability zones.
An availability zone is an independent datacenter (power, machines, networking, etc) but also has low latency network to its sister availability zones.
An availability zone corresponds to the Consul cluster node.

If you define the three cloud foundry instances in only two
availability zones, you have some minimal level of high availability
It is not the strongest strongest high availability since losing an availability zone that has the two cloud foundry instances would make Consul lose its quorum.
