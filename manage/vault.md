[README](../README.md) > [Management Environment](../manage.md) > manage/**vault**

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

    ```
    $ mkdir -p ~/ops
    $ cd ~/ops
    $ genesis new deployment --template vault
    ```

1. For our deployment, generate a site from a template.  This can be a name of your infrastructure provider or datacenter location.

    ```
    $ cd vault-deployments/
    $ genesis new site --template aws aws
    ```

1. Using our site, create an environment.  For instance, if we're creating the `prod` for Production in the "aws" site, we'd run:

    ```
    $ cd aws/
    $ genesis new environment aws prod
    ```

### <a name="toc2"></a> Merge template files together

Next we use the tool called `spruce` to merge the `genesis` template together into
a single manifest that BOSH will use to deploy Vault.

This process is an iterative process of beginning in the `environment` folder where
the `Makefile` exists. Run the command `make manifest` to attempt to generate the
deployment manifest then pay attention to the resulting output.

Once this process is complete running `make manifest` will exit `0` and have generated
a manifest file that can be used to deploy Vault.

1. Run the `make manifest` command from the `~/ops/vault-deployments/aws/prod` folder.

    ```
    $ make manifest
    ```

    This will either build a manifest file for you or it will tell you what you
    need to fix before it can build a working manifest.

    ![make_manifest_example](/images/make_manifest_example.png)

1. Read and understand the errors.

    A recommended method to iterate through these errors is to take the first message,
    open a new connection in the root of deployment project and look for what the error
    is referencing.

    Use the first error:

    ```
    $.compilation.cloud_properties.availability_zone: Define the z1 AWS availability zone
    ```

    Search for the error from the root of the project.

    ```
    $ cd ~/ops/vault-deployments
    $ grep -e 'Define the z1 AWS availability zone' -ir
    ```

    ![search_example](/images/search_example.png)

    You will see dot directory names like .global, .site and .templates in your deployment directory.
    These directories are used by the tools for additional data input  or for the generated output.
    THese directories should be ignored even if a match is found.   If the noise bothers you can have grep
    ignore those directories.

    ```
    grep -Ri --exclude-dir='\.[a-z]*|bin' -e <pattern>
    ```

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

1. Provide values for error in environment template.

    In your environment's folder, you'll now define the three AWS availability
    zones for Vault to use.

    ```
    $ cd ~/ops/vault-deployments/aws/prod
    $ vim networking.yml
    ```

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

    ```
    $ cd ~/ops/vault-deployments/aws/prod
    $ make manifest
    ```

    ![specify_network](/images/specify_network.png)

    Less errors!

    Run the above steps to "Read and understand the errors" and "Provide values for error in environment template."

    Recommended network settings are:

    ```
    networks:
    - name: vault_z1
      type: manual

      subnets:
      - range:   10.4.1.16/28
        gateway: 10.4.1.16
        dns:     [10.4.1.2]

        reserved:
        - 10.4.1.2-10.4.1.18
        static:
        - 10.4.1.3

        cloud_properties: {subnet: subnet-0ae85b7c}

    - name: vault_z2
      type: manual

      subnets:
      - range:   10.10.2.0/24
        gateway: 10.10.2.1
        dns:     [10.10.0.2]

        reserved:
        - 10.10.2.2-10.10.2.10
        static:
        - 10.10.2.193

        cloud_properties: {subnet: subnet-0ae85b7c}

    - name: vault_z3
      type: manual

      subnets:
      - range:   10.10.2.0/24
        gateway: 10.10.2.1
        dns:     [10.10.0.2]

        reserved:
        - 10.10.2.2-10.10.2.10
        static:
        - 10.10.2.194

        cloud_properties: {subnet: subnet-0ae85b7c}    
    ```

1. Repeat until `make manifest` doesn't error

  Once `make manifest` produces no errors, it instead creates a manifest file in the
`~/ops/vault-deployments/aws/prod/manifests/manifest.yml` which will be used in the
next step.

### <a name="toc3"></a> Deploy Vault to infrastructure

1. To begin the process of deploying we'll run `make deploy` and we'll get back any errors of what's missing.

    Here's what's required to do a vault release:

    ```
    $ bosh upload release https://bosh.io/d/github.com/cloudfoundry-community/consul-boshrelease?v=20
    $ bosh upload release https://bosh.io/d/github.com/cloudfoundry-community/vault-boshrelease?v=0.4.0
    $ bosh upload stemcell https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3232.8
    ```

    To find a version URL go to [http://bosh.io/releases](http://bosh.io/releases), find the release and pay attention to the version.

### <a name="toc4"></a> Initialize Vault

1. Target the vault server with `safe`.


    ```
    $ safe target "http://10.10.2.192:8200" prod
    ```

1. We're going to run the `init` command which will output the keys we need to unseal the vault.

    ```
    $ safe vault init
    ```

    Take note of the output the five keys and `Initial Root Token`.  They will be required as input next.

1. Unseal the vault, you'll need to use at least three of the five unique keys.

   Vault uses [Shamir's Secret Sharing](https://www.vaultproject.io/docs/concepts/seal.html) algorithm to split and recreate a master key.  Once enough shards of the key are given, the master key will unseal the vault.

    ```
    $ safe vault unseal
    $ safe vault unseal
    $ safe vault unseal
    ```

1. Now we're ready to use the `Initial Root Token` to authenticate to vault.

    ```
    $ safe auth
    ```

1. Verify you can work with an unsealed vault.

    ```
    $ safe set secret/handshake initialized=true
    initialized: true
    $ safe tree
    .
    └── secret
        └── handshake
    $ safe get secret/handshake
    --- # secret/handshake
    initialized: "true"
    ```

### <a name="toc5"></a> Disperse keys and configure policies and authentication

TODO: @jhunt or @geofffranks how do we do this?

### <a name="toc6"></a> Migrate credentials from proto-BOSH manifest into Vault

TODO: @jhunt or @geofffranks how do we do this?

### <a name="toc7"></a> Re-deploy proto-BOSH (an update) using Vaulted manifests

TODO: @jhunt or @geofffranks how do we do this?
