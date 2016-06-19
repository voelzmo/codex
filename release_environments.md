## Release Environment

### Prerequisites

Please ensure that these have been setup:

  * [Infrastructure Provider](infrastructure.md)
  * [Network Topology](network.md)
  * [Management Environment](management_environment.md)

### Setup a Release Environment

1. Use proto-BOSH to deploy n Alpha BOSH-lites (Warden CPI)
1. Use proto-BOSH to deploy Runway Concourse
1. Use proto-BOSH to deploy SHIELD
1. Configure an alpha environment using Alpha BOSH-lites
1. Configure production environment
1. Configure Runway Concourse pipeline for deployment
1. Configure Backups of all components using SHIELD:
  * proto-BOSH
  * Concourse
1. Use proto-BOSH to deploy Bolo
1. Configure an alpha environment using Alpha BOSH-lites
1. Configure production environment
1. Configure Runway Concourse pipelines for deployment
1. Reconfigure proto-BOSH, SHIELD, Vault and Concourse to feed monitoring data
1. Use proto-BOSH to deploy a BOSH director for each logical site (per client need)
1. Configure UAA
1. Configure monitoring
1. Configure SHIELD backups
1. Use proto-BOSH to deploy a Jumpbox
1. For each desired deployment:
1. Configure an alpha environment using Alpha BOSH-lites
1. Configure beta and production environments using appropriate directors
1. Configure Runway Concourse pipeline for deployment
1. Configure backups in SHIELD
1. Configure monitoring integration with Bolo
