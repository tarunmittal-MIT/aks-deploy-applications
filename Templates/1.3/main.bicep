var location  = resourceGroup().location
var vmUsername  = 'kubeadmin'
var vmPassword = 'SuperLongPassword12345'
var osDiskSizeGB  = 128
var agentCount = 1
var agentVMSize = 'Standard_D2s_v3'
var osTypeLinux = 'Linux'
var uniqueSuffix = uniqueString(resourceGroup().id)

var roleDefinitionId = {
  AcrPull: {
    id: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'cr${uniqueSuffix}'
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
}

resource devcluster 'Microsoft.ContainerService/managedClusters@2024-06-02-preview' = {
  location: location
  name: 'aks-${uniqueSuffix}'
  tags: {
    displayname: 'AKS Cluster'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enableRBAC: true
    dnsPrefix: 'aks-${uniqueSuffix}'
    agentPoolProfiles: [
      {
        name: 'syspool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: osTypeLinux
        type: 'VirtualMachineScaleSets'
        mode: 'System'
      }
    ]
  }
}

resource AssignAcrPullToAks 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, containerRegistry.name, devcluster.name, 'ACRPull')
  scope: containerRegistry
  properties: {
    principalId: devcluster.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleDefinitionId['AcrPull'].id
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vnet1'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet1'
        properties:{
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg1.id
          }
        }
      }
    ]
  }
}
resource nsg1 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg1'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAnyRDPInbound'
        properties: {
          description: 'Allow inbound RDP traffic from the Internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAnySSHInbound'
        properties: {
          description: 'Allow inbound SSH traffic from the Internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource LinuxVMPIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'pip-1-LinuxVM'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource LinuxVMNIC 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nic-LinuxVM-1'
  location: location
  properties: {
          ipConfigurations: [
            {
              name: 'ipconfig-1-nic-1-LinuxVM'
              properties: {
                privateIPAllocationMethod: 'Dynamic'
                publicIPAddress: {
                  id: LinuxVMPIP.id
                }
                subnet: {
                  id: vnet.properties.subnets[0].id
                }
              }
            }
          ]
  }
}

resource LinuxVM 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: 'LinuxVM'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      osDisk: {
        name: 'linuxVM-OSDisk'
        caching: 'ReadWrite'
        createOption: 'fromImage'
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: LinuxVMNIC.id
        }
      ]
    }
    osProfile: {
      computerName: 'LinuxVM'
      adminUsername: vmUsername
      adminPassword: vmPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
  }
}

resource LinuxVMCSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: LinuxVM
  name: 'cse-LinuxVM'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: 'curl -sL https://gist.githubusercontent.com/WayneHoggett-ACG/821b23445f007d200b231e0381b71b68/raw/LinuxKubeAdmin.sh | sudo bash'
    }
  }
}
