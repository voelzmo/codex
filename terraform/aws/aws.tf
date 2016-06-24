#
# Amazonia - Terraform Configuration for
# AWS BOSH + Cloud Foundry
#
# author:  James Hunt <james@niftylogic.com>
# created: 2016-06-14
#

variable "aws_access_key" {} # Your Access Key ID     (required)
variable "aws_secret_key" {} # Your Secret Access Key (required)
variable "aws_vpc_name"   {} # Name of your VPC       (required)
variable "aws_key_name"   {} # Name of EC2 Keypair    (required)

variable "aws_region"     { default = "us-west-2" } # AWS Region
variable "network"        { default = "10.4" }      # First 2 octets of your /16

variable "aws_az1"        { default = "a" }
variable "aws_az2"        { default = "b" }
variable "aws_az3"        { default = "c" }

#
# VPC NAT AMI
#
# These are the region-specific IDs for the Amazon-suggested
# AMI for running a NAT instance inside of a VPC:
#
#    amzn-ami-vpc-nat-hvm-2014.03.2.x86_64-gp2
#
variable "aws_nat_ami" {
  default = {
    us-east-1      = "ami-4c9e4b24"
    us-west-1      = "ami-1d2b2958"
    us-west-2      = "ami-8b6912bb"
    ap-northeast-1 = "ami-49c29e48"
    ap-northeast-2 = "ami-0199506f"
    ap-southeast-1 = "ami-d482da86"
    ap-southeast-2 = "ami-a164029b"
    eu-west-1      = "ami-5b60b02c"
    sa-east-1      = "ami-8b72db96"
  }
}

#
# Generic Ubuntu AMI
#
# These are the region-specific IDs for an
# HVM-compatible Ubuntu image:
#
#    ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20160610
#
# (Note: this AMI is missing from the Seoul [ap-northeast-2] region)
#
variable "aws_ubuntu_ami" {
  default = {
    us-east-1      = "ami-f652979b"
    us-west-1      = "ami-08490c68"
    us-west-2      = "ami-d06a90b0"
    ap-northeast-1 = "ami-b601ead7"
    #ap-northeast-2 = "" # MISSING
    ap-southeast-1 = "ami-e7a67584"
    ap-southeast-2 = "ami-61e3ca02"
    eu-west-1      = "ami-0ae77879"
    sa-east-1      = "ami-09991365"
  }
}

###############################################################

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

###############################################################

resource "aws_vpc" "default" {
  cidr_block           = "${var.network}.0.0/16"
  enable_dns_hostnames = "true"
  tags { Name = "${var.aws_vpc_name}" }
}



########   #######  ##     ## ######## #### ##    ##  ######
##     ## ##     ## ##     ##    ##     ##  ###   ## ##    ##
##     ## ##     ## ##     ##    ##     ##  ####  ## ##
########  ##     ## ##     ##    ##     ##  ## ## ## ##   ####
##   ##   ##     ## ##     ##    ##     ##  ##  #### ##    ##
##    ##  ##     ## ##     ##    ##     ##  ##   ### ##    ##
##     ##  #######   #######     ##    #### ##    ##  ######

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}
resource "aws_route_table" "external" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
  tags { Name = "${var.aws_vpc_name}-external" }
}
resource "aws_route_table" "internal" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.nat.id}"
  }
  tags { Name = "${var.aws_vpc_name}-internal" }
}



 ######  ##     ## ########  ##    ## ######## ########  ######
##    ## ##     ## ##     ## ###   ## ##          ##    ##    ##
##       ##     ## ##     ## ####  ## ##          ##    ##
 ######  ##     ## ########  ## ## ## ######      ##     ######
      ## ##     ## ##     ## ##  #### ##          ##          ##
##    ## ##     ## ##     ## ##   ### ##          ##    ##    ##
 ######   #######  ########  ##    ## ########    ##     ######

