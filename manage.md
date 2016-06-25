[README](README.md) > **Management Environment**

## Management Environment

### Prerequisites

Please ensure that these have been setup:

  * [Infrastructure Provider](infrastructure.md)
  * [Network Topology](network.md)
  * [Initialize proto-BOSH](initialize.md)

### Setup Services

After the proto-BOSH has been bootstrapped, it's time to setup
the management services.

1. [Setup vault](manage/proto-BOSH/vault.md).

1. [Setup bolo](manage/proto-BOSH/bolo.md).

1. [Setup concourse](manage/proto-BOSH/concourse.md).

1. [Setup shield](manage/proto-BOSH/shield.md).

### Release Environment

Now it's time to build each subsequent [Release Environment](release.md).
