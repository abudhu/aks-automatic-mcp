@description('Name of the API Management service instance')
param serviceName string

@description('Azure region for API Management')
param location string = resourceGroup().location

@description('Publisher name displayed in the APIM developer portal')
param publisherName string

@description('Publisher contact email')
param publisherEmail string

@description('SKU tier for the APIM instance')
@allowed([
  'Consumption'
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Developer'

@description('Capacity (scale unit count) for the selected SKU')
@minValue(1)
param skuCapacity int = 1

@description('Public base URL of the MCP Weather server (e.g. https://mcp.example.com)')
param mcpBackendUrl string

@description('API suffix appended to the gateway URL (https://<name>.azure-api.net/<suffix>)')
param apiSuffix string = 'mcp-weather'

@description('Friendly display name for the published API')
param apiDisplayName string = 'MCP Weather API'

@description('API description shown in the developer portal')
param apiDescription string = 'Routes requests to the MCP Weather server running in AKS.'

@description('Require callers to provide an APIM subscription key')
param apiSubscriptionRequired bool = false

var backendId = 'mcp-weather-backend'
var apiName = apiSuffix
var policyContent = '<policies>\n  <inbound>\n    <base />\n    <set-backend-service backend-id="${backendId}" />\n  </inbound>\n  <backend>\n    <base />\n  </backend>\n  <outbound>\n    <base />\n  </outbound>\n  <on-error>\n    <base />\n  </on-error>\n</policies>'

resource apim 'Microsoft.ApiManagement/service@2022-08-01' = {
  name: serviceName
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    publisherName: publisherName
    publisherEmail: publisherEmail
  }
}

resource backend 'Microsoft.ApiManagement/service/backends@2022-08-01' = {
  parent: apim
  name: backendId
  properties: {
    url: mcpBackendUrl
    protocol: 'https'
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2022-08-01' = {
  parent: apim
  name: apiName
  properties: {
    displayName: apiDisplayName
    description: apiDescription
    path: apiSuffix
    apiRevision: '1'
    subscriptionRequired: apiSubscriptionRequired
    protocols: [
      'https'
    ]
  }
  dependsOn: [
    backend
  ]
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2022-08-01' = {
  parent: api
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: policyContent
  }
}

resource operation 'Microsoft.ApiManagement/service/apis/operations@2022-08-01' = {
  parent: api
  name: 'invoke-mcp-weather'
  properties: {
    displayName: 'Invoke MCP Weather'
    method: 'POST'
    urlTemplate: '/'
    description: 'Calls the MCP Weather server backend with the provided payload.'
    request: {
      queryParameters: []
      headers: []
      representations: [
        {
          contentType: 'application/json'
        }
      ]
    }
    responses: [
      {
        statusCode: 200
        description: 'Successful response from the MCP Weather server.'
        representations: [
          {
            contentType: 'application/json'
          }
        ]
      }
    ]
  }
}

@description('Gateway URL for invoking APIs')
output gatewayUrl string = apim.properties.gatewayUrl

@description('Developer portal URL')
output developerPortalUrl string = apim.properties.portalUrl

@description('Base invoke URL for the MCP Weather API')
output apiInvokeUrl string = '${apim.properties.gatewayUrl}/${apiSuffix}'
