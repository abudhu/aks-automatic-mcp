"""Create an Azure AI Foundry Agent that calls the MCP Weather API through Azure API Management.

Prerequisites:
- The MCP Weather workload is reachable at the external URL you supplied to API Management.
- API Management is deployed with the `apim-mcp.bicep` template and exposes the weather API.
- You have an Azure AI Foundry project with an Azure OpenAI connection that includes a GPT-4.1 deployment.
- Environment variables listed below are populated before running the script.

Environment variables:
- AZURE_AI_PROJECT_ENDPOINT: Full endpoint of your Azure AI Foundry project (e.g. https://<region>.api.azureml.ms)
- AZURE_AI_PROJECT_ID: Project ID (UUID) inside Azure AI Foundry.
- AZURE_AI_RESOURCE_ID: Resource ID of the Azure AI Foundry hub/workspace hosting the project.
- AZURE_OPENAI_DEPLOYMENT: Name of the GPT-4.1 deployment in the connected Azure OpenAI resource.
- APIM_WEATHER_API_URL: HTTPS URL for invoking the MCP Weather API (e.g. https://<service>.azure-api.net/mcp-weather).
- APIM_SUBSCRIPTION_KEY: Subscription key if the API requires one (leave unset when subscriptionRequired=false).

Usage:
    pip install -r requirements.txt
    python create_agent.py
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Dict, Optional

import requests
from azure.identity import DefaultAzureCredential

API_VERSION = "2024-10-01-preview"
TOKEN_SCOPE = "https://cognitiveservices.azure.com/.default"
OUTPUT_PATH = Path(__file__).parent / "agent_response.json"


def _get_env(name: str, required: bool = True) -> Optional[str]:
    value = os.getenv(name)
    if required and not value:
        raise EnvironmentError(f"Environment variable {name} is required.")
    return value


def build_agent_payload(apim_url: str, apim_subscription_key: Optional[str], model_deployment: str) -> Dict:
    """Craft the agent definition payload."""
    headers = {}
    if apim_subscription_key:
        headers["Ocp-Apim-Subscription-Key"] = apim_subscription_key

    return {
        "name": "mcp-weather-agent",
        "description": "Agent that uses GPT-4.1 and the MCP Weather API to answer weather questions.",
        "model": model_deployment,
        "instructions": (
            "You are a weather assistant. When the user requests weather information, call the "
            "`mcp_weather_via_apim` tool and pass the location as JSON {\"location\": \"city\"}. "
            "Return a concise summary of the weather based on the tool response."
        ),
        "tools": [
            {
                "type": "web_api",
                "name": "mcp_weather_via_apim",
                "description": "Calls the MCP Weather API exposed through Azure API Management.",
                "spec": {
                    "method": "POST",
                    "url": apim_url,
                    "headers": headers,
                    "input_schema": {
                        "type": "object",
                        "properties": {
                            "location": {
                                "type": "string",
                                "description": "City, postal code, or location recognized by the MCP Weather service."
                            }
                        },
                        "required": ["location"]
                    },
                    "output_schema": {
                        "type": "object",
                        "properties": {
                            "content": {
                                "type": "string",
                                "description": "Weather report returned by the MCP Weather server."
                            }
                        }
                    }
                }
            }
        ]
    }


def create_agent() -> Dict:
    endpoint = _get_env("AZURE_AI_PROJECT_ENDPOINT")
    project_id = _get_env("AZURE_AI_PROJECT_ID")
    resource_id = _get_env("AZURE_AI_RESOURCE_ID")
    model_deployment = _get_env("AZURE_OPENAI_DEPLOYMENT")
    apim_url = _get_env("APIM_WEATHER_API_URL")
    subscription_key = _get_env("APIM_SUBSCRIPTION_KEY", required=False)

    credential = DefaultAzureCredential()
    token = credential.get_token(TOKEN_SCOPE)

    payload = build_agent_payload(apim_url, subscription_key, model_deployment)

    headers = {
        "Authorization": f"Bearer {token.token}",
        "Content-Type": "application/json",
        "ai-resource-id": resource_id,
        "ai-project-id": project_id,
    }

    url = f"{endpoint}/openai/agents?api-version={API_VERSION}"
    response = requests.post(url, headers=headers, data=json.dumps(payload), timeout=60)
    response.raise_for_status()

    data = response.json()
    OUTPUT_PATH.write_text(json.dumps(data, indent=2))
    print(f"Agent created. Response written to {OUTPUT_PATH}.")
    return data


if __name__ == "__main__":
    create_agent()
