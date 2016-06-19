## Network

### Example for AWS

Here's an example network for an AWS build.

```
  - 10.10.0.0/16 -> overall network
  - 10.10.0.0/24 -> NAT gateway / bastion host

  - 10.10.1.0/24 640ec712 BOSH (proto-BOSH and site-BOSHes)
  - 10.10.2.0/24 7a0ec70c INFRA (SHIELD / Bolo / Concourse / Vault)
  - 10.10.2.0/26 	SHIELD
  - 10.10.2.64/26	Bolo
  - 10.10.2.128/26   Concourse
  - 10.10.2.192/26   Vault

  - 10.10.1.31 prod bosh
  - 10.10.3.0/24 7d0ec70b prod	CF Proper
  - 10.10.4.0/24 fe3c889a prod	CF Services

  - 10.10.1.51 staging boshl
  - 10.10.5.0/24 670ec711 staging CF Proper
  - 10.10.6.0/24 4345d227 staging CF Services

  - 10.10.7.0/24 660ec710     	(unused)
```

### Setup the management environment

Now it's time to setup the [management environment](management_environment.md) that will enable each release environment to be more resilient and flexible.
