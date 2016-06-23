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

Once this process is complete running `make manifest` will exit `0` and have generated
a manifest file that can be used to deploy Vault.

1. Run the `make manifest` command.

    <pre class="terminal">
    cd ~/codex/vault-deployments/aws/prod
    make manifest
    </pre>

    This will either build a manifest file for you or it will tell you what you
    need to fix before it can build a working manifest.

    ![make_manifest_example](/images/make_manifest_example.png)

1. Read and understand the errors.

    A recommended method to iterate through these errors is to take the first message,
    open a new connection at the top of the deployment and look for what the error
    is referencing.

    Use the first error:

    ```
    $.compilation.cloud_properties.availability_zone: Define the z1 AWS availability zone
    ```

    Go to the top of the deployment folder structure:

    <pre class="terminal">
    cd ~/codex/vault-deployments
    grep -e 'Define the z1 AWS availability zone' -ir
    </pre>

    ![search_example](/images/search_example.png)

    TODO: Why can we usually skip the `.foldername` folders?

    Open the file `aws/site/resource_pools.yml` and look for reference to
    `Define the z1 AWS availability zone`:

    ```
    meta:
      aws:
        azs:
          z1: (( param "Define the z1 AWS availability zone" ))
          z2: (( param "Define the z2 AWS availability zone" ))
          z3: (( param "Define the z3 AWS availability zone" ))
    ```

1. Provide information in the environment template.

    In your environment's folder, you'll now define the three AWS availability
    zones for Vault to use.

    <pre class="terminal">
    cd ~/codex/vault-deployments/aws/prod
    vim networking.yml
    </pre>

    It could look something like this to get you started:

    ```
    ---
    meta:
      aws:
        azs:
          z1: us-west-2a
          z2: us-west-2a
          z3: us-west-2a
    ```

    NOTE: This is not true HA because all of the zones are in one `availability_zone`.  
    This is for instructional purposes only when trying to quickly setup a proof-of-concept.

1. Run `make manifest` again.

    Each time we make a change to a template, to provide settings that replace what
    an error is looking for, we can run `make manifest` again to see if we've correctly
    configured the parameter.

    <pre class="terminal">
    cd ~/codex/vault-deployments/aws/prod
    make manifest
    </pre>

    ![specify_network](/images/specify_network.png)

    Now we can see that less errors are there.


### <a name="toc3"></a> Deploy Vault to infrastructure

### <a name="toc4"></a> Initialize Vault

### <a name="toc5"></a> Disperse keys and configure policies and authentication

### <a name="toc6"></a> Migrate credentials from proto-BOSH manifest into Vault

### <a name="toc7"></a> Re-deploy proto-BOSH (an update) using Vaulted manifests
