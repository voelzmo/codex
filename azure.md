# Part II - Deploying on AWS

Welcome to the Stark & Wayne guide to deploying Cloud Foundry on Microsoft Azure.

## Initial Setup

Install Azure CLI under Node.js 4.x

````
npm install azure-cli -g
````

Then you can log in to set up the Jumpbox

````
[ruby-2.2.3] Homer:Ford krutten$ azure login
Microsoft Azure CLI would like to collect data about how users use CLI
commands and some problems they encounter.  Microsoft uses this information
to improve our CLI commands.  Participation is voluntary and when you
choose to participate your device automatically sends information to
Microsoft about how you use Azure CLI.

If you choose to participate, you can stop at any time later by using Azure
CLI as follows:
1.  Use the azure telemetry command to turn the feature Off.
To disable data collection, execute: azure telemetry --disable

If you choose to not participate, you can enable at any time later by using
Azure CLI as follows:
1.  Use the azure telemetry command to turn the feature On.
To enable data collection, execute: azure telemetry --enable

Select y to enable data collection :(y/n) n

You choose not to participate in Microsoft Azure CLI data collection.


info:    Executing command login
|info:    To sign in, use a web browser to open the page https://aka.ms/devicelogin. Enter the code EKJJYNXPU to authenticate.
-info:    Added subscription Free Trial
info:    Setting subscription "Free Trial" as default
+
info:    login command OK
[ruby-2.2.3] Homer:Ford krutten$
````

Most of the commands required need you to be in `Azure CLI Resource Management` mode.

>The Azure Resource Manager mode and Azure Service Management mode are mutually exclusive. That is, resources created in one mode cannot be managed from the other mode.

````
[ruby-2.2.3] Homer:Ford krutten$ azure config mode arm
info:    Executing command config mode
info:    New mode is arm
info:    config mode command OK
[ruby-2.2.3] Homer:Ford krutten$
````

## Setting up an Azure VPC/Terraforming

TBD

### Generate an EC2 Key Pair

## Booting a Jumpbox
You can boot the default Ubuntu 14.04 with

````
[ruby-2.2.3] Homer:Ford krutten$ azure vm quick-create -M ~/.ssh/id_azure.pub -Q UbuntuLTS
info:    Executing command vm quick-create
Resource group name:  proto
Virtual machine name:  jumpbox
Location name:  westus
Operating system Type [Windows, Linux]:  linux
User name:  jump
+ Listing virtual machine sizes available in the location "westus"
+ Looking up the VM "jumpbox"
info:    Verifying the public key SSH file: /Users/krutten/.ssh/id_azure.pub
info:    Using the VM Size "Standard_DS1"
info:    The [OS, Data] Disk or image configuration requires storage account
+ Looking up the storage account cli26496493432090414049
+ Looking up the NIC "jumpb-westu-2649649343-nic"
info:    Found an existing NIC "jumpb-westu-2649649343-nic"
info:    Found an IP configuration with virtual network subnet id "/subscriptions/13c77c2c-b99d-4eba-a00c-fe5425d760d6/resourceGroups/proto/providers/Microsoft.Network/virtualNetworks/jumpb-westu-2649649343-vnet/subnets/jumpb-westu-2649649343-snet" in the NIC "jumpb-westu-2649649343-nic"
info:    This NIC IP configuration is already configured with the provided public ip "jumpb-westu-2649649343-pip"
+ Looking up the storage account clisto1457861882jumpbox
+ Creating VM "jumpbox"
+ Looking up the VM "jumpbox"
+ Looking up the NIC "jumpb-westu-2649649343-nic"
+ Looking up the public ip "jumpb-westu-2649649343-pip"
data:    Id                              :/subscriptions/13c77c2c-b99d-4eba-a00c-fe5425d760d6/resourceGroups/proto/providers/Microsoft.Compute/virtualMachines/jumpbox
data:    ProvisioningState               :Succeeded
data:    Name                            :jumpbox
data:    Location                        :westus
data:    Type                            :Microsoft.Compute/virtualMachines
data:
data:    Hardware Profile:
data:      Size                          :Standard_DS1
data:
data:    Storage Profile:
data:      Image reference:
data:        Publisher                   :Canonical
data:        Offer                       :UbuntuServer
data:        Sku                         :14.04.4-LTS
data:        Version                     :latest
data:
data:      OS Disk:
data:        OSType                      :Linux
data:        Name                        :cli9a45ea28ea164df0-os-1468608733494
data:        Caching                     :ReadWrite
data:        CreateOption                :FromImage
data:        Vhd:
data:          Uri                       :https://cli26496493432090414049.blob.core.windows.net/vhds/cli9a45ea28ea164df0-os-1468608733494.vhd
data:
data:    OS Profile:
data:      Computer Name                 :jumpbox
data:      User Name                     :jump
data:      Linux Configuration:
data:        Disable Password Auth       :true
data:
data:    Network Profile:
data:      Network Interfaces:
data:        Network Interface #1:
data:          Primary                   :true
data:          MAC Address               :00-0D-3A-34-4E-29
data:          Provisioning State        :Succeeded
data:          Name                      :jumpb-westu-2649649343-nic
data:          Location                  :westus
data:            Public IP address       :104.40.73.246
data:            FQDN                    :jumpb-westu-2649649343-pip.westus.cloudapp.azure.com
data:
data:    Diagnostics Profile:
data:      BootDiagnostics Enabled       :true
data:      BootDiagnostics StorageUri    :https://clisto1457861882jumpbox.blob.core.windows.net/
data:
data:      Diagnostics Instance View:
info:    vm quick-create command OK
[ruby-2.2.3] Homer:Ford krutten$
````

