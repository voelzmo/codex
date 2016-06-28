# Deploying Proto-BOSH and a Vault

So you've tamed the IaaS and outfitted your bastion host with the
necessary tools to deploy stuff.  First up, we have to deploy a
BOSH director, which we will call proto-BOSH.

Proto-BOSH is a little different from all of the other BOSH
directors we're going to deploy.  For starters, it gets deployed
via `bosh-init`, whereas our environment-specific BOSH directors
are going to be deployed via the proto-BOSH (and the `bosh` CLI).
It is also the only deployment that gets deployed without the
benefit of a pre-existing Vault in which to store secret
credentials (but, as you'll see, we're going to cheat a bit on
that front).

## Proto-Vault

BOSH has secrets.  Lots of them.  Components like NATS and the
database rely on secure passwords for inter-component
interaction.  Ideally, we'd have a spinning Vault for storing our
credentials, so that we don't have them on-disk or in a git
repository somewhere.

However, we are starting from almost nothing, so we don't have the
luxury of using a BOSH-deployed Vault.  What we can do, however,
is spin a single-threaded Vault server instance _on the bastion
host_, and then migrate the credentials to the real Vault later.

The `jumpbox` script that we ran as part of setting up the bastion
host installs the `vault` command-line utility, which includes not
only the client for interacting with Vault, but also the Vault
server daemon itself.

```
$ vault server -dev
==> WARNING: Dev mode is enabled!

In this mode, Vault is completely in-memory and unsealed.
Vault is configured to only have a single unseal key. The root
token has already been authenticated with the CLI, so you can
immediately begin using the Vault CLI.

The only step you need to take is to set the following
environment variables:

    export VAULT_ADDR='http://127.0.0.1:8200'

The unseal key and root token are reproduced below in case you
want to seal/unseal the Vault or play with authentication.

Unseal Key:
781d77046dcbcf77d1423623550d28f152d9b419e09df0c66b553e1239843d89
Root Token: c888c5cd-bedd-d0e6-ae68-5bd2debee3b7

==> Vault server configuration:

         Log Level: info
             Mlock: supported: true, enabled: false
           Backend: inmem
        Listener 1: tcp (addr: "127.0.0.1:8200", tls: "disabled")
           Version: Vault v0.5.0

==> Vault server started! Log data will stream in below:

2016/06/28 13:24:54 [INFO] core: security barrier initialized (shares: 1, threshold 1)
2016/06/28 13:24:54 [INFO] core: post-unseal setup starting
2016/06/28 13:24:54 [INFO] core: mounted backend of type generic at secret/
2016/06/28 13:24:54 [INFO] core: mounted backend of type cubbyhole at cubbyhole/
2016/06/28 13:24:54 [INFO] core: mounted backend of type system at sys/
2016/06/28 13:24:54 [INFO] core: post-unseal setup complete
2016/06/28 13:24:54 [INFO] core: root token generated
2016/06/28 13:24:54 [INFO] core: pre-seal teardown starting
2016/06/28 13:24:54 [INFO] rollback: starting rollback manager
2016/06/28 13:24:54 [INFO] rollback: stopping rollback manager
2016/06/28 13:24:54 [INFO] core: pre-seal teardown complete
2016/06/28 13:24:54 [INFO] core: vault is unsealed
2016/06/28 13:24:54 [INFO] core: post-unseal setup starting
2016/06/28 13:24:54 [INFO] core: mounted backend of type generic at secret/
2016/06/28 13:24:54 [INFO] core: mounted backend of type cubbyhole at cubbyhole/
2016/06/28 13:24:54 [INFO] core: mounted backend of type system at sys/
2016/06/28 13:24:54 [INFO] core: post-unseal setup complete
2016/06/28 13:24:54 [INFO] rollback: starting rollback manager
...
```

(Note: you probably want to run this in a `tmux` session, in the
foreground.  Running it in the background sounds like a fine idea,
except that Vault is pretty chatty, and we can't redirect the
output to `/dev/null` because we need to see that root token.)

With our proto-Vault up and spinning, we can target it:

```
$ safe target proto http://127.0.0.1:8200
Now targeting proto at http://127.0.0.1:8200

$ safe targets

 proto  http://127.0.0.1:8200

$ safe auth token
Authenticating against proto at http://127.0.0.1:8200
Token: <paste your token here>

$ safe set secret/handshake knock=knock
knock: knock

$ safe read secret/handshake
--- # secret/handshake
knock: knock

```

All set!  Now we can deploy our proto-BOSH.

## Proto-BOSH

First, you're going to need a place on the bastion host to store
your deployments:

```
$ mkdir -p ~/ops
$ cd ~/ops
```

Genesis has a template for BOSH deployments (including support for
the proto-BOSH), so let's use that.

```
$ genesis new deployment --template bosh
$ cd bosh-deployments
```

Next, we'll create a site and an environment from which to deploy
our proto-BOSH.  The BOSH template comes with some site templates
to help you get started quickly, including:

- `aws` for Amazon Web Services VPC deployments
- `vsphere` for VMWare ESXi virtualization clusters
- `openstack` for OpenStack tenant deployments

We're going to use `aws`:

```
$ genesis new site --template aws aws
Created site aws (from template aws):
~/ops/docs/bosh-deployments/aws
├── README
└── site
    ├── README
    ├── disk-pools.yml
    ├── jobs.yml
    ├── networks.yml
    ├── properties.yml
    ├── releases
    ├── resource-pools.yml
    ├── stemcell
    │   ├── name
    │   ├── sha1
    │   ├── url
    │   └── version
    └── update.yml

2 directories, 13 files
```

