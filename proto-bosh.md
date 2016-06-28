# Deploying Proto-BOSH and a Vault

So you've tamed the IaaS and outfitted your bastion host with the
necessary tools to deploy stuff.  First up, we have to deploy a
BOSH director, which we will call proto-BOSH.

Proto-BOSH is a little different from all of the other BOSH
directors we're going to deploy.  For starters, it gets deployed
via `bosh-init`, whereas our environment-specific BOSH directors
are going to be deployed via the proto-BOSH (and the `bosh` CLI).
It is also the only deployment that gets deployed without the
benefit of a Vault in which to store secret credentials.

## Proto-BOSH

To get started, log into the bastion host as yourself, and create
a place to store your deployments.

```
$ mkdir -p ops
$ cd ops
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
$ genesis new environment proto
Running env setup hook: /Users/jhunt/ops/docs/bosh-deployments/.env_hooks/setup
Created environment aws/proto:
~/ops/docs/bosh-deployments/aws/proto
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

Because we don't have a Vault yet, we now have a `proto/credentials.yml`
file that needs to be filled out with new passwords.  You can use the pwgen
utility for this.

```
$ pwgen 32 14 -1
```

That will give you 14 random passwords, one per line, each 32 characters
long.  Replace the `(( param ... ))` calls in `proto/credentials.yml`.  To
properly format the `vcap` password (which must be SHA512-crypted) ...

TODO: figure out how to bootstrap creds better.  Should we spin a Vault on-bastion?


## Vault

## Proto-BOSH (Revisited)
