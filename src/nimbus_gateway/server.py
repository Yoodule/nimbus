"""Nimbus Gateway — Unified MCP gateway with semantic tool discovery.

Creates a central proxy from mcp.json and exposes find_tools, execute_tool,
and chain_tools over streamable-http.

Refactored from nimbus_auth-mcp/servers/gateway/server.py.
"""

import json
import logging
import os
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

from dotenv import load_dotenv
from fastmcp import Context, FastMCP
from starlette.requests import Request
from starlette.responses import JSONResponse
from qdrant_client import QdrantClient

from nimbus_gateway.account_pool import AccountScopedManagerPool
from nimbus_gateway.config import GatewaySettings, load_mcp_config
from nimbus_gateway.identity import NimbusIdentityResolver
from nimbus_gateway.indexer import ToolIndexer
from nimbus_gateway.proxy_manager import LazyServerManager
from nimbus_gateway.tools import (
    chain_tools as _chain_tools,
    execute_tool as _execute_tool,
    find_tools as _find_tools,
    list_servers as _list_servers,
    resolve_references,
    resolve_tool_name,
)

# Load .env from NIMBUS_HOME first, then current dir
NIMBUS_HOME = Path(os.environ.get("NIMBUS_HOME", Path.home() / ".nimbus"))
env_path = NIMBUS_HOME / ".env"
if not env_path.exists():
    env_path = Path(__file__).parent.parent.parent / ".env"

if env_path.exists():
    load_dotenv(env_path, override=True)

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Brand the OAuth callback pages with Nimbus identity
import fastmcp.utilities.ui as _ui
import fastmcp.client.oauth_callback as _oauth_cb

_NIMBUS_LOGO_SVG = """<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
  <style>
    .bg { fill: white; }
    .icon { fill: black; }
    @media (prefers-color-scheme: dark) {
      .bg { fill: black; }
      .icon { fill: white; }
    }
  </style>
  <rect width="32" height="32" rx="6" ry="6" class="bg"/>
  <g transform="translate(8, 8)" class="icon">
    <path d="M2.5 0.5V0H3.5V0.5C3.5 1.60457 4.39543 2.5 5.5 2.5H6V3V3.5H5.5C4.39543 3.5 3.5 4.39543 3.5 5.5V6H3H2.5V5.5C2.5 4.39543 1.60457 3.5 0.5 3.5H0V3V2.5H0.5C1.60457 2.5 2.5 1.60457 2.5 0.5Z"/>
    <path d="M14.5 4.5V5H13.5V4.5C13.5 3.94772 13.0523 3.5 12.5 3.5H12V3V2.5H12.5C13.0523 2.5 13.5 2.05228 13.5 1.5V1H14H14.5V1.5C14.5 2.05228 14.9477 2.5 15.5 2.5H16V3V3.5H15.5C14.9477 3.5 14.5 3.94772 14.5 4.5Z"/>
    <path d="M8.40706 4.92939L8.5 4H9.5L9.59294 4.92939C9.82973 7.29734 11.7027 9.17027 14.0706 9.40706L15 9.5V10.5L14.0706 10.5929C11.7027 10.8297 9.82973 12.7027 9.59294 15.0706L9.5 16H8.5L8.40706 15.0706C8.17027 12.7027 6.29734 10.8297 3.92939 10.5929L3 10.5V9.5L3.92939 9.40706C6.29734 9.17027 8.17027 7.29734 8.40706 4.92939Z"/>
  </g>
</svg>"""
_ui.FASTMCP_LOGO_URL = ""  # disable remote logo fetch

def _nimbus_logo(icon_url: str | None = None, alt_text: str = "Nimbus Gateway") -> str:
    svg = _NIMBUS_LOGO_SVG.replace('width="32" height="32"', 'width="96" height="96"', 1)
    return f'<div class="logo" style="width:96px;height:96px;margin:0 auto 16px">{svg}</div>'

_ui.create_logo = _nimbus_logo

def _nimbus_callback_html(message: str, is_success: bool = True, title: str = "Nimbus Gateway", server_url: str | None = None) -> str:
    status_title = "Authentication successful" if is_success else "Authentication failed"
    detail_info = ""
    if is_success and server_url:
        detail_info = _ui.create_info_box(f"Connected to: {server_url}", centered=True, monospace=True)
    elif not is_success:
        detail_info = _ui.create_info_box(message, is_error=True, centered=True, monospace=True)
    content = f'''
        <div class="container">
            {_nimbus_logo()}
            {_ui.create_status_message(status_title, is_success=is_success)}
            {detail_info}
            <div class="close-instruction">You can safely close this tab now.</div>
        </div>
    '''
    return _ui.create_page(content=content, title=title,
        additional_styles=_ui.STATUS_MESSAGE_STYLES + _ui.INFO_BOX_STYLES + _ui.HELPER_TEXT_STYLES)

_oauth_cb.create_callback_html = _nimbus_callback_html

