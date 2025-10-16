# AKS Automatic Deployment with Bicep

This template deploys an AKS Automatic cluster with recommended configurations for production workloads.

## What is AKS Automatic?

AKS Automatic is a new mode for Azure Kubernetes Service that provides:
- Preset configurations optimized for production
- Automatic node provisioning and scaling
- Built-in security and monitoring
- Simplified management experience

## Features Included

This template deploys an AKS Automatic cluster with:

- ✅ **Automatic Mode** - Simplified cluster management
- ✅ **Azure CNI Overlay** - Efficient networking with overlay networking
- ✅ **Auto-scaling** - Automatic node scaling (3-10 nodes)
- ✅ **Automatic Upgrades** - Stable channel for cluster and node OS
- ✅ **Workload Identity** - Modern identity solution for pods
- ✅ **OIDC Issuer** - OpenID Connect for authentication
- ✅ **Azure Key Vault Secrets Provider** - Secure secret management
- ✅ **Azure Policy** - Governance and compliance
- ✅ **Azure Monitor** - Container insights and monitoring
- ✅ **Microsoft Defender** - Security monitoring
- ✅ **Image Cleaner** - Automatic cleanup of unused images

## Prerequisites

- Azure CLI 2.50.0 or later
- Bicep CLI 0.20.0 or later
- An Azure subscription
- Appropriate permissions to create resources

## Deployment

### 1. Login to Azure

```bash
az login
az account set --subscription <subscription-id>
```

### 2. Create a Resource Group

```bash
az group create --name rg-aks-automatic --location eastus
```

### 3. Deploy the AKS Template

#### Option A: Using the parameter file

```bash
az deployment group create \
  --resource-group rg-aks-automatic \
  --template-file main.bicep \
  --parameters main.bicepparam
```

#### Option B: Using inline parameters

```bash
az deployment group create \
  --resource-group rg-aks-automatic \
  --template-file main.bicep \
  --parameters clusterName=myakscluster \
  --parameters location=eastus \
  --parameters enableMonitoring=true
```

### 4. Get Cluster Credentials

```bash
az aks get-credentials --resource-group rg-aks-automatic --name aks-automatic-cluster
```

### 5. Verify the Deployment

```bash
kubectl get nodes
kubectl get pods -A
```

## Publish MCP Weather API with API Management

Use `apim-mcp.bicep` to provision an API Management instance that fronts the MCP Weather server.

```bash
az deployment group create \
  --resource-group rg-aks-automatic \
  --template-file apim-mcp.bicep \
  --parameters apim-mcp.bicepparam \
  --parameters mcpBackendUrl=https://<ingress-or-load-balancer-for-mcp>
```

Update `apim-mcp.bicepparam` with your publisher details, SKU preferences, and the public endpoint that exposes the MCP Weather server running in AKS before running the deployment.

## Create GPT-4.1 Agent in Azure AI Foundry

1. Capture the API Management invoke URL and (optionally) subscription key for the weather API.
2. Configure an Azure AI Foundry project connected to an Azure OpenAI resource with a `gpt-4.1` deployment.
3. Populate the environment variables listed in `agents/README.md` or update Cell 3 in `deploy-aks-automatic.ipynb`.
4. Run the agent creation steps in the notebook (Step 12 installs dependencies, Step 13 creates the agent).
5. Use Step 14 to invoke the agent and verify it returns weather data. The raw response is saved to `agents/agent_invoke_response.json`.
6. Note the generated agent ID in `agents/agent_response.json` for subsequent conversations or run orchestration inside Azure AI Foundry.

## Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `clusterName` | string | Name of the AKS cluster | Required |
| `location` | string | Azure region | Resource group location |
| `dnsPrefix` | string | DNS prefix for the cluster | Same as clusterName |
| `enableMonitoring` | bool | Enable Azure Monitor | true |
| `tags` | object | Tags to apply to resources | {} |

## Outputs

| Output | Description |
|--------|-------------|
| `clusterName` | Name of the deployed cluster |
| `clusterId` | Resource ID of the cluster |
| `clusterFqdn` | Fully qualified domain name |
| `oidcIssuerUrl` | OIDC issuer URL for workload identity |
| `kubeletIdentityObjectId` | Object ID of the kubelet identity |
| `workspaceId` | Log Analytics workspace ID |

## Customization

### Change Node VM Size

Edit the `vmSize` parameter in the agent pool profile:

```bicep
vmSize: 'Standard_DS4_v2'  // Change to your preferred size
```

### Adjust Auto-scaling Limits

Modify the `minCount` and `maxCount` in the agent pool profile:

```bicep
minCount: 3   // Minimum nodes
maxCount: 10  // Maximum nodes
```

### Disable Monitoring

Set the `enableMonitoring` parameter to `false`:

```bash
az deployment group create \
  --resource-group rg-aks-automatic \
  --template-file main.bicep \
  --parameters enableMonitoring=false
```

## Clean Up

To delete all resources:

```bash
az group delete --name rg-aks-automatic --yes --no-wait
```

## Additional Resources

- [AKS Automatic Documentation](https://learn.microsoft.com/azure/aks/automatic)
- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [AKS Best Practices](https://learn.microsoft.com/azure/aks/best-practices)
- [API Management Documentation](https://learn.microsoft.com/azure/api-management/)
- [Azure AI Foundry Agents](https://learn.microsoft.com/azure/ai-services/agents/overview)

## License

This template is provided as-is under the MIT license.
