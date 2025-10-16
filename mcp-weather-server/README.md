# MCP Weather Server

This project implements a minimal [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) server that exposes a single tool, `getWeather`, allowing Agents to retrieve the current weather for a requested location.

## Features

- 🧰 `getWeather` tool with an easy city/location argument
- 🌦️ Weather data powered by the free [wttr.in](https://wttr.in) service (no API key required)
- 🔌 Communicates over stdio so it can be embedded in any MCP-compatible host
- 🧱 Written in TypeScript with the official `@modelcontextprotocol/sdk`

## Prerequisites

- Node.js 18.18.0 or newer
- npm 9+ (comes with Node.js)

## Setup

```bash
cd mcp-weather-server
npm install
```

## Development

Start the server in watch mode:

```bash
npm run dev
```

## Build

Compile TypeScript to JavaScript for production:

```bash
npm run build
```

## Run

After building, launch the server (stdio transport):

```bash
npm start
```

The process will wait for MCP Agent connections on stdin/stdout.

## Tool Reference

| Tool | Description | Input Schema |
|------|-------------|--------------|
| `getWeather` | Returns the current weather summary for a location | `{ "location": "<city or query>" }` |

### Example Output

```
Current weather for Seattle:
- Conditions: Light rain
- Temperature: 12°C (feels like 10°C)
- Humidity: 93%
- Wind: 14 km/h
```

## Deploy to AKS Automatic

1. **Build the container image**

	```bash
	cd mcp-weather-server
	npm install
	npm run build
	docker build -t <your-registry>.azurecr.io/mcp-weather-server:latest .
	```

2. **Push to Azure Container Registry (ACR)**

	```bash
	az acr login --name <your-registry>
	docker push <your-registry>.azurecr.io/mcp-weather-server:latest
	```

3. **Allow the AKS cluster to pull from ACR**

	```bash
	az aks update \
	  --resource-group <your-aks-rg> \
	  --name <your-aks-cluster> \
	  --attach-acr <your-registry>
	```

4. **Deploy the workload to the cluster**

	Update `k8s/mcp-weather.yaml` with your image name if needed, then apply it:

	```bash
	kubectl apply -f ../k8s/mcp-weather.yaml
	```

5. **Verify the deployment**

	```bash
	kubectl get pods -l app=mcp-weather-server
	kubectl logs deploy/mcp-weather-server
	```

6. **Bridge the MCP Agent**

	- Run the Agent in the same pod as a sidecar or
	- Use `kubectl exec` to stream stdio between your Agent runtime and the MCP pod.
   
	Ensure the Agent process can reach the MCP server over stdin/stdout.

## Notes

- The server relies on the wttr.in public API; rate limits may apply for heavy usage.
- Add caching or swap in a paid weather provider if you need higher reliability.
