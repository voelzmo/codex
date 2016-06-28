# The Network Plan

> This document is used throughout the rest of this documentation
> as a guideline for how networks are laid out, to provide the
> most flexibility in deployment, while mapping to common notions
> of fault zones.  You are strongly encouraged to make your own
> _Network Plan_, one for each site you build.  Doing so clarifies
> the intent of your deployments, and provides a single source of
> truth for things like BOSH `networks` stanzas, BOSH cloud
> config, firewalling and access control, and more.

## Supernet

All deployments in this site live under the `10.4.0.0/16` subnet:

```
-[ipv4 : 10.4.0.0/16] - 0

[CIDR]
Host address            - 10.4.0.0
Host address (decimal)  - 168034304
Host address (hex)      - A040000
Network address         - 10.4.0.0
Network mask            - 255.255.0.0
Network mask (bits)     - 16
Network mask (hex)      - FFFF0000
Broadcast address       - 10.4.255.255
Cisco wildcard          - 0.0.255.255
Addresses in network    - 65536
Network range           - 10.4.0.0 - 10.4.255.255
Usable range            - 10.4.0.1 - 10.4.255.254

-
```

That provides **65534** usable hosts across *255* `/24` subnets.

## Network Subdivision

> In general, we will use either `/24`, `/23` or `/22` subnet
> divisions of our supernet.  If the IaaS supports it, these should
> be real networks, with their own dedicated gateways and subnet
> masks.

To support the global infrastructure and several different
(isolated) environments (i.e. dev, staging, prod, etc.), we divide
the supernet up into 16 `/20` site networks.  Each of these can be
further sub-divided into even smaller, deployment-specific
networks (i.e. cf-edge-1, cf-edge-2, cf-1, cf-2, etc.).

| Site    | Subnet       | Deployment  | Subnet         | #    | Zone  | Purpose                |
| ------- | ------------ | ----------- | -------------- | ---- | ----- | ---------------------- |
| infra   | 10.4.0.0/20  |             |                | 4096 |       |                        |
|         |              | -           | 10.4.0.0/24    |  254 |     1 | Global Infrastructure  |
|         |              | -           | 10.4.1.0/24    |  254 |     2 | Global Infrastructure  |
|         |              | -           | 10.4.2.0/24    |  254 |     3 | Global Infrastructure  |
| dev     | 10.4.16.0/20 |             |                | 4096 |       |                        |
|         |              | -           | 10.4.16.0/24   |  254 |       | Site Infrastructure    |
|         |              | -           | 10.4.17.0/24   |  254 |       | Site Infrastructure    |
|         |              | -           | 10.4.18.0/24   |  254 |       | Site Infrastructure    |
|         |              | cf          | 10.4.19.0/25   |  126 |     1 | Cloud Foundry Routers  |
|         |              | cf          | 10.4.19.128/25 |  126 |     2 | Cloud Foundry Routers  |
|         |              | cf          | 10.4.20.0/24   |  254 |     1 | Cloud Foundry Core     |
|         |              | cf          | 10.4.21.0/24   |  254 |     2 | Cloud Foundry Core     |
|         |              | cf          | 10.4.22.0/24   |  254 |     3 | Cloud Foundry Core     |
|         |              | diego       | 10.4.23.0/24   |  254 |     1 | Diego Runtime          |
|         |              | diego       | 10.4.24.0/24   |  254 |     2 | Diego Runtime          |
|         |              | diego       | 10.4.25.0/24   |  254 |     3 | Diego Runtime          |
|         |              | *           | 10.4.26.0/24   |  254 |     1 | Cloud Foundry Services |
|         |              | *           | 10.4.27.0/24   |  254 |     2 | Cloud Foundry Services |
|         |              | *           | 10.4.28.0/24   |  254 |     3 | Cloud Foundry Services |
| staging | 10.4.32.0/20 |             |                | 4096 |       |                        |
|         |              | -           | 10.4.32.0/24   |  254 |     1 | Site Infrastructure    |
|         |              | -           | 10.4.33.0/24   |  254 |     2 | Site Infrastructure    |
|         |              | -           | 10.4.34.0/24   |  254 |     3 | Site Infrastructure    |
|         |              | cf          | 10.4.35.0/25   |  126 |     1 | Cloud Foundry Routers  |
|         |              | cf          | 10.4.35.128/25 |  126 |     2 | Cloud Foundry Routers  |
|         |              | cf          | 10.4.36.0/24   |  254 |     1 | Cloud Foundry Core     |
|         |              | cf          | 10.4.37.0/24   |  254 |     2 | Cloud Foundry Core     |
|         |              | cf          | 10.4.38.0/24   |  254 |     3 | Cloud Foundry Core     |
|         |              | diego       | 10.4.39.0/24   |  254 |     1 | Diego Runtime          |
|         |              | diego       | 10.4.40.0/24   |  254 |     2 | Diego Runtime          |
|         |              | diego       | 10.4.41.0/24   |  254 |     3 | Diego Runtime          |
|         |              | *           | 10.4.42.0/24   |  254 |     1 | Cloud Foundry Services |
|         |              | *           | 10.4.43.0/24   |  254 |     2 | Cloud Foundry Services |
|         |              | *           | 10.4.44.0/24   |  254 |     3 | Cloud Foundry Services |
| prod    | 10.4.48.0/20 |             |                | 4096 |       |                        |
|         |              | -           | 10.4.48.0/24   |  254 |     1 | Site Infrastructure    |
|         |              | -           | 10.4.49.0/24   |  254 |     2 | Site Infrastructure    |
|         |              | -           | 10.4.50.0/24   |  254 |     3 | Site Infrastructure    |
|         |              | cf          | 10.4.51.0/25   |  126 |     1 | Cloud Foundry Routers  |
|         |              | cf          | 10.4.51.128/25 |  126 |     2 | Cloud Foundry Routers  |
|         |              | cf          | 10.4.52.0/24   |  254 |     1 | Cloud Foundry Core     |
|         |              | cf          | 10.4.53.0/24   |  254 |     2 | Cloud Foundry Core     |
|         |              | cf          | 10.4.54.0/24   |  254 |     3 | Cloud Foundry Core     |
|         |              | diego       | 10.4.55.0/24   |  254 |     1 | Diego Runtime          |
|         |              | diego       | 10.4.56.0/24   |  254 |     2 | Diego Runtime          |
|         |              | diego       | 10.4.57.0/24   |  254 |     3 | Diego Runtime          |
|         |              | *           | 10.4.58.0/24   |  254 |     1 | Cloud Foundry Services |
|         |              | *           | 10.4.59.0/24   |  254 |     2 | Cloud Foundry Services |
|         |              | *           | 10.4.60.0/24   |  254 |     3 | Cloud Foundry Services |