# Global state (populated during lifespan)
tool_index: Dict[str, Dict[str, str]] = {}
qdrant_client: Optional[QdrantClient] = None
server_manager: Optional[LazyServerManager] = None  # static mcp.json fallback
indexer: Optional[ToolIndexer] = None
account_pool: Optional[AccountScopedManagerPool] = None  # per-user manager pool


def init_qdrant(settings: GatewaySettings) -> Optional[QdrantClient]:
    """Initialize Qdrant client."""
    try:
        if settings.is_qdrant_local:
            client = QdrantClient(path=settings.qdrant_local_path)
            logger.info(f"Connected to local Qdrant at {settings.qdrant_local_path}")
        else:
            client = QdrantClient(
                url=settings.qdrant_url,
                api_key=os.getenv("QDRANT_API_KEY"),
                timeout=30,
            )
            logger.info(f"Connected to Qdrant at {settings.qdrant_url}")
        return client
    except Exception as e:
        logger.error(f"Failed to connect to Qdrant: {e}")
        return None


def _detect_oauth_servers(mcp_config: Dict[str, Any]) -> List[str]:
    """Return server names that require OAuth (should be lazily connected)."""
    oauth_servers = []
    for name, cfg in mcp_config.get("mcpServers", {}).items():
        if cfg.get("auth") == "oauth":
            oauth_servers.append(name)
    return oauth_servers


async def index_tools_from_manager(
    manager: LazyServerManager,
    indexer_obj: ToolIndexer,
    skip_servers: Optional[List[str]] = None,
) -> Dict[str, Dict[str, str]]:
    """Index tools from non-OAuth servers into Qdrant and memory.

    OAuth servers are skipped on startup — their tools are loaded
    lazily when first called.
    """
    all_tools, idx = await manager.list_all_tools(skip_servers=skip_servers)

    if indexer_obj and all_tools:
        count = await indexer_obj.index_all(all_tools)
        logger.info(f"Indexed {count} tools to Qdrant")

    logger.info(f"Loaded {len(idx)} tools (skipped {len(skip_servers or [])} OAuth servers)")
    return idx


@asynccontextmanager
async def lifespan(mcp: FastMCP):
    """Initialize lazy server manager, Qdrant, indexer, and account pool on startup.

    OAuth servers are NOT connected at startup — they connect lazily
    on first tool call. Non-OAuth servers connect eagerly for indexing.
    Authenticated users get per-user server pools fetched from Nimbus.
    """
    global tool_index, qdrant_client, server_manager, indexer, account_pool

    logger.info("Initializing Nimbus Gateway...")
    settings = GatewaySettings()

    # Init Qdrant
    qdrant_client = init_qdrant(settings)

    # Init static lazy server manager from mcp.json (fallback)
    # Try NIMBUS_HOME first, then fallback to relative
    config_path = NIMBUS_HOME / "mcp.json"
    if not config_path.exists():
        config_path = NIMBUS_HOME / ".mcp.json"
    
    if not config_path.exists():
        config_path = Path(__file__).parent.parent.parent / "mcp.json"
        if not config_path.exists():
            config_path = Path(__file__).parent.parent.parent / ".mcp.json"

    oauth_servers: List[str] = []
    if config_path.exists():
        mcp_config = load_mcp_config(config_path)
        server_configs = mcp_config.get("mcpServers", {})
        server_manager = LazyServerManager(server_configs)
        oauth_servers = _detect_oauth_servers(mcp_config)
        logger.info(
            f"Configured {len(server_configs)} servers from mcp.json "
            f"({len(oauth_servers)} OAuth, deferred)"
        )
    else:
        logger.warning("No mcp.json found — static server manager not initialized")

    # Init indexer
    indexer = ToolIndexer(
        qdrant_client=qdrant_client,
        api_key=settings.openrouter_api_key,
        model=settings.embedding_model,
    )
    if server_manager:
        server_manager._indexer = indexer

    # Init per-user account pool (populated lazily on first authenticated request)
    nimbus_url = os.environ.get("NIMBUS_URL", "http://localhost:3000")
    resolver = NimbusIdentityResolver(nimbus_url=nimbus_url)
    account_pool = AccountScopedManagerPool(resolver=resolver, indexer=indexer)
    logger.info(f"Account pool initialized (Nimbus: {nimbus_url})")

    # Index tools from static manager (skip OAuth — they connect lazily)
    if server_manager:
        tool_index = await index_tools_from_manager(
            server_manager, indexer, skip_servers=oauth_servers
        )

    logger.info(
        f"Gateway started with {len(tool_index)} tools "
        f"({len(oauth_servers)} servers deferred)"
    )
    yield

    logger.info("Shutting down Nimbus Gateway...")


# ============ IDENTITY RESOLUTION ============


def _get_auth_header(ctx: Optional[Context]) -> Optional[str]:
    """Extract Authorization header from MCP request context (streamable-http)."""
    try:
        if ctx and ctx.request_context:
            req = ctx.request_context.request
            if hasattr(req, "headers"):
                return req.headers.get("authorization") or req.headers.get("Authorization")
    except Exception:
        pass
    return None


