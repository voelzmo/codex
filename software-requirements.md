## Software You'll Need

You will need the following software on your local machine torun these deployments:
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

To get started with a best practices Codex deployment, you'll wantto choose your IaaS provider. We have guides for the following:

- [AWS](part1/aws.md)

[spruce]: https://github.com/geofffranks/spruce
[genesis]: https://github.com/starkandwayne/genesis
[safe]: https://github.com/starkandwayne/safe
[terraform]: https://www.terraform.io
[tf-inst]: https://www.terraform.io/intro/getting-started/install.html

