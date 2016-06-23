[README](../../README.md) > [Management Environment](../../management_environment.md) > implementation/proto-BOSH/**vault**

## Setup Vault

The process to setup Vault is as such:

1. [Generate a Vault deployment manifest.](#toc1)
1. [Merge template files together.](#toc2)
1. [Deploy Vault to infrastructure.](#toc3)
1. [Initialize Vault.](#toc4)
1. [Disperse keys and configure policies and authentication.](#toc5)
1. [Migrate credentials from proto-BOSH manifest into Vault.](#toc6)
1. [Re-deploy proto-BOSH (an update) using Vaulted manifests.](#toc7)

### <a name="toc1"></a> Generate a Vault deployment manifest

We have a `genesis` template available for Vault.  To use it follow these steps.

1. Setup a deployment, using a template.

    <pre class="terminal">
    mkdir -p ~/codex
    cd ~/codex
    genesis new deployment --template vault
    </pre>

1. For our deployment, generate a site from a template.  This can be a name of your infrastructure provider or datacenter location.

    <pre class="terminal">
    cd ~/codex/vault-deployments
    genesis new site --template aws aws
    </pre>

1. Using our site, create an environment.  For instance, if we're creating the `prod` for Production in the "aws" site, we'd run:

    <pre class="terminal">
    cd ~/codex/vault-deployments/aws
    genesis new environment aws prod
    </pre>

### <a name="toc2"></a> Merge template files together

Next we use the tool called `spruce` to merge the `genesis` template together into
a single manifest that BOSH will use to deploy Vault.

This process is an iterative process of beginning in the `environment` folder where
the `Makefile` exists. Run the command `make manifest` to attempt to generate the
deployment manifest then pay attention to the resulting output.

1. Run the `make manifest` command and determine what needs to be configured.

    <pre class="terminal">
    cd ~/codex/vault-deployments/aws/prod
    make manifest
    </pre>

    ![make_manifest_example](/images/make_manifest_example.png)

    A recommended method to iterate through these errors is to take the first message,
    open a new connection at the top of the deployment and look for what the error
    is referencing.

    Using the first error:

    ```
    $.compilation.cloud_properties.availability_zone: Define the z1 AWS availability zone
    ```

    Go to the top of the deployment folder structure:

    <pre class="terminal">
    cd ~/codex/vault-deployments
    grep -e 'Define the z1 AWS availability zone' -ir
    </pre>

    ![search_example](/images/search_example.png)

    This informs us to look not in the `.file` folders.  Those are used for inheriting
    settings between layers that `genesis` manages.

    Focus then, on the `aws/site/resource_pools.yml` file in this case.  Open it
    looking inside for the reference to `Define the z1 AWS availability zone`.

    Inside the `aws/site/resource_pools.yml` file we find:

    ```
    meta:
      aws:
        azs:
          z1: (( param "Define the z1 AWS availability zone" ))
          z2: (( param "Define the z2 AWS availability zone" ))
          z3: (( param "Define the z3 AWS availability zone" ))
    ```

### <a name="toc3"></a> Deploy Vault to infrastructure

### <a name="toc4"></a> Initialize Vault

### <a name="toc5"></a> Disperse keys and configure policies and authentication

### <a name="toc6"></a> Migrate credentials from proto-BOSH manifest into Vault

### <a name="toc7"></a> Re-deploy proto-BOSH (an update) using Vaulted manifests
