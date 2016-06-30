# Vault

Vault provides an active/passive high availability(HA) service using shared
storage across the nodes. Vault recommends using Consul to provide its HA capability.
The passive nodes will forward all requests to the active node. This means vault ports (default 82000) need to be open across availability zones.

All Vaults nodes need to be running the same version since we do not if there
are storage structure changes.  The upgrade path could be tricky since Vault does not support zero downtime deployments.

Vault documentation is actually written quite well.  Instead of regurgitating
it all, I will quote their docs and point you to their page where I found information..

https://www.vaultproject.io/docs/internals/high-availability.html
> Certain storage backends, such as Consul, provide additional coordination functions that enable Vault to run in an HA configuration. When supported by the backend, Vault will automatically run in HA mode without additional configuration.

> When running in HA mode, Vault servers have two additional states they can be in: standby and active. For multiple Vault servers sharing a storage backend, only a single instance will be active at any time while all other instances are hot standbys.

 https://www.vaultproject.io/docs/internals/high-availability.html
>The active server operates in a standard fashion and processes all requests. The standby servers do not process requests, and instead redirect to the active Vault. Meanwhile, if the active server is sealed, fails, or loses network connectivity then one of the standbys will take over and become the active instance.

>It is important to note that only ***unsealed*** servers act as a standby. If a server is still in the sealed state, then it cannot act as a standby as it would be unable to serve any requests should the active server fail.

https://www.vaultproject.io/docs/install/upgrade.html
> Please note that Vault ***does not support** true zero-downtime upgrades, but with proper upgrade procedure the downtime should be very short (a few hundred milliseconds to a second depending on how the speed of access to the storage backend).

https://www.vaultproject.io/docs/config/
>Please note: The only physical backends actively maintained by HashiCorp are **consul**, inmem, and file. The other backends are community-derived and community-supported. We include them in the hope that they will be useful to those users that wish to utilize them, but they receive minimal validation and testing from HashiCorp, and HashiCorp staff may not be knowledgeable about the data store being utilized. If you encounter problems with them, we will attempt to help you, but may refer you to the backend author.


HA Storage Backends | Supported BY
------------ | -------------
consul | Hashicorp
etcd |  Community
zookeeper | Community
dynamodb | Community

No HA support for the following storage backends:

1. S3
2. Azure
3. Swift
4. Mysql
5. Postgresql
6. Inmem
7. file

# Commands used to activate Vault

```bash
$ safe targets

 proda  http://10.30.1.16:8200
 prodb  http://10.30.2.16:8200
 prodc  http://10.30.3.16:8200
 proto  http://127.0.0.1:8200

$ safe target proda
Now targeting proda at http://10.30.1.16:8200
$ safe vault status
Error checking seal status: Error making API request.


Key 1: 04f3bf668a9e9741d14afe03666cef4ad778382a44b21200b0e721bd2c78c18a01

URL: GET http://10.30.1.16:8200/v1/sys/seal-status
Code: 400. Errors:

* server is not yet initialized
!! exit status 1
$ safe vault init
Key 1: 04f3bf668a9e9741d14afe03666cef4ad778382a44b21200b0e721bd2c78c18a01
Key 2: a5cab4dc25f25eb8b0ef6d12ca4799f1b9b75d4b2029999596d2ca3757f80dfa02
Key 3: 2db8d11844e6668dcb9e3bd3ba96c931f838ce4866e408d6109d07ce1ddc7d4003
Key 4: 569da0c75c216459035086464545ddd14a785d66c8a23baf87e10afca692b91d04
Key 5: deefc5033d355c6c7821d08735948d110bf7ce658e6faaec01aec705ecb6c9a705
Initial Root Token: eb4e2ab1-fd69-324b-8c68-6bd8524d3df0

Vault initialized with 5 keys and a key threshold of 3. Please
securely distribute the above keys. When the Vault is re-sealed,
restarted, or stopped, you must provide at least 3 of these keys
to unseal it again.

Vault does not store the master key. Without at least 3 keys,
your Vault will remain permanently sealed.
$ ls
codex  vault-proto-info
$ vi vault-prod-info
#**************************************************
# copied and pasted keys into vault-prod-info file
# fubar if you lose these values.
#**************************************************
$ vault --help unseal
Usage: vault unseal [options] [key]

  Unseal the vault by entering a portion of the master key. Once all
  portions are entered, the Vault will be unsealed.

  Every Vault server initially starts as sealed. It cannot perform any
  operation except unsealing until it is sealed. Secrets cannot be accessed
  in any way until the vault is unsealed. This command allows you to enter
  a portion of the master key to unseal the vault.

  The unseal key can be specified via the command line, but this is
  not recommended. The key may then live in your terminal history. This
  only exists to assist in scripting.

General Options:

  -address=addr           The address of the Vault server.
                          Overrides the VAULT_ADDR environment variable if set.

  -ca-cert=path           Path to a PEM encoded CA cert file to use to
                          verify the Vault server SSL certificate.
                          Overrides the VAULT_CACERT environment variable if set.

  -ca-path=path           Path to a directory of PEM encoded CA cert files
                          to verify the Vault server SSL certificate. If both
                          -ca-cert and -ca-path are specified, -ca-path is used.
                          Overrides the VAULT_CAPATH environment variable if set.

  -client-cert=path       Path to a PEM encoded client certificate for TLS
                          authentication to the Vault server. Must also specify
                          -client-key.  Overrides the VAULT_CLIENT_CERT
                          environment variable if set.

  -client-key=path        Path to an unencrypted PEM encoded private key
                          matching the client certificate from -client-cert.
                          Overrides the VAULT_CLIENT_KEY environment variable
                          if set.

  -tls-skip-verify        Do not verify TLS certificate. This is highly
                          not recommended.  Verification will also be skipped
                          if VAULT_SKIP_VERIFY is set.

Unseal Options:

  -reset                  Reset the unsealing process by throwing away
                          prior keys in process to unseal the vault.
!! exit status 1
$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 1
$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 2
$ safe vault unseal
Key (will be hidden):
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0
$ safe vault status
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: active
    Leader: http://10.30.1.16:8200
$ safe target prodb
Now targeting prodb at http://10.30.2.16:8200
$ safe vault status
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: sealed
!! exit status 2
$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 1
$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 2
$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0
$ safe vault status
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: standby
    Leader: http://10.30.1.16:8200
$ safe target prodc
Now targeting prodc at http://10.30.3.16:8200
$ safe vault status
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: sealed
!! exit status 2
$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 1
$ safe vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 3
Unseal Progress: 2
$ safe vault unseal
Key (will be hidden):
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0
$ safe vault status
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: standby
    Leader: http://10.30.1.16:8200

#**********************************
# Now showing things are proper now
#**********************************
$ safe target proda
Now targeting proda at http://10.30.1.16:8200
$ safe vault status
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: active
    Leader: http://10.30.1.16:8200
$ safe target prodb
Now targeting prodb at http://10.30.2.16:8200
$ safe vault status
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: standby
    Leader: http://10.30.1.16:8200
$ safe target prodc
Now targeting prodc at http://10.30.3.16:8200
$ safe vault status
Sealed: false
Key Shares: 5
Key Threshold: 3
Unseal Progress: 0

High-Availability Enabled: true
    Mode: standby
    Leader: http://10.30.1.16:8200


$ safe target proto
Now targeting proto at http://127.0.0.1:8200
$ safe export secret >proto.sercrests
$ safe target proda
Now targeting proda at http://10.30.1.16:8200
$ safe import <proto.secrests
wrote secret/aws/proto/bosh/blobstore/director
wrote secret/aws/proto/bosh/nats
wrote secret/aws/proto/bosh/users/admin
wrote secret/handshake
wrote secret/aws/proto/bosh/blobstore/agent
wrote secret/aws/proto/bosh/db
wrote secret/aws/proto/bosh/users/hm
wrote secret/aws/proto/bosh/vcap
wrote secret/aws/proto/shield/keys/core
$ safe tree
.
└── secret
    ├── aws/
    │   └── proto/
    │       ├── bosh/
    │       │   ├── blobstore/
    │       │   │   ├── agent
    │       │   │   └── director
    │       │   ├── db
    │       │   ├── nats
    │       │   ├── users/
    │       │   │   ├── admin
    │       │   │   └── hm
    │       │   └── vcap
    │       └── shield/
    │           └── keys/
    │               └── core
    └── handshake
```

