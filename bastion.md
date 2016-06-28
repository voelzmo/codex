# Setting up the Bastion Host

The bastion host is an access point virtual machine that your IaaS
instrumentation layer (probably Terraform) should have provisioned
for you.  As such, you probably will need to consult with your
IaaS provider to figure out what IP address the bastion host can
be accessed at.  For example, on AWS, find the `bastion` EC2
instance and note its Elastic IP address.

You're going to need to SSH into the bastion host, and
unfortunately, that is also provider-specific.  In AWS, you'll
just SSH to the Elastic IP, using the private half of the EC2
keypair you generated.  Other IaaS's may have other requirements.

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

For more information, check out [the jumpbox repo][1] on Github.

Note: try not to confuse the `jumpbox` script with the jumpbox
_BOSH release_.  The latter provisions the jumpbox machine as part
of the deployment, provides requisite packages, and creates user
accounts.  The former is really only useful for setting up /
updating the bastion host.

Next: [Provisioning proto-BOSH / Vault](proto-bosh.md)

[1]: https://github.com/jhunt/jumpbox
