[README](../README.md) > [Management Environment](../manage.md) > manage/**concourse**

## Setup Concourse

If you try to setup concourse before vault you'll get this error:

```
$ genesis new environment aws prod
RSA 1024 bit CA certificates are loaded due to old openssl compatibility
Running env setup hook: /home/centos/ops/concourse-deployments/.env_hooks/00_confirm_vault
No .saferc found. Please connect to a working Vault installation.
Setup script bailed (exit 1).
Tearing down aws/prod environment...
```

The `genesis` hook failed to confirm the necessary files and connection to the target vault server from the current BOSH director.

Ensure that you have [vault setup first](vault.md).
