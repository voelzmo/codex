[README](../README.md) > [Management Environment](../manage.md) > manage/**shield**

## Setup Sheild

We are going to use one ssh key pair for all the shield agents in the various deployments.   This will avoid needing to deploy the shield release each time we add a deployment that has a shield agent release included in that deployment.

Tip:  use “safe tree” to see the vault paths already created to figure out the path you want to use.

The “safe ssh” command will generate the key pair.   The vault keys of private, public and fingerprint are created.

```
$ safe ssh [nbits] path [path…]
$ safe ssh 2048 secret/proto/shield/core
```

We now have the vault paths for the deployment we need to modify:

```
secret/proto/shield/core:private
secret/proto/shield/core:public
```

Now we need to look at the shield bosh release to get the properties we need to use to set.   I used the search terms  `shield bosh release` in google to find the github repository.   The files named `spec` contains the properties we need to read and grok.   Now poke around the repository to find the various spec files.   The files we care look at are:

```
jobs/shield-daemon/spec
jobs/shield-agent/spec
```

The properties we care about are:

```
shield.daemon.host_key:
shield.agent.authorized_keys:
```

Now update the properties file in the environment directory

TODO: Should these lines actually be in `credentials.yml` for convention purposes?   I understand they can go anywhere.

```
$ cd shield-deployment/aws/prod
```

Now edit the `properties.yml` file and it should look like:

```
properties:

  shield:

    daemon:

      host_key: (( vault "secret/proto/shield/core:private" ))

    agent:

      authorized_keys:

        - (( vault "secret/proto/shield/core:public" ))
```

Now do a `make deploy`.

Now update the other deployments with shield agent releases and add the public key to them.  

For example:

```
cd proto-bosh-deployment/aws/proto-bosh-deployment/aws/proto
```

Edit `properties.yml` file and add the public key:


```
properties:

    agent:

      authorized_keys:

        - (( vault "secret/proto/shield/core:public" ))
```


```
make deploy
```

Create an IAM user (used name backup)

Create an s3 bucket (used name codex-backup)

Set user backup permission to access s3 bucket codex-backup

(use a custom policy to strict to user backup)

The amazon resource name (arn)  for backup can be found on the summary panel

(the generic s3 policy is too open)

Replace arn

```
{

    "Statement": [

        {

            "Effect": "Allow",

            "Action": "s3:ListAllMyBuckets",

            "Resource": "arn:aws:iam::953869484482:user/backup"

        },

        {

            "Effect": "Allow",

            "Action": "s3:*",

            "Resource": [

                "arn:aws:s3:::codex-backup",

                "arn:aws:s3:::codex-backup/*"

            ]

        }

    ]

}
```

TODO: ask @norm about this final section with regard to shield and bolo.

ssh to jump box

cd to deployment directory

```
$ genesis new deployment --template bolo/bolo
```

(will create a directory named bolo-deployments

TODO: need better doc on new site —template <name>

Did not know that name here was coming from .templates directory

```
$ genesis new site -template aws aws
```
