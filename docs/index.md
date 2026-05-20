# Nimbus

<p align="center">
  <strong>Your 24/7 Employee</strong> — Built by <a href="https://www.linkedin.com/in/sundayj1213/?utm_source=nimbus&utm_medium=docs&utm_campaign=homepage" target="_blank">Sunday Johnson</a> at <a href="https://yoodule.com?utm_source=nimbus&utm_medium=docs&utm_campaign=homepage" target="_blank">Yoodule</a>.
  <br>
  The ultimate containerized orchestrator and unified semantic gateway for Model Context Protocol (MCP) servers.
</p>

---

## Overview Video

Here is a quick walkthrough of Nimbus in action, displaying how it provisions a virtual browser workspace, connects your MCP servers, and operates as your autonomous agent gateway.

<div class="video-container" style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; border-radius: 12px; margin: 24px 0;box-shadow: 0 4px 20px rgba(0,0,0,0.35);">
    <!-- Replace "YOUR_VIDEO_ID" with your actual YouTube Video ID -->
    <iframe src="https://www.youtube.com/embed/YOUR_VIDEO_ID" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0;"></iframe>
</div>

---

## Early Access Onboarding

!!! important "Direct Downloads Disabled"
    Direct downloads of the Nimbus installation scripts are currently disabled.

    To ensure everyone interested gets the best out of the tool, we would love to have a session with you to understand your goals and help set things up to maximize the best results.

    To schedule your onboarding session, please send an email to: **[hello.nimbus@yoodule.com](mailto:hello.nimbus@yoodule.com)**

*(Once your onboarding is complete, you will be provided with your personalized API access and installation commands).*

---

## CLI Reference

The `nimbus` CLI allows you to control the lifecycle of your local containerized employee workspace easily.

| Command | Action | Description |
|:---|:---|:---|
| `nimbus start` | Boot services | Provisions and starts all Docker containers (postgres, qdrant, gateway, dashboard). |
| `nimbus start --build` | Re-build & Boot | Pulls code modifications, rebuilds docker images, and boots services cleanly. |
| `nimbus stop` | Tear down | Safely terminates all container services and frees system ports. |
| `nimbus upgrade` | Upgrade installation | Pulls the latest binaries and upgrades the wrapper setup dynamically. |
| `nimbus uninstall` | Uninstall | Removes the Nimbus CLI, containers, and cleans up all associated configurations. |
| `nimbus config <subcommand>` | Configure environment | Manage configuration environment variables (list, get, set, unset). |
| `nimbus mcp <subcommand>` | Manage MCP servers | Manage Model Context Protocol (MCP) server configurations (list, get, set, remove). |

### Configuration Management (`nimbus config`)

Manage local environment variables stored in `~/.nimbus/.env`:

- **`nimbus config list`**: Lists all active environment variables (e.g. `OPENROUTER_API_KEY`, `NIMBUS_URL`).
- **`nimbus config get <KEY>`**: Retrieve the value of a specific configuration key.
- **`nimbus config set <KEY> <VALUE>`**: Set or update a configuration key to a specific value.
- **`nimbus config unset <KEY>`**: Remove a configuration key from the local environment.

### MCP Server Management (`nimbus mcp`)

Manage Model Context Protocol (MCP) servers defined in `~/.nimbus/mcp.json`:

- **`nimbus mcp list`**: List all configured stdio or HTTP-based MCP servers and their execution details.
- **`nimbus mcp get <NAME>`**: Retrieve the raw JSON configuration of a specific MCP server.
- **`nimbus mcp set <NAME> <CONFIG_JSON>`**: Add or update an MCP server. The configuration must be a valid JSON object matching the MCP server schema.
- **`nimbus mcp remove <NAME>`**: Remove an MCP server from the configuration.

---

## The Semantic Gateway (mcp.json)

Nimbus aggregates all your stdio and HTTP-based MCP servers into a single interface. When an AI model requests a capability, Nimbus dynamically discovers and executes the appropriate tool using vector embeddings stored in Qdrant.

Configure your active servers by modifying `mcp.json` in your Nimbus home directory:

```json
{
  "mcpServers": {
    "playwright-mcp": {
      "url": "http://localhost:3100/mcp",
      "transport": "streamable-http"
    },
    "notion-mcp": {
      "url": "https://mcp.notion.com/mcp",
      "transport": "streamable-http",
      "auth": "oauth"
    },
    "linkedin-mcp": {
      "command": "uv",
      "args": ["run", "-m", "linkedin_mcp_server", "--transport", "stdio"]
    }
  }
}
```

---

## Semantic Routing Capabilities

The gateway exposes four main endpoints to models (under the namespace `nimbus-utility-mcp`):

1. **list_servers**: Lists all configured MCP backend servers with their connection status and tool count.
2. **find_tools**: Searches across all servers semantically. Instead of sending hundreds of tools to a model, the model queries `find_tools` with a prompt like "browse linkedin" to fetch only the relevant tool schemas.
3. **execute_tool**: Executes any tool on any registered server dynamically.
4. **chain_tools**: Chains multiple steps together sequentially (e.g. searching google -> reading text -> sending a whatsapp message) in a single API roundtrip.

---

## Stateful OAuth Flow

Nimbus natively handles OAuth 2.1 authentication (PKCE, token exchanges, callback lifespans) for tools requiring user verification (e.g. Notion, Apollo, Zoho). The gateway automatically halts execution, prompts authorization in a beautiful custom-branded template, and resumes tool execution seamlessly once token verification succeeds.
