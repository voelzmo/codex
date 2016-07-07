## Common Errors and Solutions to them!
Here we will display all common errors, the common paths that you ended up in that position, and the ways to get around them. If you can't find the solution in the main docs, then the answer will probably be here....ONWARDS!

### Bastion / Jumpbox
* When trying to `make all` to deploy the Bastion host.
    Terraform will connect to AWS, using your Access Key and Secret
    Key, and spin up all the things it needs.  When it finishes, you
    should be left with a bunch of subnets, configured network ACLs,
    security groups, routing tables, a NAT instance (for public
    internet connectivity) and a Bastion host.

    If the `deploy` step fails with errors like:

    ```
    * aws_subnet.prod-cf-edge-1: Error creating subnet: InvalidParameterValue: Value (us-east-1a) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-east-1c, us-east-1e, us-east-1b, us-east-1d. status code: 400, request id: 8ddbe059-0818-48c2-a936-b551cd76cdeb
    * aws_subnet.prod-infra-1: Error creating subnet: InvalidParameterValue: Value (us-east-1a) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-east-1c, us-east-1b, us-east-1d, us-east-1e. status code: 400, request id: 876f72b2-6bda-4499-98c3-502d213635eb
    * aws_subnet.dev-infra-3: Error creating subnet: InvalidParameterValue: Value (us-east-1a) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-east-1c, us-east-1b, us-east-1d, us-east-1e. status code: 400, request id: 66fafa81-7718-46eb-a606-e4b98e3267b9
    ```

you should run `make destroy` to clean up, then add a line like `aws_az1 = "d"` to replace the restricted zone.

### ProtoBosh & Proto-Vault

### Proto Deployments
* Vault -
* Concourse -
* SHIELD -
* Bolo -

### Prod Bosh Deployments
* CF Deployment
