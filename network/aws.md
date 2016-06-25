[README](../README.md) > [Network](../network.md) > **AWS**

## AWS Network Example

Here's an example network for an AWS build.

TODO: This needs to be fleshed out more and explained better.

```
10.10.0.0/16    overall network
10.10.0.0/24    NAT gateway / bastion host

10.10.1.0/24    BOSH  (proto-BOSH and site-BOSHes)
10.10.2.0/24    INFRA (SHIELD / Bolo / Concourse / Vault)
10.10.2.0/26    SHIELD
10.10.2.64/26   Bolo
10.10.2.128/26  Concourse
10.10.2.192/26  Vault

10.10.1.31   prod  bosh
10.10.3.0/24 prod	CF Proper
10.10.4.0/24 prod	CF Services

10.10.1.51   staging bosh
10.10.5.0/24 staging CF Proper
10.10.6.0/24 staging CF Services

10.10.7.0/24 (unused)
```
