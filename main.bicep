@description('The name of the AKS Automatic cluster')
param clusterName string

@description('The location for the AKS Automatic cluster')
param location string = resourceGroup().location

@description('The DNS prefix for the cluster')
param dnsPrefix string = clusterName

@description('Enable Azure Monitor for the cluster')
param enableMonitoring bool = true

@description('Tags to apply to the cluster')
param tags object = {}

// AKS Automatic Cluster
resource aksAutomatic 'Microsoft.ContainerService/managedClusters@2024-05-01' = {
  name: clusterName
  location: location
  tags: tags
  sku: {
    name: 'Automatic'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 3
        vmSize: 'Standard_DS4_v2'
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
        minCount: 3
        maxCount: 10
        vnetSubnetID: null
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      networkPolicy: 'azure'
      loadBalancerSku: 'standard'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
    }
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
      nodeOSUpgradeChannel: 'NodeImage'
    }
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
      imageCleaner: {
        enabled: true
        intervalHours: 168
      }
      defender: {
        logAnalyticsWorkspaceResourceId: enableMonitoring ? logAnalyticsWorkspace.id : null
        securityMonitoring: {
          enabled: enableMonitoring
        }
      }
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
      azurepolicy: {
        enabled: true
      }
      omsagent: enableMonitoring ? {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      } : {
        enabled: false
      }
    }
  }
}

// Log Analytics Workspace for monitoring
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableMonitoring) {
  name: '${clusterName}-logs'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Outputs
output clusterName string = aksAutomatic.name
output clusterId string = aksAutomatic.id
output clusterFqdn string = aksAutomatic.properties.fqdn
output oidcIssuerUrl string = aksAutomatic.properties.oidcIssuerProfile.issuerURL
output kubeletIdentityObjectId string = aksAutomatic.properties.identityProfile.kubeletidentity.objectId
output workspaceId string = enableMonitoring ? logAnalyticsWorkspace.id : ''
