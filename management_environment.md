## Management Environment

### Prerequisites

Please ensure that these have been setup:

  * [Infrastructure Provider](infrastructure.md)
  * [Network Topology](network.md)

### Setup proto-BOSH

1. Stand up the proto-BOSH director using `bosh-init`.

    Use [this software](https://github.com/cloudfoundry-community/aws-nat-bastion-bosh-cf) to bootstrap a proto-BOSH director using `bosh-init`, Terraform, and AWS.

### Generate a Vault deployment manifest

The following outlines the process to generate a vault deployment manifest:

1. Setup a deployment, using a template.
1. For our deployment, generate a site from a template.
1. Using our site, create an environment.

Let's begin.

1. Setup a deployment, using a template.

    <pre class="terminal">
    mkdir -p ~/codex
    cd ~/codex
    genesis new deployment --template vault vault
    </pre>

1. For our deployment, generate a site from a template.  This can be a name of your infrastructure provider or datacenter location.

    <pre class="terminal">
    cd ~/codex/vault-deployments
    genesis new site --template aws aws
    </pre>

1. Using our site, create an environment.  For instance, if we're creating the `prod` for Production in the "aws" site, we'd run:

    <pre class="terminal">
    cd ~/code/vault-deployments/aws
    genesis new environment site prod
    </pre>

### Use proto-BOSH to deploy Vault

1. Initialize Vault, disperse keys and configure policies / authentication

1. Migrate credentials from proto-BOSH manifest into Vault

1. Re-deploy proto-BOSH (an update) using Vaulted manifests

### Release Environment

Now it's time to build each subsequent [Release Environment](release_environments.md).