###############################################################
# DMZ - De-militarized Zone for NAT box ONLY
#
resource "aws_subnet" "dmz" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "${var.network}.0.0/24"
  tags { Name = "${var.aws_vpc_name}-dmz" }
}
resource "aws_route_table_association" "dmz" {
  subnet_id      = "${aws_subnet.dmz.id}"
  route_table_id = "${aws_route_table.external.id}"
}

###############################################################
# INFRANET - Subnet for Infrastructural Services
#
# This includes the following:
#   - proto-BOSH
#   - SHIELD
#   - Vault (for deployment credentials)
#   - Concourse (for deployment automation)
#   - Bolo
#
resource "aws_subnet" "infranet" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "${var.network}.1.0/24"
  tags { Name = "${var.aws_vpc_name}-infranet" }
}
resource "aws_route_table_association" "infranet" {
  subnet_id      = "${aws_subnet.infranet.id}"
  route_table_id = "${aws_route_table.internal.id}"
}

resource "aws_subnet" "prod-infra" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.32.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-infra" }
}
resource "aws_route_table_association" "prod-infra" {
  subnet_id      = "${aws_subnet.prod-infra.id}"
  route_table_id = "${aws_route_table.internal.id}"
}

resource "aws_subnet" "prod-edge-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.34.0/24"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-edge-1" }
}
resource "aws_route_table_association" "prod-edge-1" {
  subnet_id      = "${aws_subnet.prod-edge-1.id}"
  route_table_id = "${aws_route_table.external.id}"
}
resource "aws_subnet" "prod-edge-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.35.0/24"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-prod-edge-2" }
}
resource "aws_route_table_association" "prod-edge-2" {
  subnet_id      = "${aws_subnet.prod-edge-2.id}"
  route_table_id = "${aws_route_table.external.id}"
}

resource "aws_subnet" "prod-cf-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.36.0/23"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-1" }
}
resource "aws_route_table_association" "prod-cf-1" {
  subnet_id      = "${aws_subnet.prod-cf-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
resource "aws_subnet" "prod-cf-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.38.0/23"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-2" }
}
resource "aws_route_table_association" "prod-cf-2" {
  subnet_id      = "${aws_subnet.prod-cf-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
resource "aws_subnet" "prod-cf-3" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.40.0/23"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-prod-cf-3" }
}
resource "aws_route_table_association" "prod-cf-3" {
  subnet_id      = "${aws_subnet.prod-cf-3.id}"
  route_table_id = "${aws_route_table.internal.id}"
}

resource "aws_subnet" "prod-svc-1" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.42.0/23"
  availability_zone = "${var.aws_region}${var.aws_az1}"
  tags { Name = "${var.aws_vpc_name}-prod-svc-1" }
}
resource "aws_route_table_association" "prod-svc-1" {
  subnet_id      = "${aws_subnet.prod-svc-1.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
resource "aws_subnet" "prod-svc-2" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.44.0/23"
  availability_zone = "${var.aws_region}${var.aws_az2}"
  tags { Name = "${var.aws_vpc_name}-prod-svc-2" }
}
resource "aws_route_table_association" "prod-svc-2" {
  subnet_id      = "${aws_subnet.prod-svc-2.id}"
  route_table_id = "${aws_route_table.internal.id}"
}
resource "aws_subnet" "prod-svc-3" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.network}.46.0/23"
  availability_zone = "${var.aws_region}${var.aws_az3}"
  tags { Name = "${var.aws_vpc_name}-prod-svc-3" }
}
resource "aws_route_table_association" "prod-svc-3" {
  subnet_id      = "${aws_subnet.prod-svc-3.id}"
  route_table_id = "${aws_route_table.internal.id}"
}



##    ##    ###     ######  ##        ######
###   ##   ## ##   ##    ## ##       ##    ##
####  ##  ##   ##  ##       ##       ##
## ## ## ##     ## ##       ##        ######
##  #### ######### ##       ##             ##
##   ### ##     ## ##    ## ##       ##    ##
##    ## ##     ##  ######  ########  ######

