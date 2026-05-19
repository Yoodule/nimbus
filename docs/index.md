# Nimbus Gateway

Unified MCP proxy gateway with semantic tool discovery and OAuth management. Aggregates multiple MCP servers (HTTP and stdio) into a single endpoint with Qdrant-powered vector search.

## Quick Start

```bash
# 1. Setup
cp .env.example .env   # add OPENROUTER_API_KEY, QDRANT_URL

# 2. Start everything (Qdrant + Playwright + LinkedIn + Gateway)
make dev

# 3. Approve OAuth prompts in browser (Notion, Apollo, Zoho)
#    Tokens are in-memory — re-approve on restart until persistent storage is added
```

The gateway will be available at `http://localhost:8088/mcp`.

## Manual Start

```bash
# Start dependencies individually
docker start qdrant || docker run -d --name qdrant -p 6333:6333 qdrant/qdrant:latest
npx @playwright/mcp@latest --port 3100 &

# Start gateway
source .env && uv run python -m nimbus_gateway.server
```

## Configuration

### `mcp.json` — Server Registry

Supports both HTTP (`url`) and stdio (`command`) servers:

```json
{
  "mcpServers": {
    "upwork-mcp": {
      "url": "http://localhost:8006/mcp",
      "transport": "streamable-http"
    },
    "notion-mcp": {
      "url": "https://mcp.notion.com/mcp",
      "transport": "streamable-http",
      "auth": "oauth"
    },
    "linkedin-mcp": {
      "command": "/path/to/uv",
      "args": ["run", "-m", "linkedin_mcp_server", "--transport", "stdio"]
    }
  }
}
```

### `.env` — Environment

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENROUTER_API_KEY` | Embeddings API key | Required |
| `QDRANT_URL` | Qdrant endpoint | `http://qdrant:6333` |
| `GATEWAY_PORT` | Gateway port | `8088` |
| `EMBEDDING_MODEL` | Model for tool embeddings | `openai/text-embedding-3-small` |

## Architecture

```
┌──────────────────────────────────────────┐
│            Nimbus Gateway :8088          │
│                                          │
│  ┌────────────┐  ┌───────────────────┐   │
│  │ find_tools │  │   create_proxy()  │   │
│  │ execute    │  │                   │   │
│  │ chain      │  │  upwork    :8006  │   │
│  └────────────┘  │  whatsapp  :8007  │   │
│                  │  notion    oauth  │   │
│  ┌────────────┐  │  apollo    oauth  │   │
│  │  Qdrant    │  │  zoho_crm  stdio │   │
│  │  Indexer   │  │  playwright:3100  │   │
│  │  (search)  │  │  linkedin  stdio  │   │
│  └────────────┘  └───────────────────┘   │
└──────────────────────────────────────────┘
         │
         ▼
┌──────────────┐
│   Qdrant     │
│   :6333      │
│  (vectors)   │
└──────────────┘
```

## Tools

| Tool | Description |
|------|-------------|
| `find_tools` | Semantic search across all servers. Pass `*` for all, or a natural query like `"send whatsapp message"` |
| `execute_tool` | Execute any tool on any connected server by name |
| `chain_tools` | Chain multiple tools sequentially with `${step.key}` references between steps |

## Auth

- **OAuth servers** (Notion, Apollo, Zoho): Set `"auth": "oauth"` in `mcp.json`. FastMCP handles the full OAuth 2.1 flow (RFC 9728 discovery, PKCE, token exchange).
- **Local servers** (Upwork, WhatsApp): No auth needed — they run locally with their own session management.
- **Callback branding**: OAuth pages show the Nimbus logo and title.

## Makefile

```bash
make dev          # Start deps + gateway (full local stack)
make dev-deps     # Start Qdrant, Playwright, LinkedIn only
make dev-stop     # Stop all dependencies
make test         # Run 33 unit tests
make test-gitops  # Validate K8s manifests (kustomize + kubeconform + conftest)
make test-all     # Run all tests
```

## Production (GitOps)

Deployed via ArgoCD + Kustomize on AKS.

| Subdomain | Service |
|-----------|---------|
| `gateway.nimbus.yoodule.com` | MCP endpoint |
| `qdrant.nimbus.yoodule.com` | Qdrant dashboard |

```bash
kubectl apply -f gitops/argocd/app-gateway.yaml
kubectl apply -f gitops/argocd/app-qdrant.yaml
```

## Project Structure

```
nimbus-gateway/
├── src/nimbus_gateway/
│   ├── server.py        # FastMCP gateway + lifespan + branding
│   ├── config.py        # Settings + mcp.json loader
│   ├── indexer.py        # Qdrant tool indexer + embeddings
│   └── tools.py          # find/execute/chain tool implementations
├── servers/              # Bundled MCP servers (e.g. whatsapp-mcp)
├── static/favicon.svg    # Nimbus logo
├── gitops/               # K8s manifests + policies
├── tests/                # 33 unit tests
├── mcp.json              # Server registry
└── Makefile              # Dev workflow
```
