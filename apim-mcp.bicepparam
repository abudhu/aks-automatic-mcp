using './apim-mcp.bicep'

param serviceName = 'apim-mcp-weather'
param location = 'eastus'
param publisherName = 'Contoso Dev Team'
param publisherEmail = 'dev-team@example.com'
param skuName = 'Developer'
param skuCapacity = 1
param mcpBackendUrl = 'https://mcp-weather.contoso.com'
param apiSubscriptionRequired = false
