#!/usr/bin/env python3
import argparse
import json
import os
import socket
import subprocess
import sys
import time
import tarfile
import zipfile
import urllib.request
import platform
import shutil
from pathlib import Path
from typing import List, Optional

# --- Configuration ---
NIMBUS_HOME = Path(os.environ.get("NIMBUS_HOME", Path.home() / ".nimbus"))
ENV_FILE = NIMBUS_HOME / ".env"
MCP_CONFIG = NIMBUS_HOME / "mcp.json"
GATEWAY_PORT = 8088
DASHBOARD_PORT = 3000
WHATSAPP_PORT = 8007
POSTGRES_PORT = 5433 

def get_lan_ip():
    """Get the local network IP address."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

def get_nip_io_url(port):
    """Generate a nip.io URL for the current LAN IP and port."""
    ip = get_lan_ip()
    dashed_ip = ip.replace('.', '-')
    return f"http://{dashed_ip}.nip.io:{port}"

class PostgresManager:
    def __init__(self, nimbus_home: Path):
        self.nimbus_home = nimbus_home
        self.bin_dir = nimbus_home / "bin" / "postgres"
        self.data_dir = nimbus_home / "data" / "db"
        self.port = POSTGRES_PORT
        self.user = "nimbus"
        self.password = "nimbus"
        self.db_name = "postgres"
        self.process = None

    def get_binary_url(self):
        system = platform.system().lower()
        machine = platform.machine().lower()
        arch = "arm64v8" if "arm" in machine else "amd64"
        os_name = "darwin" if "darwin" in system else "linux" if "linux" in system else "windows"
        version = "16.2.0"
        return f"https://repo1.maven.org/maven2/io/zonky/test/postgres/embedded-postgres-binaries-{os_name}-{arch}/{version}/embedded-postgres-binaries-{os_name}-{arch}-{version}.jar"

    def ensure_binaries(self):
        if (self.bin_dir / "bin" / "postgres").exists() or (self.bin_dir / "bin" / "postgres.exe").exists():
            return
        print(f"Downloading PostgreSQL binaries for {platform.system()}...")
        self.bin_dir.mkdir(parents=True, exist_ok=True)
        url = self.get_binary_url()
        archive_path = self.nimbus_home / "postgres.jar"
        urllib.request.urlretrieve(url, archive_path)
        with zipfile.ZipFile(archive_path, 'r') as zip_ref:
            txz_name = [f for f in zip_ref.namelist() if f.endswith('.txz')][0]
            with zip_ref.open(txz_name) as txz_file:
                with open(self.nimbus_home / "temp.txz", "wb") as f:
                    f.write(txz_file.read())
            with tarfile.open(self.nimbus_home / "temp.txz", "r:xz") as tar:
                tar.extractall(path=self.bin_dir)
            (self.nimbus_home / "temp.txz").unlink()
        archive_path.unlink()

    def init_db(self):
        if (self.data_dir / "PG_VERSION").exists():
            return
        print("Initializing private database...")
        self.data_dir.mkdir(parents=True, exist_ok=True)
        initdb_path = self.bin_dir / "bin" / "initdb"
        subprocess.run([str(initdb_path), "-D", str(self.data_dir), "-U", self.user, "--auth=trust"], check=True, capture_output=True)

    def start(self):
        self.ensure_binaries()
        self.init_db()
        print(f"Starting hidden PostgreSQL on port {self.port}...")
        postgres_path = self.bin_dir / "bin" / "postgres"
        self.process = subprocess.Popen([str(postgres_path), "-D", str(self.data_dir), "-p", str(self.port)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(2)

    def stop(self):
        if self.process:
            print("Stopping PostgreSQL...")
            self.process.terminate()
            self.process.wait()

    def get_url(self):
        return f"postgresql://{self.user}:{self.password}@localhost:{self.port}/{self.db_name}"

class Service:
    def __init__(self, name: str, command: List[str], cwd: Path, env: Optional[dict] = None):
        self.name = name
        self.command = command
        self.cwd = cwd
        self.env = env or os.environ.copy()
        self.process = None

    def start(self):
        print(f"Starting {self.name}...")
        self.process = subprocess.Popen(
            self.command,
            cwd=self.cwd,
            env=self.env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )

    def is_running(self):
        return self.process is not None and self.process.poll() is None

    def stop(self):
        if self.process:
            print(f"Stopping {self.name}...")
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()

def start_all(args):
    # Detect if we are running as a compiled binary or source
    if getattr(sys, 'frozen', False):
        # We are running as a binary
        project_root = Path(sys.executable).parent
    else:
        # We are running from source
        project_root = Path(__file__).parent.absolute()
    
    # In production, use NIMBUS_HOME as the base for many things
    NIMBUS_HOME.mkdir(parents=True, exist_ok=True)
    
    # 0. PostgreSQL (Bundled)
    pg = PostgresManager(NIMBUS_HOME)
    pg.start()

    services = []

    # 1. Gateway
    gateway_env = os.environ.copy()
    gateway_env["QDRANT_URL"] = f"local://{NIMBUS_HOME}/qdrant"
    gateway_env["GATEWAY_PORT"] = str(GATEWAY_PORT)
    gateway_env["NIMBUS_HOME"] = str(NIMBUS_HOME)
    if args.openrouter_key:
        gateway_env["OPENROUTER_API_KEY"] = args.openrouter_key

    # Binary naming convention: nimbus-gateway-[os]-[arch]
    system = platform.system().lower()
    machine = platform.machine().lower()
    if machine == "x86_64": machine = "amd64"
    
    binary_name = f"nimbus-gateway-{system}-{machine}"
    gateway_binary = project_root / binary_name
    
    # Fallback to simple name or source
    if not gateway_binary.exists():
        gateway_binary = project_root / "nimbus-gateway"
        if not gateway_binary.exists():
            gateway_binary = project_root / "dist" / "nimbus-gateway"

    if gateway_binary.exists():
        gateway_cmd = [str(gateway_binary)]
    else:
        gateway_cmd = ["uv", "run", "python", "-m", "nimbus_gateway.server"]

    services.append(Service("Gateway", gateway_cmd, project_root, gateway_env))

    # 2. Dashboard
    # In production, the dashboard is in NIMBUS_HOME/dashboard (from the installer)
    # or project_root/dashboard
    dashboard_root = NIMBUS_HOME / "dashboard"
    if not dashboard_root.exists():
        dashboard_root = project_root / "dashboard"
    
    if dashboard_root.exists():
        dashboard_env = os.environ.copy()
        dashboard_env["PORT"] = str(DASHBOARD_PORT)
        dashboard_env["POSTGRES_URL"] = pg.get_url()
        dashboard_env["BETTER_AUTH_URL"] = get_nip_io_url(DASHBOARD_PORT)
        dashboard_env["TRUSTED_ORIGINS"] = f"http://localhost:3000,{get_nip_io_url(DASHBOARD_PORT)}"
        dashboard_env["NIMBUS_GATEWAY_URL"] = f"{get_nip_io_url(GATEWAY_PORT)}/mcp"
        
        # Production mode: node server.js
        if (dashboard_root / "server.js").exists():
            dashboard_cmd = ["node", "server.js"]
        elif (dashboard_root / ".next" / "standalone" / "server.js").exists():
            dashboard_root = dashboard_root / ".next" / "standalone"
            dashboard_cmd = ["node", "server.js"]
        else:
            # Fallback to dev
            if shutil.which("pnpm"):
                dashboard_cmd = ["pnpm", "dev"]
            else:
                dashboard_cmd = ["npm", "run", "dev"]
        
        services.append(Service("Dashboard", dashboard_cmd, dashboard_root, dashboard_env))

    # Start them
    try:
        for s in services:
            s.start()
        
        print("\n" + "="*40)
        print("Nimbus is starting up!")
        print(f"Dashboard: {get_nip_io_url(DASHBOARD_PORT)}")
        print(f"Gateway:   {get_nip_io_url(GATEWAY_PORT)}/mcp")
        print(f"Database:  Running on port {POSTGRES_PORT}")
        print("="*40 + "\n")
        print("Press Ctrl+C to stop all services.")

        while True:
            for s in services:
                if not s.is_running():
                    print(f"Error: {s.name} stopped unexpectedly.")
                    # Show some tail of the log if it failed
                    if s.process:
                        out, _ = s.process.communicate()
                        if out: print(f"Log: {out}")
            time.sleep(2)

    except KeyboardInterrupt:
        print("\nShutting down...")
    finally:
        for s in services:
            s.stop()
        pg.stop()

def config_list(args):
    if not ENV_FILE.exists():
        print("No configuration found.")
        return
    print(f"--- Configuration ({ENV_FILE}) ---")
    with open(ENV_FILE, "r") as f:
        print(f.read())

def config_set(args):
    NIMBUS_HOME.mkdir(parents=True, exist_ok=True)
    lines = []
    if ENV_FILE.exists():
        with open(ENV_FILE, "r") as f:
            lines = f.readlines()
    
    key_found = False
    new_line = f"{args.key.upper()}={args.value}\n"
    for i, line in enumerate(lines):
        if line.startswith(f"{args.key.upper()}="):
            lines[i] = new_line
            key_found = True
            break
    
    if not key_found:
        lines.append(new_line)
    
    with open(ENV_FILE, "w") as f:
        f.writelines(lines)
    print(f"Set {args.key.upper()}={args.value}")

def config_get(args):
    if not ENV_FILE.exists():
        print("No configuration found.")
        return
    with open(ENV_FILE, "r") as f:
        for line in f:
            if line.startswith(f"{args.key.upper()}="):
                print(line.split("=", 1)[1].strip())
                return
    print(f"Key '{args.key.upper()}' not found.")

def mcp_list(args):
    if not MCP_CONFIG.exists():
        print("No MCP configuration found.")
        return
    with open(MCP_CONFIG, "r") as f:
        config = json.load(f)
        servers = config.get("mcpServers", {})
        print(f"--- MCP Servers ({len(servers)}) ---")
        for name, cfg in servers.items():
            if "command" in cfg:
                print(f"- {name}: {cfg.get('command')} {' '.join(cfg.get('args', []))}")
            elif "url" in cfg:
                print(f"- {name}: [HTTP] {cfg.get('url')}")
            else:
                print(f"- {name}: (Unknown configuration)")

def mcp_add(args):
    NIMBUS_HOME.mkdir(parents=True, exist_ok=True)
    config = {"mcpServers": {}}
    if MCP_CONFIG.exists():
        with open(MCP_CONFIG, "r") as f:
            config = json.load(f)
    
    config.setdefault("mcpServers", {})[args.name] = {
        "command": args.exec,
        "args": args.args or []
    }
    
    with open(MCP_CONFIG, "w") as f:
        json.dump(config, f, indent=2)
    print(f"Added MCP server: {args.name}")

def mcp_remove(args):
    if not MCP_CONFIG.exists():
        print("No MCP configuration found.")
        return
    with open(MCP_CONFIG, "r") as f:
        config = json.load(f)
    
    if args.name in config.get("mcpServers", {}):
        del config["mcpServers"][args.name]
        with open(MCP_CONFIG, "w") as f:
            json.dump(config, f, indent=2)
        print(f"Removed MCP server: {args.name}")
    else:
        print(f"Server '{args.name}' not found.")

def main():
    parser = argparse.ArgumentParser(description="Nimbus CLI - One command to rule them all")
    subparsers = parser.add_subparsers(dest="command")
    
    # Start
    start_parser = subparsers.add_parser("start", help="Start all Nimbus services")
    start_parser.add_argument("--openrouter-key", help="OpenRouter API key for embeddings")
    
    # Config
    config_parser = subparsers.add_parser("config", help="Manage Nimbus configuration")
    config_sub = config_parser.add_subparsers(dest="subcommand")
    
    config_list_p = config_sub.add_parser("list", help="List all config variables")
    
    config_set_p = config_sub.add_parser("set", help="Set a config variable")
    config_set_p.add_argument("key", help="Variable name (e.g. OPENROUTER_API_KEY)")
    config_set_p.add_argument("value", help="Variable value")
    
    config_get_p = config_sub.add_parser("get", help="Get a config variable")
    config_get_p.add_argument("key", help="Variable name")
    
    # MCP
    mcp_parser = subparsers.add_parser("mcp", help="Manage MCP servers")
    mcp_sub = mcp_parser.add_subparsers(dest="subcommand")
    
    mcp_list_p = mcp_sub.add_parser("list", help="List configured MCP servers")
    
    mcp_add_p = mcp_sub.add_parser("add", help="Add a new MCP server")
    mcp_add_p.add_argument("name", help="Server name")
    mcp_add_p.add_argument("exec", help="Command or executable path")
    mcp_add_p.add_argument("args", nargs="*", help="Arguments for the command")
    
    mcp_remove_p = mcp_sub.add_parser("remove", help="Remove an MCP server")
    mcp_remove_p.add_argument("name", help="Server name")

    args = parser.parse_args()
    if args.command == "start":
        start_all(args)
    elif args.command == "config":
        if args.subcommand == "list": config_list(args)
        elif args.subcommand == "set": config_set(args)
        elif args.subcommand == "get": config_get(args)
        else: config_parser.print_help()
    elif args.command == "mcp":
        if args.subcommand == "list": mcp_list(args)
        elif args.subcommand == "add": mcp_add(args)
        elif args.subcommand == "remove": mcp_remove(args)
        else: mcp_parser.print_help()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
