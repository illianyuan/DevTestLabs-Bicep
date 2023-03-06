@description('The name of the new lab instance to be created')
param labName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the lab virtual network resource')
param labVirtualNetworkName string

@description('Shared services workstations subnet name')
param virtualMachinesSubnetName string

@description('The access rights to be granted to the user when provisioning an environment')
@allowed([
  'Contributor'
  'Reader'
])
param roleAccessRightsPermission string

param vnetResourceID string = '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${labVirtualNetworkName}'
param subNetResourceID string = '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${labVirtualNetworkName}/subnets/${virtualMachinesSubnetName}'

resource lab 'Microsoft.DevTestLab/labs@2018-09-15' = {
  name: labName
  location: location
  tags: {
    tagName1: ''
    tagName2: ''
  }
  properties: {
    environmentPermission: roleAccessRightsPermission
    labStorageType: 'Premium'
    mandatoryArtifactsResourceIdsLinux: []
    mandatoryArtifactsResourceIdsWindows: []
    premiumDataDisks: 'Disabled'
    announcement: {
      enabled: 'Disabled'
      expired: false
    }
    support: {
      enabled: 'Enabled'
      markdown: 'TBC'
    }
  }
}

resource labVirtualNetwork 'Microsoft.DevTestLab/labs/virtualnetworks@2018-09-15' = {
  parent: lab
  name: labVirtualNetworkName
  tags: {
    tagName1: ''
    tagName2: ''
  }
  properties: {
    allowedSubnets: [
      {
        resourceId: subNetResourceID
        labSubnetName: virtualMachinesSubnetName
        allowPublicIp: 'Allow'
      }
    ]
    externalProviderResourceId: vnetResourceID
    subnetOverrides: [
      {
        resourceId: subNetResourceID
        labSubnetName: virtualMachinesSubnetName
        useInVmCreationPermission: 'Allow'
        usePublicIpAddressPermission: 'Allow'
        sharedPublicIpAddressConfiguration: {
          allowedPorts: [
            {
              transportProtocol: 'Tcp'
              backendPort: 3389
            }
            {
              transportProtocol: 'Tcp'
              backendPort: 22
            }
          ]
        }
      }
    ]
  }
}

resource labsVmsShutdown 'microsoft.devtestlab/labs/schedules@2018-09-15' = {
  parent: lab
  name: 'labvmsshutdown'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'LabVmsShutdownTask'
    dailyRecurrence: {
      time: '1930'
    }
    timeZoneId: 'New Zealand Standard Time'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 30
    }
  }
}

resource labsVmAutostart 'microsoft.devtestlab/labs/schedules@2018-09-15' = {
  parent: lab
  name: 'labvmautostart'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'LabVmsStartupTask'
    weeklyRecurrence: {
      weekdays: [
        'Monday'
        'Tuesday'
        'Wednesday'
        'Thursday'
        'Friday'
      ]
      time: '0700'
    }
    timeZoneId: 'New Zealand Standard Time'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 0
    }
  }
}

resource labsPublicEnvironmentRepo 'microsoft.devtestlab/labs/artifactsources@2018-09-15' = {
  parent: lab
  name: 'public environment repo'
  properties: {
    displayName: 'Public Environment Repo'
    uri: 'https://github.com/Azure/azure-devtestlab.git'
    sourceType: 'GitHub'
    armTemplateFolderPath: '/Environments'
    branchRef: 'master'
    status: 'Disabled'
  }
}

resource labsPublicRepo 'microsoft.devtestlab/labs/artifactsources@2018-09-15' = {
  parent: lab
  name: 'public repo'
  properties: {
    displayName: 'Public Artifact Repo'
    uri: 'https://github.com/Azure/azure-devtestlab.git'
    sourceType: 'GitHub'
    folderPath: '/Artifacts'
    branchRef: 'master'
    status: 'Enabled'
  }
}

resource policySetParent 'Microsoft.DevTestLab/labs/policysets@2018-09-15' = {
  parent: lab
  name: 'policySetParent'
  location: location
  properties: {
    
  }
}

resource allowedVmSizesPolicies 'Microsoft.DevTestLab/labs/policysets/policies@2018-09-15' = {
  name: 'allowedVmSizesPolicy'
  location: location
  parent: policySetParent
  properties: {
    evaluatorType: 'AllowedValuesPolicy'
    factName: 'LabVmSize'
    status: 'Enabled'
    threshold: 'Standard_D2_v3, Standard_D4_v3, Standard_D8_v3, Standard_E2_v4, Standard_E4_v4, Standard_E8_v4'
    }
  }

resource allowedVmsPerLabPolicies 'Microsoft.DevTestLab/labs/policysets/policies@2018-09-15' = {
  name: 'allowedVmsPerLabPolicy'
  location: location
  parent: policySetParent
  properties: {
    evaluatorType: 'MaxValuePolicy'
    factName: 'LabVmCount'
    status: 'Enabled'
    threshold: '20'
    }
  }

output labId string = lab.id

