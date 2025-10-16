# Azure AI Foundry Agent (GPT-4.1) for MCP Weather

This folder contains helper assets for creating an Agent in Azure AI Foundry that uses the GPT-4.1 model and calls the MCP Weather service through Azure API Management.

## Contents

- `requirements.txt` – Python dependencies needed to run the helper script.
- `create_agent.py` – Creates or updates an Agent definition using the Azure AI Projects preview REST API.
- `agent_response.json` – Generated after running the script and captures the raw service response.

## Prerequisites

1. **Azure AI Foundry project** connected to an Azure OpenAI resource that has a GPT-4.1 deployment (for example `gpt-4.1`).
2. **API Management endpoint** published with `apim-mcp.bicep` so that the MCP Weather API is reachable from the internet.
3. **Azure CLI login** (`az login`) and permissions to call the Azure AI Projects endpoint.
4. **Python 3.10+** with ability to install packages listed in `requirements.txt`.

## Required environment variables

| Variable | Description |
|----------|-------------|
| `AZURE_AI_PROJECT_ENDPOINT` | Project endpoint (e.g. `https://eastus2.api.azureml.ms`) |
| `AZURE_AI_PROJECT_ID` | Project GUID from Azure AI Foundry |
| `AZURE_AI_RESOURCE_ID` | Full resource ID of the Azure AI hub/workspace |
| `AZURE_OPENAI_DEPLOYMENT` | Azure OpenAI deployment name for GPT-4.1 |
| `APIM_WEATHER_API_URL` | Invoke URL of the MCP Weather API in API Management |
| `APIM_SUBSCRIPTION_KEY` | (Optional) Subscription key if required by the API |

## Usage

```bash
cd agents
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
export AZURE_AI_PROJECT_ENDPOINT="https://<region>.api.azureml.ms"
export AZURE_AI_PROJECT_ID="<project-guid>"
export AZURE_AI_RESOURCE_ID="/subscriptions/.../resourceGroups/.../providers/Microsoft.MachineLearningServices/workspaces/..."
export AZURE_OPENAI_DEPLOYMENT="gpt-4_1"
export APIM_WEATHER_API_URL="https://<service>.azure-api.net/mcp-weather"
export APIM_SUBSCRIPTION_KEY="<key>"  # omit if API does not require subscriptions
python create_agent.py
```

After the script runs, review `agent_response.json` for the created agent ID. Store this identifier for later runs and invocations within Azure AI Foundry.
