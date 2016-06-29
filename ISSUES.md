Open Issues
===========

(This is a place to put any issues with deployments, problems
 encountered while running scripts, missing tooling, bugs, etc.)

1. Need the `certstrap` utility on the Jumpbox BOSH release to
   make the cf-deployments go easier.  [GH jumpbox-boshrelease#6][1]
2. The `cf-deployment` template needs a [README that explains][2] what
   all of the `(( param ... ))` calls are for, and what they should
   be set to.
3. All templates that need to use `safe` should verify that the
   [user is targeted][3] to the Vault they want to use, before we go
   blindly generating credentials and stuffing them in the vault.

Once #1 and #2 are solved, I think we can drop the RTF file that
Norm commited with notes.

[1]: https://github.com/cloudfoundry-community/jumpbox-boshrelease/issues/6
[2]: https://github.com/starkandwayne/cf-deployment/issues/1
[3]: https://github.com/jhunt/safe/issues/27
