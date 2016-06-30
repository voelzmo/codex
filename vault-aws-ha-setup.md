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


