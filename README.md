# codex

Codex brings together the years of experience and lessons learned after designing, deploying and managing their client's BOSH and Cloud Foundry distributed architectures.  These best practices are gathered together here to further mature and develop these techniques.

## Deploying From Nothing

To get started with a best practices Codex deployment, you'll want
to choose your IaaS provider.  We have guides for the following:

- [AWS](deploy/aws.md)

## Overview

1. Choose a [infrastructure](infrastructure.md) provider.
1. Designate a [network](network.md) topology.
1. [Initialize](initialize.md) a proto-BOSH director.
1. Setup key software on the proto-BOSH [management environment](manage.md).
1. Create each BOSH [release environment](release.md) for incremental testing of releases.

![proto-BOSH](/images/proto-BOSH.png)

In the above diagram, BOSH (1) is the proto-BOSH, while BOSH (2) and BOSH (3) are the per-site BOSH directors.