Finally, let's create our new environment, and name it `proto`
(that's `aws/proto`, formally speaking).

```
$ cd aws
Running env setup hook: ~/ops/bosh-deployments/.env_hooks/setup

 proto  http://127.0.0.1:8200

Use this Vault for storing deployment credentials?  [yes or no]
yes
Setting up credentials in vault, under secret/aws/proto/bosh
.
└── secret/aws/proto/bosh
    ├── blobstore/
    │   ├── agent
    │   └── director
    ├── db
    ├── nats
    ├── users/
    │   ├── admin
    │   └── hm
    └── vcap


Created environment aws/proto:
~/ops/bosh-deployments/aws/proto
├── cloudfoundry.yml
├── credentials.yml
├── director.yml
├── Makefile
├── monitoring.yml
├── name.yml
├── networking.yml
├── properties.yml
├── README
└── scaling.yml

0 directories, 10 files
```

The template helpfully generated all new credentials for us and
stored them in our proto-Vault, under the `secret/aws/proto/bosh`
subtree.  Later, we'll migrate this subtree over to our real
Vault, once it is up and spinning.

Let's head into the `proto/` environment directory and see if we
can create a manifest, or (a more likely case) we still have to
provide some critical information:

```
$ cd proto
$ make manifest
19 error(s) detected:
 - $.cloud_provider.properties.aws.access_key_id: Please supply an AWS Access Key
 - $.cloud_provider.properties.aws.default_key_name: What is your full key name?
 - $.cloud_provider.properties.aws.default_security_groups: What Security Groups?
 - $.cloud_provider.properties.aws.region: What AWS region are you going to use?
 - $.cloud_provider.properties.aws.secret_access_key: Please supply an AWS Secret Key
 - $.cloud_provider.ssh_tunnel.private_key: What is the local path to the Amazon Private Key for this deployment?
 - $.compilation.cloud_properties.availability_zone: What Availability Zone will BOSH be in?
 - $.meta.aws.access_key: Please supply an AWS Access Key
 - $.meta.aws.azs.z1: What Availability Zone will BOSH be in?
 - $.meta.aws.region: What AWS region are you going to use?
 - $.meta.aws.secret_key: Please supply an AWS Secret Key
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network
 - $.properties.aws.access_key_id: Please supply an AWS Access Key
 - $.properties.aws.default_key_name: What is your full key name?
 - $.properties.aws.default_security_groups: What Security Groups?
 - $.properties.aws.region: What AWS region are you going to use?
 - $.properties.aws.secret_access_key: Please supply an AWS Secret Key
 - $.properties.shield.agent.authorized_keys: Specify the SSH public key from this environment's SHIELD daemon
 - $.resource_pools.bosh.cloud_properties.availability_zone: What
Availability Zone will BOSH be in?


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Drat.  Luckily, a lot of these are duplicates, most likely from a
`(( grab ... ))` operation.  Let's focus on the `$.meta` subtree,
since that's where most parameters are defined in Genesis
templates:

```
- $.meta.aws.access_key: Please supply an AWS Access Key
- $.meta.aws.azs.z1: What Availability Zone will BOSH be in?
- $.meta.aws.region: What AWS region are you going to use?
- $.meta.aws.secret_key: Please supply an AWS Secret Key
```

(As you can see, I'm using the AWS site for this run-through.  On
other environments, using other templates, your mileage will
vary.)

This is easy enough to supply.  We'll put these properties in
`properties.yml`:

```
$ cat properties.yml
---
meta:
  aws:
    region: us-west-2
    azs:
      z1: (( concat meta.aws.region "b" ))
    access_key: (( vault "secret/proto/aws:access_key" ))
    secret_key: (( vault "secret/proto/aws:secret_key" ))
```

I use the `(( concat ... ))` operator to [DRY][DRY] up the
configuration.  This way, if we need to move the BOSH director to
a different region (for whatever reason) we just change
`meta.aws.region` and the availability zone just tacks on "b".

(We use the "b" availability zone because that's where our subnet
is located.)

I also configured the AWS access and secret keys by pointing
Genesis to the Vault.  Let's go put those credentials in the
Vault:

```
$ safe set secret/aws access_key secret_key
access_key [hidden]:
access_key [confirm]:

secret_key [hidden]:
secret_key [confirm]:

```

Let's try that `make manifest` again.

```
$ make manifest`
7 error(s) detected:
 - $.cloud_provider.properties.aws.default_key_name: What is your full key name?
 - $.cloud_provider.properties.aws.default_security_groups: What Security Groups?
 - $.cloud_provider.ssh_tunnel.private_key: What is the local path to the Amazon Private Key for this deployment?
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network
 - $.properties.aws.default_key_name: What is your full key name?
 - $.properties.aws.default_security_groups: What Security Groups?
 - $.properties.shield.agent.authorized_keys: Specify the SSH public key from this environment's SHIELD daemon


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Better.  Note that we still have some `(( grab ... ))` calls in
there, leading to the duplication.

> Once [issue #129][spruce-129] is fixed, the duplication of
> `(( param ... ))` violations should go away, leading to cleaner
> error messages and a smoother setup process.

Let's configure our `cloud_provider` for AWS, using our EC2
keypair.

```
$ cat properties.yml
---
meta:
  aws:
    region: us-west-2
    azs:
      z1: (( concat meta.aws.region "a" ))
    access_key: (( vault "secret/proto/aws:access_key" ))
    secret_key: (( vault "secret/proto/aws:secret_key" ))

cloud_provider:
  ssh_tunnel:
    private_key: /path/to/the/ec2/key.pem
  properties:
    aws:
      default_key_name: your-ec2-keypair-name
      default_security_groups:
        - restricted
```

Once more, with feeling:

```
$ make manifest
2 error(s) detected:
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network
 - $.properties.shield.agent.authorized_keys: Specify the SSH public key from this environment's SHIELD daemon


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Excellent.  We're down to two issues.

We haven't deployed a SHIELD yet, so it may seem a bit odd that
we're being asked for an SSH public key.  When we deploy our
proto-BOSH via `bosh-init`, we're going to spend a fair chunk of
time compiling packages on the bastion host before we can actually
create and update the director VM.  `bosh-init` will delete the
director VM before it starts this compilation phase, so we will be
unable to do _anything_ while `bosh-init` is hard at work.  The
whole process takes about 30 minutes, so we want to minimize the
number of times we have to re-deploy proto-BOSH.  By specifying
the SHIELD agent configuration up-front, we skip a re-deploy after
SHIELD itself is up.

Let's leverage our Vault to create the SSH keypair for BOSH.
`safe` has a handy builtin for doing this:

```
$ safe ssh secret/aws/proto/shield/keys/core
$ safe get secret/aws/proto/shield/keys/core
--- # secret/aws/proto/shield/keys/core
fingerprint: 40:9b:11:82:67:41:23:a8:c2:87:98:5d:ec:65:1d:30
private: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIEowIBAAKCAQEA+hXpB5lmNgzn4Oaus8nHmyUWUmQFmyF2pa1++2WBINTIraF9
  ... etc ...
  5lm7mGwOCUP8F1cdPmpPNCkoQ/dx3T5mnsCGsb3a7FVBDDBje1hs
  -----END RSA PRIVATE KEY-----
public: |
  ssh-rsa AAAAB3NzaC...4vbnncAYZPTl4KOr
```

(output snipped for brevity and security; but mostly brevity)

Now we can put references to our Vaultified keypair in
`credentials.yml`:

```
$ cat credentials.yml
---
properties:
  shield:
    agent:
      authorized_keys:
        - (( vault "secret/aws/proto/shield/keys/core:public" ))
```

You may want to take this opportunity to migrate
credentials-oriented keys from `properties.yml` into this file.

Now, we should have only a single error left when we `make
manifest`:

```
$ make manifest
1 error(s) detected:
 - $.networks.default.subnets: Specify subnets for your BOSH vm's network


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

So it's down to networking.

Refer back to your [Network Plan](network/plan.md), and find the
subnet for the proto-BOSH.  If you're using the plan in this
repository, that would be `10.4.1.0/24`, and we're allocating
`10.4.1.0/28` to our BOSH director.  Our `networking.yml` file,
then, should look like this:

```
$ cat networking.yml
---
networks:
  - name: default
    subnets:
      - range:    10.4.1.0/24
        gateway:  10.4.1.1
        dns:     [10.4.1.2]
        cloud_properties:
          subnet: subnet-xxxxxxxx
          security_groups: [bosh]
        reserved:
          - 10.4.1.2 - 10.4.1.3    # Amazon reserves these
            # proto-BOSH is in 10.4.1.0/28
          - 10.4.1.16 - 10.4.1.254 # Allocated to other deployments
        static:
          - 10.4.1.4
```

Our range is that of the actual subnet we are in, `10.4.1.0/24`
(in reality, the `/28` allocation is merely a tool of bookkeeping
that simplifies ACLs and firewall configuration).  As such, our
Amazon-provided default gateway is 10.4.1.1 (the first available
IP) and our DNS server is 10.4.1.2.

We identify our AWS-specific configuration under
`cloud_properties`, by calling out what AWS Subnet we want the EC2
instance to be placed in, and what EC2 Security Groups it should
be subject to.

Under the `reserved` block, we reserve the IPs that Amazon
reserves for its own use (see [Amazon's
documentation][aws-subnets], specifically the "Subnet sizing"
section), and everything outside of `10.4.1.0/28` (that is,
`10.4.1.16` and above).

Finally, in `static` we reserve the first usable IP (`10.4.1.4`)
as static.  This will be assigned to our `bosh/0` director VM.

Now, `make manifest` should succeed (no output is a good sign),
and we should have a full manifest at `manifests/manifest.yml`:

```
$ make manifest
$ ls -l manifests/
total 8
-rw-r--r-- 1 jhunt staff 4572 Jun 28 14:24 manifest.yml
```

All that's left is to try to deploy it:

> TODO: I had to `echo bosh-init > .type` to engage the bosh-init
> style of deployment.  How do we want to handle that?  Does
> Genesis need an update for a `--type` flag to `new env`?

> TODO: i also had to copy the aws key up to the bastion host.

```
$ make deploy
No existing genesis-created bosh-init statefile detected. Please
help genesis find it.
Path to existing bosh-init statefile (leave blank for new
deployments):
Deployment manifest: '~/ops/bosh-deployments/aws/proto/manifests/.deploy.yml'
Deployment state: '~/ops/bosh-deployments/aws/proto/manifests/.deploy-state.json'

Started validating
  Downloading release 'bosh'... Finished (00:00:09)
  Validating release 'bosh'... Finished (00:00:03)
  Downloading release 'bosh-aws-cpi'... Finished (00:00:02)
  Validating release 'bosh-aws-cpi'... Finished (00:00:00)
  Downloading release 'shield'... Finished (00:00:10)
  Validating release 'shield'... Finished (00:00:02)
  Validating cpi release... Finished (00:00:00)
  Validating deployment manifest... Finished (00:00:00)
  Downloading stemcell... Finished (00:00:01)
  Validating stemcell... Finished (00:00:00)
Finished validating (00:00:29)
...
```

(At this point, `bosh-init` starts the tedious process of
compiling all the things.  End-to-end, this is going to take about
a half an hour, so you probably want to go play [a game][slither]
or grab a cup of tea.)

...

All done?  Verify the deployment by trying to `bosh target` the
newly-deployed Director.  First you're going to need to get the
password out of our proto-Vault.

```
$ safe get secret/aws/proto/bosh/users/admin
--- # secret/mgmt/proto/bosh/users/admin
password: super-secret
```

Then, run target the director:

```
$ bosh target https://10.4.1.4:25555 proto-bosh
Target set to `aws-proto-bosh'
Your username: admin
Enter password:
Logged in as `admin'

$ bosh status
Config
             ~/.bosh_config

Director
  Name       aws-proto-bosh
  URL        https://10.4.1.4:25555
  Version    1.3232.2.0 (00000000)
  User       admin
  UUID       a43bfe93-d916-4164-9f51-c411ee2110b2
  CPI        aws_cpi
  dns        disabled
  compiled_package_cache disabled
  snapshots  disabled

Deployment
  not set
```

All set!

Before you move onto the next step, you should commit your local
deployment files to version control, and push them up _somewhere_.
It's ok, thanks to Vault, there are no credentials or anything
sensitive in the Genesis template files.

## Vault

Now that we have a proto-BOSH director, we can use it to deploy
our real Vault.  We'll start with the Genesis template for Vault:

```
$ cd ~/ops
$ genesis new deployment --template vault
$ cd vault-deployments
```

As before (and as will become almost second-nature soon), let's
create our `aws` site using the `aws` template, and then create
the `proto` environment inside of that site.

```
$ genesis new site --template aws aws
$ genesis new environment aws proto
$ cd aws/proto
$ make manifest
10 error(s) detected:
 - $.compilation.cloud_properties.availability_zone: Define the z1 AWS availability zone
 - $.meta.aws.azs.z1: Define the z1 AWS availability zone
 - $.meta.aws.azs.z2: Define the z2 AWS availability zone
 - $.meta.aws.azs.z3: Define the z3 AWS availability zone
 - $.networks.vault_z1.subnets: Specify the z1 network for vault
 - $.networks.vault_z2.subnets: Specify the z2 network for vault
 - $.networks.vault_z3.subnets: Specify the z3 network for vault
 - $.resource_pools.small_z1.cloud_properties.availability_zone: Define the z1 AWS availability zone
 - $.resource_pools.small_z2.cloud_properties.availability_zone: Define the z2 AWS availability zone
 - $.resource_pools.small_z3.cloud_properties.availability_zone: Define the z3 AWS availability zone


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

Vault is pretty self-contained, and doesn't have any secrets of
its own.  All you have to supply is your network configuration,
and any IaaS settings.

Referring back to our [Network Plan][network/plan.md] again, we
find that Vault should be striped across three zone-isolated
networks:

  - *10.4.1.16/28* in zone 1 (a)
  - *10.4.2.16/28* in zone 2 (b)
  - *10.4.3.16/28* in zone 3 (c)

First, lets do our AWS-specific region/zone configuration:

```
$ cat properties.yml
---
meta:
  aws:
    region: us-west-2
    azs:
      z1: (( concat meta.aws.region "a" ))
      z2: (( concat meta.aws.region "b" ))
      z3: (( concat meta.aws.region "c" ))
```

Our `/28` ranges are actually in their corresponding `/24` ranges
because the `/28`'s are (again) just for bookkeeping and ACL
simplification.  That leaves us with this for our
`networking.yml`:

```
$ cat networking.yml
---
networks:
  - name: vault_z1
    subnets:
      - range:    10.4.1.0/24
        gateway:  10.4.1.1
        dns:     [10.4.1.2]
        cloud_properties:
          subnet: subnet-xxxxxxxx
          security_groups: [bosh]
        reserved:
          - 10.4.1.2 - 10.4.1.3    # Amazon reserves these
          - 10.4.1.4 - 10.4.1.15   # Allocated to other deployments
            # Vault (z1) is in 10.4.1.16/28
          - 10.4.1.32 - 10.4.1.254 # Allocated to other deployments
        static:
          - 10.4.1.16 - 10.4.1.18

  - name: vault_z2
    subnets:
      - range:    10.4.2.0/24
        gateway:  10.4.2.1
        dns:     [10.4.2.2]
        cloud_properties:
          subnet: subnet-yyyyyyyy
          security_groups: [bosh]
        reserved:
          - 10.4.2.2 - 10.4.2.3    # Amazon reserves these
          - 10.4.2.4 - 10.4.2.15   # Allocated to other deployments
            # Vault (z2) is in 10.4.2.16/28
          - 10.4.2.32 - 10.4.2.254 # Allocated to other deployments
        static:
          - 10.4.2.16 - 10.4.2.18

  - name: vault_z3
    subnets:
      - range:    10.4.3.0/24
        gateway:  10.4.3.1
        dns:     [10.4.3.2]
        cloud_properties:
          subnet: subnet-zzzzzzzz
          security_groups: [bosh]
        reserved:
          - 10.4.3.2 - 10.4.3.3    # Amazon reserves these
          - 10.4.3.4 - 10.4.3.15   # Allocated to other deployments
            # Vault (z3) is in 10.4.3.16/28
          - 10.4.3.32 - 10.4.3.254 # Allocated to other deployments
        static:
          - 10.4.3.16 - 10.4.3.18
```

That's a ton of configuration, but when you break it down it's not
all that bad.  We're defining three separate networks (one for
each of the three availability zones).  Each network has a unique
AWS Subnet ID, but they share the same EC2 Security Groups, since
we want uniform access control across the board.

