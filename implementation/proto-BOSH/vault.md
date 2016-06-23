## Setup Vault

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
    cd ~/codex/vault-deployments/aws
    genesis new environment aws prod
    </pre>

### Use `genesis` to build manifest

Now that we've defined a deployment (vault), a site (aws) and an environment (prod)
we can combine those layers into a specific deployment for BOSH.

1. Determine necessary configuration changes.

    In order to determine what configuration changes need to be made run `make manifest`
    in the environment folder.

    <pre class="terminal">
    cd ~/codex/vault-deployments/aws/prod
    make manifest
    </pre>

    See figure below for example:

    ![make_manifest_example](/images/make_manifest_example.png)

    We want our Vault to be HA by using Consul and assigning it three IP
    addresses across availability zones.

    For example in the `networking.yml` file we can give three static IP
    addresses to the vault deployment by defining them with the `static` list in
    the `networks` dictionary.

    ```
    ---
    networks:
      - name: vault
        type: manual
        subnets:
        - range: 10.10.2.0/24
          gateway: 10.10.2.1
          cloud_properties:
            subnet: subnet-0ab12c3d
            security_groups: [sg-efgd5678]
          dns: [10.10.2.2]
          reserved:
            - 10.10.2.2 - 10.10.2.191
          static:
            - 10.10.2.192 - 10.10.2.194 # first 3

    jobs:
      - name: vault
        networks:
          - name: vault
            static_ips: (( static_ips 0 1 2 ))
    ```

### Use proto-BOSH to deploy Vault

1. Initialize Vault, disperse keys and configure policies / authentication

1. Migrate credentials from proto-BOSH manifest into Vault

1. Re-deploy proto-BOSH (an update) using Vaulted manifests
