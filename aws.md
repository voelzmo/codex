# Deploying on AWS

So you want to deploy Cloud Foundry to good old Amazon Web
Services eh?  Good on you!

## Setting up an AWS VPC

## A Little Prep Goes A Long Way

To get started, you're going to need an AWS account, and four
pieces of information to get started:

1. Your AWS Access Key ID
2. Your AWS Secret Key ID
3. A Name for your VPC (you'll just make this up)
4. An EC2 Key Pair

### Generate an AWS Access Key / Secret Key

The first thing you're going to need is a combination Access Key
ID / Secret Key ID.  These are generated (for IAM users) via the
IAM dashboard.  If you aren't using IAM for this, you really
should.

On the AWS web console, access the IAM service, and click on
`Users` in the sidebar.  Then, find the user you want to do your
deployment / configuration under, and click on the username.

This should bring up a summary of the user with things like the
_User ARN_, _Groups_, etc.  In the bottom half of the Summary
pane, you should see some tabs, and one of those tabs should be
_Security Credentials_.  Click on that one.

You are strongly encouraged to generate a new Access Key, using
the big blue button, for each VPC you deploy, even if you use the
same IAM user for all of them.

**Make sure you save the secret key somewhere safe**, like
1password or a Vault instance.  Amazon will be unable to give you
the Secret Key ID if you misplace it -- your only recourse at that
point is to generate a new set of keys and start over.

### Name Your VPC

This step is really simple -- just make one up.  The VPC name will
be used to prefix all of the Network ACLs, Subnets and Security
Groups, so that you can have multiple VPCs under one account
without going cross-eyed trying to keep them separate.

### Generate an EC2 Key Pair

The Access Key / Secret Key is used to get access to the Amazon
Web Services themselves.  In order to properly deploy the NAT and
Bastion Host instances to EC2, you're going to need an EC2
Key Pair.  This is the key pair you're going to need to use to SSH
into the instances.

Starting from the main Amazon Web Console, go to Service > EC2,
and then click the _Key Pairs_ link under _Network & Security_.
The big blue `Create Key Pair` button.  Make a note of the name
you chose for the key pair, because we're going to need that for
our Terraform configuration.

**N.B.**: Make sure you are in the correct region (top-right
corner of the black menu bar) when you create your EC2 Key Pair.
Otherwise, it just plain won't work.

## Terraform

Now we can put it all together and build out your shiny new VPC in
Amazon.  For this step, you're going to want to be in the
`terraform/aws` sub-directory of this repository.  This Terraform
configuration directly matches the [Network Plan][netplan]
for the demo environment.  For deploying in production, you may
need to tweak or rewrite.

Start with the following `aws.tfvars` file:

```
aws_access_key = "..."
aws_secret_key = "..."
aws_vpc_name = "my-new-vpc"
aws_key_name = "bosh-ec2-key"
```

(substituting your actual values, of course)

If you need to change the region or subnet, you can override the defaults by adding

```
aws_region = "us-east-1"
network = "10.42"
```

As a quick pre-flight check, run `make manifest` to compile your
Terraform plan and suss out any issues with naming, missing
variables, configuration, etc.:

```
$ make manifest
terraform get -update
terraform plan -var-file aws.tfvars -out aws.tfplan
Refreshing Terraform state prior to plan...

<snip>

Plan: 33 to add, 0 to change, 0 to destroy.
```

If everything worked out you should se a summary of the plan.  If
this is the first time you've done this, all of your changes
should be additions.  The numbers may differ from the above
output, and that's okay.

Now, to pull the trigger, run `make deploy`:

```
$ make deploy
```

Terraform will connect to AWS, using your Access Key and Secret
Key, and spin up all the things it needs.  When it finishes, you
should be left with a bunch of subnets, configured network ACLs,
security groups, routing tables, a NAT instance (for public
internet connectivity) and a Bastion host.

If the `deploy` step fails with errors like:

```
 * aws_subnet.prod-cf-edge-1: Error creating subnet: InvalidParameterValue: Value (us-east-1a) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-east-1c, us-east-1e, us-east-1b, us-east-1d.
	status code: 400, request id: 8ddbe059-0818-48c2-a936-b551cd76cdeb
 * aws_subnet.prod-infra-1: Error creating subnet: InvalidParameterValue: Value (us-east-1a) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-east-1c, us-east-1b, us-east-1d, us-east-1e.
	status code: 400, request id: 876f72b2-6bda-4499-98c3-502d213635eb
* aws_subnet.dev-infra-3: Error creating subnet: InvalidParameterValue: Value (us-east-1a) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-east-1c, us-east-1b, us-east-1d, us-east-1e.
	status code: 400, request id: 66fafa81-7718-46eb-a606-e4b98e3267b9
```

you should run `make destroy` to clean up, then add a line like `aws_az1 = "d"` to replace the restricted zone.

## Setting up the Bastion Host

The bastion host is an access point virtual machine that your IaaS
instrumentation layer (probably Terraform) should have provisioned
for you.  As such, you probably will need to consult with your
IaaS provider to figure out what IP address the bastion host can
be accessed at.  For example, on AWS, find the `bastion` EC2
instance and note its Elastic IP address.

You're going to need to SSH into the bastion host (as the `ubuntu`
user), and unfortunately, that is also provider-specific.  In AWS,
you'll just SSH to the Elastic IP, using the private half of the
EC2 keypair you generated.  Other IaaS's may have other
requirements.

