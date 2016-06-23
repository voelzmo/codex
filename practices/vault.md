## Vault Best Practices

Our best practice is to have a single vault/safe for all deployment environments.
This may not be possible because of security requirement preconditions.   In these cases 
make the additional vault deployments as high as in the platform/global/site/environment structure.

Do not take shortcuts on the vault paths.   Use the full platform/global/site/environment path structure 
defining the paths.  It will make things easier if the vault data needs to be combined or split out
into different vaults over time. 

Do your best to have single definition for a password or credential.   This will simplify the process when 
passwords or credentials need to rotated.  When this is not possible, create some documentation right away about this dependency. 

Avoid placing multiple credentials in the same path.   
