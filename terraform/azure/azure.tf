#
# Amazonia - Terraform Configuration for
# Azure Bosh + Cloud Foundry
#
#

variable "azure_region"     { default = "West US" } # Azure Region (https://azure.microsoft.com/en-us/regions/)
variable "network"        { default = "10.4" }      # First 2 octets of your /16

variable "resource_group_name" {}

variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

##############################################################

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

#############################################################

# Create a resource group
resource "azurerm_resource_group" "production" {
    name     = "${vars.resource_group_name}"
    location = "${vars.azure_region}"
}

###############################################################


########   #######  ##     ## ######## #### ##    ##  ######
##     ## ##     ## ##     ##    ##     ##  ###   ## ##    ##
##     ## ##     ## ##     ##    ##     ##  ####  ## ##
########  ##     ## ##     ##    ##     ##  ## ## ## ##   ####
##   ##   ##     ## ##     ##    ##     ##  ##  #### ##    ##
##    ##  ##     ## ##     ##    ##     ##  ##   ### ##    ##
##     ##  #######   #######     ##    #### ##    ##  ######



 ######  ##     ## ########  ##    ## ######## ########  ######
##    ## ##     ## ##     ## ###   ## ##          ##    ##    ##
##       ##     ## ##     ## ####  ## ##          ##    ##
 ######  ##     ## ########  ## ## ## ######      ##     ######
      ## ##     ## ##     ## ##  #### ##          ##          ##
##    ## ##     ## ##     ## ##   ### ##          ##    ##    ##
 ######   #######  ########  ##    ## ########    ##     ######

###############################################################
# DMZ - De-militarized Zone for NAT box ONLY



###############################################################
# GLOBAL - Global Infrastructure
#
# This includes the following:
#   - proto-BOSH
#   - SHIELD
#   - Vault (for deployment credentials)
#   - Concourse (for deployment automation)
#   - Bolo
#


###############################################################
# DEV-INFRA - Development Site Infrastructure
#
#  Primarily used for BOSH directors, deployed by proto-BOSH
#
#  Also reserved for situations where you prefer to have
#  dedicated, per-site infrastructure (SHIELD, Bolo, etc.)
#
#  Three zone-isolated networks are provided for HA and
#  fault-tolerance in deployments that support / require it.
#


###############################################################
# DEV-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#


###############################################################
# DEV-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#


###############################################################
# DEV-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#


###############################################################
# DEV-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#


###############################################################
# STAGING-INFRA - Staging Site Infrastructure
#
#  Primarily used for BOSH directors, deployed by proto-BOSH
#
#  Also reserved for situations where you prefer to have
#  dedicated, per-site infrastructure (SHIELD, Bolo, etc.)
#
#  Three zone-isolated networks are provided for HA and
#  fault-tolerance in deployments that support / require it.
#


###############################################################
# STAGING-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#


###############################################################
# STAGING-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#


###############################################################
# STAGING-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#


###############################################################
# STAGING-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#


###############################################################
# PROD-INFRA - Production Site Infrastructure
#
#  Primarily used for BOSH directors, deployed by proto-BOSH
#
#  Also reserved for situations where you prefer to have
#  dedicated, per-site infrastructure (SHIELD, Bolo, etc.)
#
#  Three zone-isolated networks are provided for HA and
#  fault-tolerance in deployments that support / require it.
#


###############################################################
# PROD-CF-EDGE - Cloud Foundry Routers
#
#  These subnets are separate from the rest of Cloud Foundry
#  to ensure that we can properly ACL the public-facing HTTP
#  routers independent of the private core / services.
#


###############################################################
# PROD-CF-CORE - Cloud Foundry Core
#
#  These subnets contain the private core components of Cloud
#  Foundry.  They are separate for reasons of isolation via
#  Network ACLs.
#


###############################################################
# PROD-CF-RUNTIME - Cloud Foundry Runtime
#
#  These subnets house the Cloud Foundry application runtime
#  (either DEA-next or Diego).
#


###############################################################
# PROD-CF-SVC - Cloud Foundry Services
#
#  These subnets house Service Broker deployments for
#  Cloud Foundry Marketplace services.
#


##    ##    ###     ######  ##        ######
###   ##   ## ##   ##    ## ##       ##    ##
####  ##  ##   ##  ##       ##       ##
## ## ## ##     ## ##       ##        ######
##  #### ######### ##       ##             ##
##   ### ##     ## ##    ## ##       ##    ##
##    ## ##     ##  ######  ########  ######




  #### ##    ##  ######   ########  ########  ######   ######
   ##  ###   ## ##    ##  ##     ## ##       ##    ## ##    ##
   ##  ####  ## ##        ##     ## ##       ##       ##
   ##  ## ## ## ##   #### ########  ######    ######   ######
   ##  ##  #### ##    ##  ##   ##   ##             ##       ##
   ##  ##   ### ##    ##  ##    ##  ##       ##    ## ##    ##
  #### ##    ##  ######   ##     ## ########  ######   ######


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



 ######  ########  ######          ######   ########   #######  ##     ## ########   ######
##    ## ##       ##    ##        ##    ##  ##     ## ##     ## ##     ## ##     ## ##    ##
##       ##       ##              ##        ##     ## ##     ## ##     ## ##     ## ##
 ######  ######   ##              ##   #### ########  ##     ## ##     ## ########   ######
      ## ##       ##              ##    ##  ##   ##   ##     ## ##     ## ##              ##
##    ## ##       ##    ## ###    ##    ##  ##    ##  ##     ## ##     ## ##        ##    ##
 ######  ########  ######  ###     ######   ##     ##  #######   #######  ##         ######





##    ##    ###    ########
###   ##   ## ##      ##
####  ##  ##   ##     ##
## ## ## ##     ##    ##
##  #### #########    ##
##   ### ##     ##    ##
##    ## ##     ##    ##




########     ###     ######  ######## ####  #######  ##    ##
##     ##   ## ##   ##    ##    ##     ##  ##     ## ###   ##
##     ##  ##   ##  ##          ##     ##  ##     ## ####  ##
########  ##     ##  ######     ##     ##  ##     ## ## ## ##
##     ## #########       ##    ##     ##  ##     ## ##  ####
##     ## ##     ## ##    ##    ##     ##  ##     ## ##   ###
########  ##     ##  ######     ##    ####  #######  ##    ##