You can check your SSH keypair by comparing the Amazon fingerprints.  

On the Web UI, you can check the uploaded key on the [key page][amazon-keys].

If you prefer the Amazon CLI, you can run (replacing bosh with your key name):

```
$ aws ec2 describe-key-pairs --region us-east-1 --key-name bosh|JSON.sh -b| grep 'KeyFingerprint'|awk '{ print $2 }' -
"05:ad:67:04:2a:62:e3:fb:e6:0a:61:fb:13:c7:6e:1b"
$
```

You check your private key you are using with:

```
$ openssl pkey -in ~/.ssh/bosh.pem -pubout -outform DER | openssl md5 -c
(stdin)= 05:ad:67:04:2a:62:e3:fb:e6:0a:61:fb:13:c7:6e:1b
$
```

(on OS X you need to `brew install openssl` to get OpenSSL 1.0.x and use that version)

Once on the bastion host, you'll want to use the `jumpbox` script,
which you can get off of Github, like so:

```
$ sudo curl -o /usr/local/bin/jumpbox \
    https://raw.githubusercontent.com/jhunt/jumpbox/master/bin/jumpbox
$ sudo chmod 0755 /usr/local/bin/jumpbox
```

Script in hand, you can go ahead and prepare the system with
globally available utilities:

```
$ sudo jumpbox system
```

That should install some useful utilities like `jq`, `spruce`,
`safe`, and `genesis` all of which will be important when we start
using the bastion host to do deployments.

Next up, you're going to want to provision some normal user
accounts on the bastion host, so that operations staff can login
via named accounts:

```
$ jumpbox useradd
Full name: Joe User
Username:  juser
sudo password for ubuntu:
You should run `jumpbox user` now, as juser:
  sudo -iu juser
  jumpbox user

$ sudo -iu juser
$ jumpbox user
<snip>
$ mkdir ~/.ssh
$ vim ~/.ssh/authorized_keys
$ chmod 600 ~/.ssh/authorized_keys
$ logout
```

Using named accounts provides auditing (via the `sudo` logs),
isolation (people won't step on each others toes on the
filesystem) and customization (everyone gets to set their own
prompt / shell / $EDITOR / etc.)

Once you're done setting up your users, you should log in (via
SSH) as your personal account and make sure everything is working.

You can verify what's currently installed on the bastion via:

```
$ jumpbox
```

