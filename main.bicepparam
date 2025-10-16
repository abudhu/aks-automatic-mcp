using './main.bicep'

// Required parameters
param clusterName = 'aks-automatic-cluster'

// Optional parameters
param location = 'eastus'
param dnsPrefix = 'aksauto'
param enableMonitoring = true
param tags = {
  environment: 'dev'
  project: 'aks-automatic'
  managedBy: 'bicep'
}