The most difficult part of this configuration is getting the
reserved ranges and static ranges correct, and self-consistent
with the network range / gateway / DNS settings.  This is a bit
easier since our network plan allocates a different `/24` to each
zone network, meaning that only the third octet has to change from
zone to zone (x.x.1.x for zone 1, x.x.2.x for zone 2, etc.)

Now, let's try a `make manifest` again (no output is a good sign):

```
$ make manifest
```

And then we can deploy via the proto-BOSH director:

```
$ make deploy
Acting as user 'admin' on 'aws-proto-bosh'
Checking whether release consul/20 already exists...NO
Using remote release `https://bosh.io/d/github.com/cloudfoundry-community/consul-boshrelease?v=20'

Director task 1

```

Thanks to Genesis, we don't even have to upload the BOSH releases
(or stemcells) ourselves!

TODO: start here


## Migrating Credentials

You should now have two `safe` targets, one for the proto-Vault
(named 'proto') and another for the real Vault (named 'ops'):

```
$ safe targets
TODO
```

Our `ops` Vault should be empty; we can verify that with `safe
tree`:

```
$ safe target ops -- tree
TODO
```

`safe` sports a handy import/export feature that can be used to
move credentials securely between Vaults, without touching disk,
which is exactly what we need to migrate from our proto-Vault to
our real one:

```
$ safe target proto -- export secret |\
  safe target ops   -- import
TODO
$ safe target ops -- tree
```

Voila!  We now have all of our credentials in our real Vault, and
we can kill the proto-Vault server process!

```
$ sudo pkill vault
```

Next: [Deploying Bolo Monitoring][bolo.md]

[DRY]:         https://en.wikipedia.org/wiki/Don%27t_repeat_yourself
[spruce-129]:  https://github.com/geofffranks/spruce/issues/129
[aws-subnets]: http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html
[slither]:     http://slither.io
