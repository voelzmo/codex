# Vault

1. [Best Practices](#toc1)
1. [High Availability](#toc2)
  1. [High Availability Storage Backends](#toc3)
1. [Unsealing a High Availability Vault](#toc4)

## <a name="toc1"></a> Best Practices

* One Vault or One Vault Per Environment

This may not be possible because of security requirement preconditions or network topology.  In these cases place the additional Vault deployments as high as possible in the environment structure.

* Be consistent with a descriptive, reusable and unique path

For example here's the path to the BOSH admin password:

```
$ safe get secret/aws/proto/bosh/users/admin
```

* Keep related data together

```
$ safe set secret/aws access_key secret_key
```

## <a name="toc2"></a> High Availability

Vault provides an active/passive [high availability(HA)][ha] service using shared storage across the nodes. Vault recommends using Consul to provide its HA capability.

The passive nodes will forward all requests to the active node. This means Vault ports (default 8200) need to be open across availability zones.  The default Vault port is 8200.

>It is important to note that only **unsealed** servers act as a standby. If a server is still in the sealed state, then it cannot act as a standby as it would be unable to serve any requests should the active server fail.

All Vaults nodes need to be running the same version since we do not if there are storage structure changes.  The [upgrade path][upgrade] could be tricky since Vault does not support zero downtime deployments.

> Please note that Vault **does not support** true zero-downtime upgrades, but with proper upgrade procedure the downtime should be very short (a few hundred milliseconds to a second depending on how the speed of access to the storage backend).

### <a name="toc3"></a> High Availability Storage Backends

HA Storage Backends | Supported By
------------------- | -------------
             consul | Hashicorp
               etcd | Community
          zookeeper | Community
           dynamodb | Community

The following storage backends exist for Vault, but do not have a HA option:

  * S3
  * Azure
  * Swift
  * Mysql
  * Postgresql
  * Inmem
  * file

## <a name="toc4"></a> Unsealing a High Availability Vault

```
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

Vault uses [Shamir's Secret Sharing](https://www.vaultproject.io/docs/concepts/seal.html) algorithm to split and recreate a master key.  Once enough shards of the key are given, the master key will unseal the Vault.


$ ls
codex  vault-proto-info

$ vi vault-prod-info
#**************************************************
# copied and pasted keys into vault-prod-info file
# fubar if you lose these values.
#**************************************************

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

[ha]:      https://www.vaultproject.io/docs/internals/high-availability.html
[upgrade]: https://www.vaultproject.io/docs/install/upgrade.html
