[README](README.md) > **Initialize**

## Initialize

How to setup the proto-BOSH with bosh-init.

1. Log into your bastion host
2. Create a directory for your deployments
3. Create your BOSH deployments repo: `genesis new deployment --template bosh`
4. Go inside your new repo (`bosh-deployments`), and create a new site based on your infrastructure: `genesis new site --template <aws|vsphere|openstack> <site_name>` 
5. Create your proto-bosh environment: `genesis new environment --type bosh-init <site_name> proto`
6. Go inside `<site_name>/proto`, and run `make manifest`
7. Fill out any parameters that remain to be set, in the environment level, until `make manifest` succeeds. Start with any of the `$.meta.*` properties, since `spruce` does not 
8. Deploy via `make deploy`
9. Make sure **NOT** to commit anything to the repo **YET**. Once you deploy Vault, you will move all the creds there.
10. Pause, while you deploy vault (TODO: where should this link to for vault deployments)
11. Resume! Take the creds generated for your proto-bosh and stick them into Vault via `safe set <path> <key>`
12. Update the `bosh-deployments/<site_name>/proto/*.yml` files to replace the credential overrides with the `(( vault "<path>:<key>" ))` Spruce operator
13. Ensure the changes to be committed do not contain any sensitive material
14. Commit the changes to the `bosh-deployments` repo
15. Push the `bosh-deployments` repo to wherever it's going to live.

TODO: ensure that we have `jumpbox` full instructions.

  * Installed `jumpbox`
  * Ran `sudo /usr/local/bin/jumpbox system` to have `safe` and other tools for Vault setup.

### Setup Management Environment

Now it's time to setup the [management environment](manage.md) that will enable each release environment to be more resilient and flexible.