def _get_local_active_token() -> Optional[str]:
    """Read the active account's session token from the local nimbus_auth-mcp store.

    This is the fallback for local single-user dev: the user runs
    nimbus_auth-mcp_login once, which stores the token in accounts.json.
    Subsequent gateway calls automatically use that token.
    """
    try:
        store_path = Path.home() / ".nimbus-gateway" / "accounts.json"
        if not store_path.exists():
            return None
        import json as _json
        data = _json.loads(store_path.read_text())
        active = data.get("active")
        if not active:
            return None
        account = data.get("accounts", {}).get(active)
        return account.get("session_token") if account else None
    except Exception:
        return None


async def _resolve_manager(ctx: Optional[Context] = None) -> Optional[LazyServerManager]:
    """Return the right LazyServerManager for this request.

    Resolution order (industry standard — identity from verified token, never from args):
    1. Authorization: Bearer <token> from the incoming HTTP request header
    2. Active account token from ~/.nimbus-gateway/accounts.json (local dev fallback)
    3. Static mcp.json manager (unauthenticated fallback)

    Returns:
        A LazyServerManager scoped to the authenticated user, or the static fallback.
    """
    # 1. Bearer token from request header (production multi-user path)
    token = _get_auth_header(ctx)

    # 2. Active local account token (single-user dev fallback)
    if not token:
        token = _get_local_active_token()
        if token:
            logger.debug("Using active local account token from nimbus_auth-mcp store")

    # 3. If we have a token, get the user-scoped manager from the pool
    if token and account_pool:
        try:
            return await account_pool.get_or_create(token)
        except Exception as exc:
            logger.warning(
                f"Failed to resolve account-scoped manager ({exc}); "
                "falling back to static mcp.json manager"
            )

    # 4. Static fallback
    return server_manager


# Create gateway
gateway = FastMCP("Nimbus Gateway", lifespan=lifespan)


# ============ TOOLS ============


@gateway.tool(timeout=600)
async def find_tools(ctx: Context, server_name: str, query: str, limit: int = 10) -> Dict[str, Any]:
    """Find tools on a specific server using semantic search.

    Args:
        server_name: The server to search (e.g. 'whatsapp-mcp'). Use list_servers() to see all available servers.
        query: Natural language search query describing the tool you need.
        limit: Max results to return.
    """
    mgr = await _resolve_manager(ctx)
    return await _find_tools(
        server_name=server_name,
        query=query,
        limit=limit,
        indexer=indexer,
        server_manager=mgr,
    )


@gateway.tool(timeout=600)
async def execute_tool(ctx: Context, tool_name: str, arguments: Dict[str, Any], original_goal: str) -> Dict[str, Any]:
    """Execute a tool via lazy per-server connections.

    Args:
        tool_name: The name of the tool to execute.
        arguments: The arguments to pass to the tool.
        original_goal: The very first overarching goal the user asked you to achieve. REQUIRED so you never forget the big picture and don't stop prematurely.
    """
    mgr = await _resolve_manager(ctx)
    return await _execute_tool(
        tool_name=tool_name,
        arguments=arguments,
        original_goal=original_goal,
        server_manager=mgr,
        tool_index=tool_index,
        indexer=indexer,
    )


@gateway.tool(timeout=600)
async def chain_tools(ctx: Context, steps: List[Dict[str, Any]], original_goal: str) -> Dict[str, Any]:
    """Execute a sequence of tools via lazy per-server connections.

    Args:
        steps: List of step dicts with tool_name and arguments.
        original_goal: The very first overarching goal the user asked you to achieve. REQUIRED so you never forget the big picture and don't stop prematurely.
    """
    mgr = await _resolve_manager(ctx)
    return await _chain_tools(
        steps=steps,
        original_goal=original_goal,
        server_manager=mgr,
        tool_index=tool_index,
        indexer=indexer,
    )


@gateway.tool
async def list_servers(ctx: Context, intent: str = "*") -> Dict[str, Any]:
    """List all configured MCP backend servers with their connection status and tool count.

    Args:
        intent: Optional search query to filter servers by name or tool semantic intent. Default '*' returns all.
    """
    mgr = await _resolve_manager(ctx)
    return await _list_servers(
        intent=intent,
        server_manager=mgr,
        indexer=indexer,
    )

# ============ HEALTH CHECK ============


@gateway.custom_route("/health", methods=["GET"])
async def health_check(request: Request):
    """Fast liveness check."""
    mgr = server_manager
    status = "healthy" if (mgr is not None and mgr.ready and tool_index) else "degraded"
    return JSONResponse({
        "status": status,
        "tools_indexed": len(tool_index),
        "servers_configured": mgr.server_count if mgr else 0,
        "servers_connected": mgr.connected_count if mgr else 0,
    })


# ============ ENTRY POINT ============


if __name__ == "__main__":
    settings = GatewaySettings()
    logger.info(f"Starting Nimbus Gateway on http://0.0.0.0:{settings.port}")
    gateway.run(
        transport="streamable-http",
        host="0.0.0.0",
        port=settings.port,
    )