For more information, check out [the jumpbox repo][jumpbox] on Github.

Note: try not to confuse the `jumpbox` script with the jumpbox
_BOSH release_.  The latter provisions the jumpbox machine as part
of the deployment, provides requisite packages, and creates user
accounts.  The former is really only useful for setting up /
updating the bastion host.

## Deploying Proto-BOSH and a Vault

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

### Proto-Vault

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

### Proto-BOSH

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
$ genesis new environment --type bosh-init aws proto
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

(Note: don't forget that `--type bosh-init` flag, it's very
important. otherwise, you'll run into problems with your
deployment)

The template helpfully generated all new credentials for us and
stored them in our proto-Vault, under the `secret/aws/proto/bosh`
subtree.  Later, we'll migrate this subtree over to our real
Vault, once it is up and spinning.

Let's head into the `proto/` environment directory and see if we
can create a manifest, or (a more likely case) we still have to
provide some critical information:

```
$ cd aws/proto
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
 - $.properties.shield.agent.daemon_public_key: Specify the SSH public key from this environment's SHIELD daemon
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
      z1: (( concat meta.aws.region "a" ))
    access_key: (( vault "secret/aws:access_key" ))
    secret_key: (( vault "secret/aws:secret_key" ))
```

I use the `(( concat ... ))` operator to [DRY][DRY] up the
configuration.  This way, if we need to move the BOSH director to
a different region (for whatever reason) we just change
`meta.aws.region` and the availability zone just tacks on "a".

