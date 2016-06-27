[README](../README.md) > [Management Environment](../manage.md) > manage/**bolo**

## Bolo

Bolo is a monitoring system that collects metrics and state data
from your BOSH deployments, aggregates it, and provides data
visualization and notification primitives.

You may opt to deploy Bolo once for all of your environments, in
which case it belongs in your management network, or you may
decide to deploy per-environment Bolo installations.  What you
choose mostly only affects your network topology / configuration.

## Deploying Bolo

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

## Deploying

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

## Configuring dbolo Agents

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

## Further Reading

More information can be found in the [Bolo BOSH Release README][1]
which contains a wealth of information about available graphs,
collectors, and deployment properties.




[1]: https://github.com/cloudfoundry-community/bolo-boshrelease