At this time Ubuntu 16.04 is not on the list of [Available Images](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-linux-cli-ps-findimage/)

### Installing the Packages

````
jump@jumpbox:~$ sudo curl -o /usr/local/bin/jumpbox \
>     https://raw.githubusercontent.com/starkandwayne/jumpbox/master/bin/jumpbox
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  8561  100  8561    0     0  56303      0 --:--:-- --:--:-- --:--:-- 56695
jump@jumpbox:~$ sudo chmod 0755 /usr/local/bin/jumpbox
jump@jumpbox:~$ sudo jumpbox system
                   _.-+.
              _.-""     '.
          +:""            '.
          J \               '.
           L \             _.-+
           |  '.       _.-"   |
           J    \  _.-"       L
            L    +"          J
            +    |           |     (( jumpbox ))
             \   |          .+
              \  |       .-'
               \ |    .-'
                \| .-'
                 +

>> Installing Core System Packages (via apt-get)
Reading package lists... Done
Building dependency tree
Reading state information... Done
tmux is already the newest version.
The following extra packages will be installed:
  git-man liberror-perl
Suggested packages:
  git-daemon-run git-daemon-sysvinit git-doc git-el git-email git-gui gitk
  gitweb git-arch git-bzr git-cvs git-mediawiki git-svn zip
The following NEW packages will be installed:
  git git-man liberror-perl pwgen tree unzip
0 upgraded, 6 newly installed, 0 to remove and 0 not upgraded.
Need to get 3,518 kB of archives.
After this operation, 22.5 MB of additional disk space will be used.
Get:1 http://azure.archive.ubuntu.com/ubuntu/ trusty/main liberror-perl all 0.17-1.1 [21.1 kB]
Get:2 http://azure.archive.ubuntu.com/ubuntu/ trusty-updates/main git-man all 1:1.9.1-1ubuntu0.3 [699 kB]
Get:3 http://azure.archive.ubuntu.com/ubuntu/ trusty-updates/main git amd64 1:1.9.1-1ubuntu0.3 [2,586 kB]
Get:4 http://azure.archive.ubuntu.com/ubuntu/ trusty/main pwgen amd64 2.06-1ubuntu4 [17.3 kB]
Get:5 http://azure.archive.ubuntu.com/ubuntu/ trusty/universe tree amd64 1.6.0-1 [37.8 kB]
Get:6 http://azure.archive.ubuntu.com/ubuntu/ trusty-updates/main unzip amd64 6.0-9ubuntu1.5 [157 kB]
Fetched 3,518 kB in 0s (9,700 kB/s)
Selecting previously unselected package liberror-perl.
(Reading database ... 28424 files and directories currently installed.)
Preparing to unpack .../liberror-perl_0.17-1.1_all.deb ...
Unpacking liberror-perl (0.17-1.1) ...
Selecting previously unselected package git-man.
Preparing to unpack .../git-man_1%3a1.9.1-1ubuntu0.3_all.deb ...
Unpacking git-man (1:1.9.1-1ubuntu0.3) ...
Selecting previously unselected package git.
Preparing to unpack .../git_1%3a1.9.1-1ubuntu0.3_amd64.deb ...
Unpacking git (1:1.9.1-1ubuntu0.3) ...
Selecting previously unselected package pwgen.
Preparing to unpack .../pwgen_2.06-1ubuntu4_amd64.deb ...
Unpacking pwgen (2.06-1ubuntu4) ...
Selecting previously unselected package tree.
Preparing to unpack .../tree_1.6.0-1_amd64.deb ...
Unpacking tree (1.6.0-1) ...
Selecting previously unselected package unzip.
Preparing to unpack .../unzip_6.0-9ubuntu1.5_amd64.deb ...
Unpacking unzip (6.0-9ubuntu1.5) ...
Processing triggers for man-db (2.6.7.1-1ubuntu1) ...
Processing triggers for mime-support (3.54ubuntu1.1) ...
Setting up liberror-perl (0.17-1.1) ...
Setting up git-man (1:1.9.1-1ubuntu0.3) ...
Setting up git (1:1.9.1-1ubuntu0.3) ...
Setting up pwgen (2.06-1ubuntu4) ...
Setting up tree (1.6.0-1) ...
Setting up unzip (6.0-9ubuntu1.5) ...
>> Checking for jq v1.5
>> Installing jq v1.5
   installed  (jq-1.5)
>> Checking for spruce v1.6.0
>> Installing spruce v1.6.0
   installed  (spruce - Version 1.6.0)
>> Checking for safe v0.0.21
>> Installing safe v0.0.21
   installed  (safe v0.0.21)
>> Checking for vault v0.6.0
>> Installing vault v0.6.0
Archive:  /tmp/vault.zip
  inflating: vault
   installed  (Vault v0.6.0)
>> Checking for bosh-init v0.0.81
>> Installing bosh-init v0.0.81
   installed  (version 0.0.81-775439c-2015-12-09T00:36:03Z)
>> Checking for genesis v1.5.2
>> Installing genesis v1.5.2
   installed  (genesis 1.5.2 (61864a21370c))
sent invalidate(passwd) request, exiting
sent invalidate(group) request, exiting
sent invalidate(group) request, exiting



   ALL DONE
jump@jumpbox:~$
````

### Quick Recap

````
azure login
azure config mode arm

azure provider register Microsoft.Storage
azure provider register Microsoft.Network
azure provider register Microsoft.Compute

azure vm quick-create -M ~/.ssh/azure_id_rsa.pub -Q UbuntuLTS
````