(We use the "a" availability zone because that's where our subnet
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
 - $.properties.shield.agent.daemon_public_key: Specify the SSH public key from this environment's SHIELD daemon


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
    access_key: (( vault "secret/aws:access_key" ))
    secret_key: (( vault "secret/aws:secret_key" ))

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
 - $.properties.shield.agent.daemon_public_key: Specify the SSH public key from this environment's SHIELD daemon


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
      daemon_public_key: (( vault "secret/aws/proto/shield/keys/core:public" ))
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

Refer back to your [Network Plan][netplan], and find the
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
          subnet: subnet-xxxxxxxx # <-- your AWS Subnet ID
          security_groups: [wide-open]
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

> TODO: I had to `echo bosh-init > .type` to engage the bosh-init
> style of deployment.  How do we want to handle that?  Does
> Genesis need an update for a `--type` flag to `new env`?

> TODO: i also had to copy the aws key up to the bastion host.

Before we can deploy we need to upload the stemcell:

```
$ bosh upload stemcell https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3232.8
```

With the `stemcell` in place, let's give the deploy a whirl:

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

### Vault

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

Referring back to our [Network Plan][netplan] again, we
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
          subnet: subnet-xxxxxxxx  # <--- your AWS Subnet ID
          security_groups: [wide-open]
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
          subnet: subnet-yyyyyyyy  # <--- your AWS Subnet ID
          security_groups: [wide-open]
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
          subnet: subnet-zzzzzzzz  # <--- your AWS Subnet ID
          security_groups: [wide-open]
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

### Migrating Credentials

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

## Deploying Bolo Monitoring

Bolo is a monitoring system that collects metrics and state data
from your BOSH deployments, aggregates it, and provides data
visualization and notification primitives.

You may opt to deploy Bolo once for all of your environments, in
which case it belongs in your management network, or you may
decide to deploy per-environment Bolo installations.  What you
choose mostly only affects your network topology / configuration.

### Deploying Bolo

To get started, you're going to need to create a Genesis
deployments repo for your Bolo deployments:

```
$ cd ~/ops
$ genesis new deployment --template bolo
$ cd bolo-deployments
```

Next, we'll create a site for your datacenter or VPC.  The bolo
template deployment offers some site templates to make getting
things stood up quick and easy, including:

- `aws` for Amazon Web Services VPC deployments
- `vsphere` for VMWare ESXi virtualization clusters
- `bosh-lite` for deploying and testing locally

For purposes of illustration, let's choose `aws`:

```
$ genesis new site --template aws mgmt
Created site mgmt (from template aws):
~/ops/bolo-deployments/mgmt
├── README
└── site
    ├── disk-pools.yml
    ├── jobs.yml
    ├── networks.yml
    ├── properties.yml
    ├── releases
    ├── resource-pools.yml
    ├── stemcell
    │   ├── name
    │   └── version
    └── update.yml

2 directories, 10 files
```

(Note: if you are deploying per-environment Bolo installations,
you may want to choose something more environment-appropriate than
`mgmt`...)

Now, we can create our environment.  I like to call this `prod`,
in case we decide to build staging / sandbox environments for
deployment runways later.

```
$ cd mgmt/
$ genesis new environment prod
Created environment mgmt/prod:
/Users/jhunt/ops/docs/bolo-deployments/mgmt/prod
├── Makefile
├── README
├── cloudfoundry.yml
├── credentials.yml
├── director.yml
├── monitoring.yml
├── name.yml
├── networking.yml
├── properties.yml
└── scaling.yml

0 directories, 10 files
```

Bolo deployments have no secrets, so there isn't much in the way
of environment hooks for setting up credentials.

### Configuring Bolo For Amazon AWS

We need to configure the following things for an AWS deployment of
bolo:

- Availability Zone (via `meta.az`)
- Networking configuration

First, let's do the availability zone:

```
$ cd prod/
$ cat properties.yml
---
meta:
  az:
    us-west-2a
```

Then, open up `networking.yml` and fill out your networking
configuration.  For purposes of illustration, let's assume we're
going to deploy our Bolo into the `10.4.0.128/26` subdivision of
our `10.4.0.0/24` subnet.  For reference, here's the details on
the `/26` network:

```
-[ipv4 : 10.4.0.128/26] - 0

[CIDR]
Host address            - 10.4.0.128
Host address (decimal)  - 168034432
Host address (hex)      - A040080
Network address         - 10.4.0.128
Network mask            - 255.255.255.192
Network mask (bits)     - 26
Network mask (hex)      - FFFFFFC0
Broadcast address       - 10.4.0.191
Cisco wildcard          - 0.0.0.63
Addresses in network    - 64
Network range           - 10.4.0.128 - 10.4.0.191
Usable range            - 10.4.0.129 - 10.4.0.190
```

So that's 64 available hosts, strting at 10.4.0.128 and continuing
to 10.4.0.191.  Let's reserve the first 16 IPs for static
allocation, and let the compilation VMs / dynamically-allocated
VMs use the rest:

```
$ cat networking.yml
---
networks:
  - name: bolo
    type: manual
    subnets:
    - range: 10.4.0.0/24
      gateway: 10.4.0.1
      cloud_properties:
        subnet: subnet-XXXXXXXX # <--------- you'll want to change this
        security_groups: [sg-XXXXXXXX] # <-- also, change this
      dns: [10.4.0.2]
      reserved:
        - 10.4.0.2   - 10.4.0.127  # everything before our /26
        - 10.4.0.192 - 10.4.0.254  # everything after our /26
      static:
        - 10.4.0.128 - 10.4.0.144  # first 16 IPs

jobs:
  - name: bolo
    networks:
      - name: bolo
        static_ips: (( static_ips 0 ))
```

### Deploying

You can validate your manifest by running `make manifest` and
ensuring that you get no errors (no output is a good sign)

Then, you can deploy to your BOSH director via `make deploy`

Once you've deployed, you can validate the deployment by accessing
the Gnossis web interface on your `bolo/0` VM.  You can find the
IP via `bosh vms`, and just visit it in a browser, over HTTP
(standard port).

Out of the box, the Bolo installation will begin monitoring itself
for general host health (the `linux` collector), so you should
have graphs.

### Configuring dbolo Agents

Now that you have a Bolo installation, you're going to want to
configure your other deployments to use it.  To do that, you'll
need to add the `bolo` release to the deployment (if it isn't
already there), add the `dbolo` template to all the VMs you want
monitored, and configure `dbolo` to submit metrics to your
`bolo/0` VM in the bolo deployment.

(Note that this may require configuration of network ACLs,
security groups, etc. -- if you experience issues with this step,
you might want to start looking in those areas first)

To add the release:

```
$ cd ~/ops/shield-deployments
$ genesis add release shield latest
$ cd mgmt/prod
$ genesis use release shield
```

If you do a `make manifest` at this point, you should see a new
release being added to the top-level `releases` list.

To configure dbolo, you're going to want to add a line like the
last one here to all of your job template definitions:

```
jobs:
  - name: whatever
    templates:
      - { release: bolo, name: dbolo }
```

Then, to configure `dbolo` to submit to your Bolo installation,
add the `dbolo.submission.address` property either globally or
per-job (strong recommendation for global, by the way).  You can
do this in `properties.yml`

```
properties:
  dbolo:
    submission:
      address: 10.4.0.128
```

As before, you can get the IP address of the `bolo/0` VM by
running `bosh vms` against your BOSH director.

### Configuring Specific Monitoring

If you have specific monitoring requirements, above and beyond
the stock host-health checks that the `linux` collector provides,
you can add per-job (or global) properties like this (in
properties.yml, again):

```
jobs:
  - name: shield
    properties:
      dbolo:
        collectors:
          - { every: 20s, run: 'linux' }
          - { every: 20s, run: 'httpd' }
          - { every: 20s, run: 'process -n nginx -m nginx' }
```

(Remember that you will need to supply the `linux` collector
configuration, since Bolo skips the automatic `dbolo` settings you
get for free when you specify your own configuration.)

### Further Reading on Bolo

More information can be found in the [Bolo BOSH Release README][bolo]
which contains a wealth of information about available graphs,
collectors, and deployment properties.

## Deploying SHIELD Backups

etc.

## Deploying Concourse

If we're not already targeting the ops vault, do so now to save frustration later.

```
$ safe target "http://10.4.1.16:8200" ops
Now targeting ops at http://10.4.1.16:8200
```

From the `~/ops` folder let's generate a new `concourse` deployment, using the `--template` flag.

```
$ genesis new deployment --template concourse
$ cd concourse-deployments/
```

Inside the `global` deployment level goes the site level definition.  For this concourse setup we'll use an `aws` template for an `aws` site.

```
$ genesis new site --template aws aws
Created site aws (from template aws):
/home/tbird/ops/concourse-deployments/aws
├── README
└── site
    ├── disk-pools.yml
    ├── jobs.yml
    ├── networks.yml
    ├── properties.yml
    ├── releases
    ├── resource-pools.yml
    ├── stemcell
    │   ├── name
    │   └── version
    └── update.yml

2 directories, 10 files
```

Finally now, because our vault is setup and targeted correctly we can generate our `environment` level configurations.  And begin the process of setting up the specific parameters for our environment.

```
$ genesis new environment aws ops
$ cd aws/ops
$ make manifest
11 error(s) detected:
 - $.compilation.cloud_properties.availability_zone: What availability zone should your concourse VMs be in?
 - $.jobs.haproxy.templates.haproxy.properties.ha_proxy.ssl_pem: Want ssl? define a pem
 - $.jobs.web.templates.atc.properties.external_url: What is the external URL for this concourse?
 - $.meta.availability_zone: What availability zone should your concourse VMs be in?
 - $.meta.external_url: What is the external URL for this concourse?
 - $.meta.ssl_pem: Want ssl? define a pem
 - $.networks.concourse.subnets: Specify your concourse subnet
 - $.resource_pools.db.cloud_properties.availability_zone: What availability zone should your concourse VMs be in?
 - $.resource_pools.haproxy.cloud_properties.availability_zone: What availability zone should your concourse VMs be in?
 - $.resource_pools.web.cloud_properties.availability_zone: What availability zone should your concourse VMs be in?
 - $.resource_pools.workers.cloud_properties.availability_zone: What availability zone should your concourse VMs be in?


Failed to merge templates; bailing...
Makefile:22: recipe for target 'manifest' failed
make: *** [manifest] Error 5
```

## Deploying Cloud Foundry

Before you begin, please ensure that the jumpbox user has been installed and `certstrap` has been installed.

TODO: @norm is working on a PR for this in the `jumpbox` repo.

Let's generate the Cloud Foundry deployment with a `genesis` template.

```
$ cd ~/ops
$ genesis new deployment --template cf-deployment
```

Now we need to create our AWS site inside our Cloud Foundry deployment.

```
$ cd cf-deployment/
$ genesis new site --template aws aws
```

From the site level now we can create each of the staging and production environments we want (or more based on requirements) for a client.

From `~/ops/cf-deployment/` we can run this because we're specifying the site as part of the parameters.

```
$ genesis new environment aws staging
$ genesis new environment aws prod
```

All the templates are generated now.  It's time to go into one of the environments and begin the process of providing the environment speicifc parameters that apply to the site/environment we're deploying to.

Let's begin with staging.

```
$ cd aws/staging
$ make manifest
TODO output goes here...
```

If we look at:

```
$.meta.cf.base_domain: Enter the Cloud Foundry base domain
```

You can edit the env `properties.yml` file, inheriting object “path” based on the output. Given this at the left, you might do…

```
---
meta:
  cf:
    base_domain: cf-aws-prod
```

If unsure what base_domain should be, refer to `name.yml` in the specific ENV in question.

Using the configuration information from AWS subnets  we got the subnets gateway and dns information.   The subnet ids are also available.   The gateway is subnet.1 and the gateway VPC.1

We are removing the cf2 networking configuration in a later step to save time.

```
---
networks:
- name: cf1
  subnets:
    - range: 10.10.3.0/24
      reserved:
        - 10.10.3.2 - 10.10.3.9
      static:
        - 10.10.3.10 - 10.10.3.128
      gateway: 10.10.3.1
      dns:
        - 10.10.0.2
      cloud_properties:
        security_groups:
          - cf
        subnet: subnet-7d0ec70b
- name: cf2
  subnets:
    - range: 10.10.9.0/24
      reserved:
        - 10.10.9.2 - 10.10.9.9
      static:
        - 10.10.9.10 - 10.10.9.128
      gateway: 10.10.9.1
      dns:
        - 10.10.0.2
      cloud_properties:
        security_groups:
          - cf
        subnet: subnet-d89902bc
```

Added S3 blobstore to the vault and then referenced vault spruce command to pull in the credentials.   This command will prompt you for the access keys.

```
$ safe write secret/aws/s3/blobstore aws_access_key_id
$ safe write secret/aws/s3/blobstore aws_secret_access_key
```

Added the following lines to the aws/prod/credentials.yml file.

```
meta:
  cf:
    blobstore_config:
      fog_connection:
        aws_access_key_id: (( vault secret/aws/s3/blobstore:aws_access_key_id ))
        aws_secret_access_key: (( vault secret/aws/s3/blobstore:aws_secret_access_key ))
        region: us-west-2
```

The cf3 network is required for the consul to have cluster quorum.   Need to three because consul attempts to avoid a split brain scenario.

[aws-subnets]: http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html
[bolo]:        https://github.com/cloudfoundry-community/bolo-boshrelease
[DRY]:         https://en.wikipedia.org/wiki/Don%27t_repeat_yourself
[jumpbox]:     https://github.com/jhunt/jumpbox
[netplan]:     network.md
[spruce-129]:  https://github.com/geofffranks/spruce/issues/129
[slither]:     http://slither.io
[amazon-keys]: https://console.aws.amazon.com/ec2/v2/home?region=us-west-2#KeyPairs:sort=keyName
