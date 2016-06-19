## Management Environment

### Prerequisites

Please ensure that these have been setup:

  * [Infrastructure Provider](infrastructure.md)
  * [Network Topology](network.md)

### Setup proto-BOSH

1. Stand up the proto-BOSH director using bosh-init
1. Use proto-BOSH to deploy Vault
  1. Initialize Vault, dispersing keys and configuring policies / authentication
  1. Migrate credentials from proto-BOSH manifest into Vault
  1. Re-deploy proto-BOSH (an update) using Vaulted manifests

### Release Environment

Now it's time to build each subsequent [Release Environment](release_environments.md).
