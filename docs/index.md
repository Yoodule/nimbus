# Nimbus

<p align="center">
  <strong>Your 24/7 Employee</strong> — The ultimate containerized orchestrator and unified semantic gateway for Model Context Protocol (MCP) servers.
</p>

---

## Overview Video

Here is a quick walkthrough of Nimbus in action, displaying how it provisions a virtual browser workspace, connects your MCP servers, and operates as your autonomous agent gateway.

<div class="video-container" style="position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; max-width: 100%; border-radius: 12px; margin: 24px 0;box-shadow: 0 4px 20px rgba(0,0,0,0.35);">
    <!-- Replace "YOUR_VIDEO_ID" with your actual YouTube Video ID -->
    <iframe src="https://www.youtube.com/embed/YOUR_VIDEO_ID" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0;"></iframe>
</div>

---

## Quick Start

Installing the Nimbus environment takes just a single command. The installer automatically checks your system architecture, installs Astral's `uv` (if missing), configures your paths, and prepares your runtime.

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

Once installed, reload your shell and launch the entire stack:

```bash
source ~/.zshrc  # or ~/.bashrc
nimbus start
```

This boots up the complete containerized stack in the background:
- **Agent Dashboard**: http://localhost:3000
- **Semantic Gateway (MCP)**: http://localhost:8088/mcp
- **Virtual Browser Workspace (VNC)**: http://localhost:6080/vnc.html?autoconnect=true (Password: nimbusvnc)
- **Vector Search Database (Qdrant)**: http://localhost:6333
- **Relational Storage (PostgreSQL)**: Running on port 5433

---

## CLI Reference

The `nimbus` CLI allows you to control the lifecycle of your local containerized employee workspace easily.

| Command | Action | Description |
|:---|:---|:---|
| `nimbus start` | Boot services | Provisions and starts all Docker containers (postgres, qdrant, gateway, dashboard). |
| `nimbus start --build` | Re-build & Boot | Pulls code modifications, rebuilds docker images, and boots services cleanly. |
| `nimbus stop` | Tear down | Safely terminates all container services and frees system ports. |
| `nimbus status` | Health check | Queries and displays the live health and port mappings of the running services. |
| `nimbus upgrade` | Upgrade installation | Pulls the latest binaries and upgrades the wrapper setup dynamically. |
| `nimbus logs` | Tail logs | Streams live output from the semantic gateway and background MCP servers. |

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

The gateway exposes three main endpoints to models (under the namespace `nimbus-utility-mcp`):

1. **find_tools**: Searches across all servers semantically. Instead of sending hundreds of tools to a model, the model queries `find_tools` with a prompt like "browse linkedin" to fetch only the relevant tool schemas.
2. **execute_tool**: Executes any tool on any registered server dynamically.
3. **chain_tools**: Chains multiple steps together sequentially (e.g. searching google -> reading text -> sending a whatsapp message) in a single API roundtrip.

---

## Stateful OAuth Flow

Nimbus natively handles OAuth 2.1 authentication (PKCE, token exchanges, callback lifespans) for tools requiring user verification (e.g. Notion, Apollo, Zoho). The gateway automatically halts execution, prompts authorization in a beautiful custom-branded template, and resumes tool execution seamlessly once token verification succeeds.
