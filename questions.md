## Every Error I - Dan - reaches when deploying to AWS

1. When running `make apply`, I come across this error...Its because the `aws.tf` file is hardcoded to use `us-west-2` by default. I had to change it to my correct region for it to work.
```
Error applying plan:

2 error(s) occurred:

* aws_instance.bastion: Error launching source instance: InvalidKeyPair.NotFound: The key pair 'bosh' does not exist
    status code: 400, request id: 116344f2-dd10-42c6-bb3e-9879f1f3266d
* aws_instance.nat: Error launching source instance: InvalidKeyPair.NotFound: The key pair 'bosh' does not exist
    status code: 400, request id: af4c04d1-6c14-4478-ad10-cf69e5cb9fbd

Terraform does not automatically rollback in the face of errors.
Instead, your Terraform state file has been partially updated with
any resources that successfully completed. Please address the error
above and apply again to incrementally change your infrastructure.
```

2. Which then on the next `make apply` led me to this wonder of subnets....
```
Error applying plan:

1 error(s) occurred:

* aws_subnet.prod-infra: InvalidSubnetID.NotFound: The subnet ID 'subnet-d03567fa' does not exist
	status code: 400, request id: 327539b8-b4a3-48d9-8afe-e9df4247d12a

Terraform does not automatically rollback in the face of errors.
Instead, your Terraform state file has been partially updated with
any resources that successfully completed. Please address the error
above and apply again to incrementally change your infrastructure.
``` 