resource "aws_network_acl" "prod" {
  vpc_id = "${aws_vpc.default.id}"
  subnet_ids = [
    "${aws_subnet.prod-infra.id}",
    "${aws_subnet.prod-edge-1.id}",
    "${aws_subnet.prod-edge-2.id}",
    "${aws_subnet.prod-cf-1.id}",
    "${aws_subnet.prod-cf-2.id}",
    "${aws_subnet.prod-cf-3.id}",
    "${aws_subnet.prod-svc-1.id}",
    "${aws_subnet.prod-svc-2.id}",
    "${aws_subnet.prod-svc-3.id}"
  ]
  tags { Name = "${var.aws_vpc_name}-prod" }



  #### ##    ##  ######   ########  ########  ######   ######
   ##  ###   ## ##    ##  ##     ## ##       ##    ## ##    ##
   ##  ####  ## ##        ##     ## ##       ##       ##
   ##  ## ## ## ##   #### ########  ######    ######   ######
   ##  ##  #### ##    ##  ##   ##   ##             ##       ##
   ##  ##   ### ##    ##  ##    ##  ##       ##    ## ##    ##
  #### ##    ##  ######   ##     ## ########  ######   ######

  # Allow ICMP Echo Reply packets (type 0)
  # (response to ping/tracepath)
  ingress {
    rule_no    = "1"
    protocol   = "icmp"
    icmp_type  = "0"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Destination Unreachable (type 3) packets
  # (host/net unreachables, port closed, fragmentation
  #  issues, etc.)
  ingress {
    rule_no    = "2"
    protocol   = "icmp"
    icmp_type  = "3"
    icmp_code  = "-1"

    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Echo packets (type 8)
  # (ping/tracepath initiator)
  ingress {
    rule_no    = "3"
    protocol   = "icmp"
    icmp_type  = "8"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Time Exceeded (type 11)
  # (tracepath TTL issue)
  ingress {
    rule_no    = "4"
    protocol   = "icmp"
    icmp_type  = "11"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }

  # Allow SSH traffic from the Bastion Host (in the DMZ)
  ingress {
    rule_no    = "101"
    protocol   = "tcp"
    from_port  = "22"
    to_port    = "22"
    cidr_block = "${aws_instance.bastion.private_ip}/32"
    action     = "allow"
  }

  # OTHER RULES NEEDED:
  #  - BOSH (for proto-BOSH to deploy BOSH directors)
  #  - SHIELD (for backups to/from infranet)
  #  - Bolo (to submit monitoring egress to infranet)
  #  - Concourse (either direct acccess to BOSH, or worker communication)
  #  - Vault (jumpboxen need to get to Vault for creds.  also, concourse workers)

  # All other traffic is blocked by an implicit
  # Block all other traffic.



  ########  ######   ########  ########  ######   ######
  ##       ##    ##  ##     ## ##       ##    ## ##    ##
  ##       ##        ##     ## ##       ##       ##
  ######   ##   #### ########  ######    ######   ######
  ##       ##    ##  ##   ##   ##             ##       ##
  ##       ##    ##  ##    ##  ##       ##    ## ##    ##
  ########  ######   ##     ## ########  ######   ######

  # Allow ICMP Echo Reply packets (type 0)
  # (response to ping/tracepath)
  egress {
    rule_no    = "1"
    protocol   = "icmp"
    icmp_type  = "0"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Destination Unreachable (type 3) packets
  # (host/net unreachables, port closed, fragmentation
  #  issues, etc.)
  egress {
    rule_no    = "2"
    protocol   = "icmp"
    icmp_type  = "3"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Echo packets (type 8)
  # (ping/tracepath initiator)
  egress {
    rule_no    = "3"
    protocol   = "icmp"
    icmp_type  = "8"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow ICMP Time Exceeded (type 11)
  # (tracepath TTL issue)
  egress {
    rule_no    = "4"
    protocol   = "icmp"
    icmp_type  = "11"
    icmp_code  = "-1"
    to_port = "0"
    from_port = "0"
    cidr_block = "0.0.0.0/0"
    action     = "allow"
  }
  # Allow return traffic on ephemeral ports.
  # (Linux kernels use 32768-61000 for ephemeral ports)
  egress {
    rule_no    = "101"
    protocol   = "tcp"
    from_port  = "32768"
    to_port    = "65535"
    cidr_block = "0.0.0.0/0" # FIXME: lockdown to prod / bastion
    action     = "allow"
  }
  egress {
    rule_no    = "102"
    protocol   = "udp"
    from_port  = "32768"
    to_port    = "65535"
    cidr_block = "0.0.0.0/0" # FIXME: lockdown to prod / bastion
    action     = "allow"
  }

  # All other traffic is blocked by an implicit
  # DENY rule in the Network ACL (inside of AWS)
}



 ######  ########  ######          ######   ########   #######  ##     ## ########   ######
##    ## ##       ##    ##        ##    ##  ##     ## ##     ## ##     ## ##     ## ##    ##
##       ##       ##              ##        ##     ## ##     ## ##     ## ##     ## ##
 ######  ######   ##              ##   #### ########  ##     ## ##     ## ########   ######
      ## ##       ##              ##    ##  ##   ##   ##     ## ##     ## ##              ##
##    ## ##       ##    ## ###    ##    ##  ##    ##  ##     ## ##     ## ##        ##    ##
 ######  ########  ######  ###     ######   ##     ##  #######   #######  ##         ######

resource "aws_security_group" "dmz" {
  name        = "dmz"
  description = "Allow services from the private subnet through NAT"
  vpc_id      = "${aws_vpc.default.id}"
  tags { Name = "${var.aws_vpc_name}-dmz" }

  # ICMP traffic control
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow SSH traffic into the NAT box
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # ICMP traffic control (outbound)
  # Allows diagnostic utilities like ping / traceroute
  # to function as expected, and aid in troubleshooting.
  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow *ALL* outbound TCP traffic.
  # (security ppl may not like this...)
  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow *ALL* outbound UDP traffic.
  # (security ppl may not like this...)
  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "wide-open" {
  name        = "wide-open"
  description = "Allow everything in and out"
  vpc_id      = "${aws_vpc.default.id}"
  tags { Name = "${var.aws_vpc_name}-wide-open" }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



##    ##    ###    ########
###   ##   ## ##      ##
####  ##  ##   ##     ##
## ## ## ##     ##    ##
##  #### #########    ##
##   ### ##     ##    ##
##    ## ##     ##    ##

resource "aws_instance" "nat" {
  ami             = "${lookup(var.aws_nat_ami, var.aws_region)}"
  instance_type   = "t2.small"
  key_name        = "${var.aws_key_name}"
  security_groups = ["${aws_security_group.dmz.id}"]
  subnet_id       = "${aws_subnet.dmz.id}"

  associate_public_ip_address = true
  source_dest_check           = false

  tags { Name = "nat" }
}
resource "aws_eip" "nat" {
  instance = "${aws_instance.nat.id}"
  vpc      = true
}



########     ###     ######  ######## ####  #######  ##    ##
##     ##   ## ##   ##    ##    ##     ##  ##     ## ###   ##
##     ##  ##   ##  ##          ##     ##  ##     ## ####  ##
########  ##     ##  ######     ##     ##  ##     ## ## ## ##
##     ## #########       ##    ##     ##  ##     ## ##  ####
##     ## ##     ## ##    ##    ##     ##  ##     ## ##   ###
########  ##     ##  ######     ##    ####  #######  ##    ##

resource "aws_instance" "bastion" {
  ami             = "${lookup(var.aws_ubuntu_ami, var.aws_region)}"
  instance_type   = "t2.small"
  key_name        = "${var.aws_key_name}"
  security_groups = ["${aws_security_group.dmz.id}"]
  subnet_id       = "${aws_subnet.dmz.id}"

  tags { Name = "bastion" }
}
resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc      = true
}
