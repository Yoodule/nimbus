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

## Get Nimbus

<div style="background: #000000; border: 1px solid #333333; border-radius: 12px; padding: 40px 32px; margin: 32px 0; text-align: center;">
  <h3 style="color: #ffffff; font-size: 1.7em; font-weight: 700; margin: 0 0 16px 0; letter-spacing: -0.02em;">One command. No sign-up.</h3>
  <p style="color: #a3a3a3; font-size: 1.1em; line-height: 1.6; margin: 0 auto 24px auto; max-width: 540px;">
    Nimbus installs the CLI, the gateway, and every bundled MCP server with a single curl. SHA256-verified, runs locally, and provisions the full Docker stack.
  </p>
  <div style="background: #0a0a0a; border: 1px solid #262626; border-radius: 8px; padding: 16px 20px; margin: 0 auto 24px auto; max-width: 640px; text-align: left; font-family: 'SF Mono', Menlo, Consolas, monospace; font-size: 0.92em; color: #e5e5e5; overflow-x: auto; white-space: nowrap;">
    <span style="color: #737373;">$ </span>curl -fsSL https://nimbus.yoodule.com/install.sh | bash
  </div>
  <a href="download/" style="display: inline-flex; align-items: center; gap: 8px; background: #ffffff; color: #000000; text-decoration: none; font-weight: 600; padding: 14px 32px; border-radius: 8px; font-size: 1.05em; margin-right: 12px;">
    Download for macOS / Linux / Windows
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"></line><polyline points="12 5 19 12 12 19"></polyline></svg>
  </a>
</div>

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
