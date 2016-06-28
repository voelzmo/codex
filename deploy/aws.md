# Setting up an AWS VPC

So you want to deploy Cloud Foundry to good old Amazon Web
Services eh?  Good on you!

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
configuration directly matches the [Network Plan](../network/plan.md)
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

Next up: [Setting up the Bastion Host](../bastion.md)
