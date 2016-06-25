[README](README.md) > **Management Environment**

## Management Environment

### Prerequisites

Please ensure that these have been setup:

  * [Infrastructure Provider](infrastructure.md)
  * [Network Topology](network.md)
  * [Initialize proto-BOSH](initialize.md)

### Setup Services

After the proto-BOSH has been initialized, each of these management services are brought up to provide services.

1. [Setup vault](manage/vault.md) to store secrets.  Integrates with `genesis` driven templates once initialized and configured.  Best to setup first.

1. [Setup bolo](manage/bolo.md) and gain deeper insights into metrics of the hardware of the infrastructure.

1. [Setup concourse](manage/concourse.md) TODO: how are we using concourse in the management environment?

1. [Setup shield](manage/shield.md) backup and restore your vital data systems with our pluggable system.

### Begin Building Release Environment(s)

Once the proto-BOSH's services setup is complete, each subsequent [Release Environment](release.md) can be constructed.
