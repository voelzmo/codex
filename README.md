# codex

Code brings together the years of experience and lessons learned after designing, deploying and managing their client's BOSH and Cloud Foundry distributed architectures.  These best practices are gathered together here to further mature and develop these techniques.

## Overview

1. Choose a [Infrastructure](infrastructure.md) provider
1. Designate a [network](network.md) topology
1. Create a BOSH [management environment](management_environment.md) (proto-BOSH)
1. Create each [release environment](release_environments.md) for testing (staging/production)

![proto-BOSH](/images/proto-BOSH.png)

In the above diagram, BOSH (1) is the proto-BOSH, while BOSH (2) and BOSH (3) are the per-site BOSH directors.