## Vault Best Practices

Our best practice is to have a single vault/safe for all deployment environments.
This may not be possible because of security requirement preconditions or network topology.
In these cases place the additional vault deployments as high as possible in the
platform/global/site/environment structure.

Do not take shortcuts on the vault paths.   Use the fullest path necessary to define your secret.
The path should correespond as if you only had one vault for your secrets.
It will make things easier if the vault data needs to be combined or split out into different vaults over time.

TBD Do we want a best practice on path ordering?
* deployment/platform/global/site/environment/manifest:key
* platform/global/site/environment/deployment/manifest:key
* many other choices

Consider using a key name that matches to the manifest key name.  Make it easy for the next person to recognize the usage just by looking at its path and keyname.  The manifest level could be made part of the path or incorporated into the key name.

Stay consistent with the path and keyname style already used in the a deployment manifest.   The inconsistency drives us ADD types crazy and it looks unprofessional.

Avoid placing multiple secrets under the same path and key.  Secret rotation is easier if there is
only one secret to worry about.

Do your best to have single definition for your secret.   This will simplify the process when
secrets needs to be rotated.  When this is not possible because we are using multiple vaults,
, create some documentation right away about secret dependency.  Failures will occur quickly if the duplicated
secret values get out of synced.

Consider placing related secret data such as username and host address in the vault under the same path as the secret.   It should avoid manually updating all the various deployments if that data is duplicated in the manifest files.

## Setup Cloud Foundry

Cloud Foundry uses Consul by Hashicorp for various purposes, but its
distributed datacenter high availability that needs some extra explanation.
Many high availability software packages allows you to run with a single
node cluster for its degraded mode. Consul does not. Consul defines an available cluster by having a quorum of nodes defined by the following formula (nodes/2) + 1 >= 2
If you do not have at least two nodes in your cluster, your cluster does
not have a quorum and your cluster is marked unavailable.

Even in a two node configuration, you do not have high availability
since one node going down means you do not have a quorum and thus no cluster.
So you need at least three nodes to have high availability. Consul's degraded mode is a two node cluster.

What does mean for running cloud foundry on Amazon Web Services?
You will want to have three availability zones.
An availability zone is an independent datacenter (power, machines, networking, etc) but also has low latency network to its sister availability zones.
An availability zone corresponds to the Consul cluster node.

If you define the three cloud foundry instances in only two
availability zones, you have some minimal level of high availability
It is not the strongest strongest high availability since losing an availability zone that has the two cloud foundry instances would make Consul lose its quorum.

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