## Global Infrastructure IP Allocation

The `infra` "site" consists of three zone-isolated subnets.  Inside of those
subnets, we can further sub-divide (albeit purely for allocation's sake) for
the different infrastructural deployments.  Note that these sub-divisions
will not introduce new gateways, netmasks or broadcast addresses, rather
they merely serve to slice up the `/24` networks for fairly small
deployments.

| Deployment | "Subnet"     | #  | Zone | Purpose                         |
| ---------- | ------------ | --- | ---- | ------------------------------- |
| _reserved_ | 10.4.0.0/28  |  16 |      | IaaS use (bastion / nat / etc.) |
| bosh       | 10.4.1.0/28  |  16 |      | proto-BOSH director             |
| vault      | 10.4.0.16/28 |  16 |    1 | Secure Vault                    |
| vault      | 10.4.1.16/28 |  16 |    2 | Secure Vault                    |
| vault      | 10.4.2.16/28 |  16 |    3 | Secure Vault                    |
| shield     | 10.4.0.32/28 |  16 |      | SHIELD Backup/Restore Core      |
| concourse  | 10.4.0.48/28 |  16 |      | Runway Concourse                |
| bolo       | 10.4.0.64/28 |  16 |      | Monitoring                      |

The _reserved_ `10.4.0.0/28` range houses the site gateway, any networking
gear like AWS NAT hosts or DNS appliances (in AWS, 10.4.0.2 would be our
resolver), and the IaaS-provided bastion host.  In AWS, Terraform is
responsible for deploying the bastion host, so BOSH needs to be told to stay
away from it.

Most infrastructural deployments are not highly available, nor even
HA-capable, so they do not need to be striped across the three zone-isolated
subnets.  `vault` is the only HA deployment in the bunch, however, so it
_is_ deployed across three `/28` ranges, one per subnet.
