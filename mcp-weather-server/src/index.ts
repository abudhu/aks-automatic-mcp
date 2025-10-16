import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/transports/stdio';
import { Server } from '@modelcontextprotocol/sdk/server';
import { ToolInput, ToolResult } from '@modelcontextprotocol/sdk/types';

const server = new Server({
  name: 'mcp-weather-server',
  version: '0.1.0'
});

server.addTool({
  name: 'getWeather',
  description: 'Fetch the current weather for a city or location (powered by wttr.in).',
  inputSchema: {
    type: 'object',
    properties: {
      location: {
        type: 'string',
        description: 'City name, postal code, or geographic query supported by wttr.in.'
      }
    },
    required: ['location']
  }
}, async (args: ToolInput): Promise<ToolResult> => {
  const location = (args as { location?: string }).location?.trim();
  if (!location) {
    return {
      isError: true,
      content: [{ type: 'text', text: 'The "location" argument is required.' }]
    };
  }

  try {
    const response = await fetch(`https://wttr.in/${encodeURIComponent(location)}?format=j1`, {
      headers: {
        'Accept': 'application/json'
      }
    });

    if (!response.ok) {
      return {
        isError: true,
        content: [{ type: 'text', text: `Weather API request failed with status ${response.status}.` }]
      };
    }

    const payload = await response.json() as {
      current_condition?: Array<{
        temp_C?: string;
        weatherDesc?: Array<{ value?: string }>;
        humidity?: string;
        FeelsLikeC?: string;
        windspeedKmph?: string;
      }>;
    };

    const current = payload.current_condition?.[0];
    if (!current) {
      return {
        isError: true,
        content: [{ type: 'text', text: 'Weather data was not available for that location.' }]
      };
    }

    const description = current.weatherDesc?.[0]?.value ?? 'Unknown conditions';
    const temp = current.temp_C ?? 'N/A';
    const feelsLike = current.FeelsLikeC ?? 'N/A';
    const humidity = current.humidity ?? 'N/A';
    const wind = current.windspeedKmph ?? 'N/A';

    const report = `Current weather for ${location}:
- Conditions: ${description}
- Temperature: ${temp}°C (feels like ${feelsLike}°C)
- Humidity: ${humidity}%
- Wind: ${wind} km/h`;

    return {
      isError: false,
      content: [{ type: 'text', text: report }]
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return {
      isError: true,
      content: [{ type: 'text', text: `Failed to fetch weather: ${message}` }]
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
