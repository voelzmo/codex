## Vault Best Practices

Our best practice is to have a single vault/safe for all deployment environments.
This may not be possible because of security requirement preconditions or network topology.
In these cases place the additional vault deployments as high as possible in the 
platform/global/site/environment structure.

Do not take shortcuts on the vault paths.   Use the fullest path necessary to define your secret.
The path should correespond as if you only had one vault for your secrets.
It will make things easier if the vault data needs to be combined or split out into different vaults over time. 

TBD Do we want a best practice on path ordering?
* deployment/platform/global/site/environment/manifest:key
* platform/global/site/environment/deployment/manifest:key
* many other choices

Consider using a key name that matches to the manifest key name.  Make it easy for the next person to recognize the usage just by looking at its path and keyname.  The manifest level could be made part of the path or incorporated into the key name.

Stay consistent with the path and keyname style already used in the a deployment manifest.   The inconsistency drives us ADD types crazy and it looks unprofessional.

Avoid placing multiple secrets under the same path and key.  Secret rotation is easier if there is
only one secret to worry about.

Do your best to have single definition for your secret.   This will simplify the process when 
secrets needs to be rotated.  When this is not possible because we are using multiple vaults,
, create some documentation right away about secret dependency.  Failures will occur quickly if the duplicated
secret values get out of synced.

Consider placing related secret data such as username and host address in the vault under the same path as the secret.   It should avoid manually updating all the various deployments if that data is duplicated in the manifest files.
