# codex

Codex brings together the years of experience and lessons learned
after designing, deploying and managing their client's BOSH and
Cloud Foundry distributed architectures.  These best practices are
gathered together here to further mature and develop these
techniques.

## Software You'll Need

You will need the following software on your local machine to
run these deployments:

- **[Spruce][spruce]**
- **[Genesis][genesis]**
- **[Safe][safe]**
- **[Terraform][terraform]**

On a Mac, you can install spruce, genesis and safe via Homebrew:

```
$ brew tap starkandwayne/cf
$ brew install spruce genesis safe
```

Terraform comes with its own [installation instructions][tf-inst].

## Deploying From Nothing

To get started with a best practices Codex deployment, you'll want
to choose your IaaS provider.  We have guides for the following:

- [AWS](aws.md)

[spruce]:    https://github.com/geofffranks/spruce
[genesis]:   https://github.com/starkandwayne/genesis
[safe]:      https://github.com/starkandwayne/safe
[terraform]: https://www.terraform.io
[tf-inst]:   https://www.terraform.io/intro/getting-started/install.html
