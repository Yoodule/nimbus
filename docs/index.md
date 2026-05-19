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

## Quick Start

Installing the Nimbus environment takes just a single command. The installer automatically checks your system architecture, installs Astral's `uv` (if missing), configures your paths, and prepares your runtime.

<div class="terminal-copy-container" style="display: flex; align-items: center; justify-content: space-between; background: rgba(30, 30, 30, 0.75); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 12px; padding: 16px 20px; margin: 24px 0; font-family: 'Fira Code', 'Courier New', Courier, monospace; box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25); backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px); transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); position: relative; overflow: hidden;">
  <div style="display: flex; align-items: center; gap: 12px; flex-grow: 1; min-width: 0;">
    <span style="color: #4f46e5; font-weight: bold; user-select: none;">$</span>
    <code id="install-command-text" style="color: #e2e8f0; font-size: 0.95em; white-space: nowrap; overflow-x: auto; flex-grow: 1; padding: 0; background: transparent; border: none; scrollbar-width: none;">curl -fsSL https://nimbus.yoodule.com/install.sh | bash</code>
  </div>
  <button id="copy-btn" onclick="copyInstallCommand()" style="background: rgba(255, 255, 255, 0.08); border: 1px solid rgba(255, 255, 255, 0.15); border-radius: 6px; padding: 8px 14px; color: #e2e8f0; cursor: pointer; font-size: 0.85em; font-family: inherit; font-weight: 500; display: flex; align-items: center; gap: 6px; transition: all 0.2s ease; user-select: none; outline: none; margin-left: 12px;">
    <svg id="copy-icon" viewBox="0 0 24 24" width="16" height="16" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round">
      <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
      <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
    </svg>
    <span id="copy-text">Copy</span>
  </button>
</div>

<style>
.terminal-copy-container:hover {
  border-color: rgba(99, 102, 241, 0.4) !important;
  box-shadow: 0 12px 40px rgba(99, 102, 241, 0.15) !important;
  transform: translateY(-2px);
}
#copy-btn:hover {
  background: rgba(255, 255, 255, 0.15) !important;
  border-color: rgba(255, 255, 255, 0.3) !important;
  color: #fff !important;
}
#copy-btn:active {
  transform: scale(0.95);
}
#install-command-text::-webkit-scrollbar {
  display: none;
}
</style>

<script>
function copyInstallCommand() {
  const text = 'curl -fsSL https://nimbus.yoodule.com/install.sh | bash';
  navigator.clipboard.writeText(text).then(() => {
    const btn = document.getElementById('copy-btn');
    const icon = document.getElementById('copy-icon');
    const textEl = document.getElementById('copy-text');

    btn.style.background = 'rgba(34, 197, 94, 0.2)';
    btn.style.borderColor = 'rgba(34, 197, 94, 0.4)';
    btn.style.color = '#4ade80';
    textEl.textContent = 'Copied!';

    icon.innerHTML = '<polyline points="20 6 9 17 4 12"></polyline>';

    setTimeout(() => {
      btn.style.background = 'rgba(255, 255, 255, 0.08)';
      btn.style.borderColor = 'rgba(255, 255, 255, 0.15)';
      btn.style.color = '#e2e8f0';
      textEl.textContent = 'Copy';
      icon.innerHTML = '<rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2 2v1"></path>';
    }, 2000);
  }).catch(err => {
    console.error('Failed to copy: ', err);
  });
}
</script>

Once installed, reload your shell and launch the entire stack:

```bash
source ~/.zshrc  # or ~/.bashrc
nimbus start
```

This boots up the complete containerized stack in the background:

- **Agent Dashboard**: <http://localhost:3000>
- **Semantic Gateway (MCP)**: <http://localhost:8088/mcp>
- **Virtual Browser Workspace (VNC)**: <http://localhost:6080/vnc.html?autoconnect=true> (Password: nimbusvnc)
- **Vector Search Database (Qdrant)**: <http://localhost:6333>
- **Relational Storage (PostgreSQL)**: Running on port 5433

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
