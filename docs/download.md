# Download Nimbus

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  The unified MCP gateway for production AI agents. One command installs the CLI, the gateway, and every bundled MCP server — SHA256-verified, no sign-up, runs locally.
</p>

<div class="prereq-callout" markdown="1">

**Prerequisite:** Nimbus needs <a href="https://www.docker.com/products/docker-desktop/" target="_blank">Docker Desktop</a> (or <a href="https://orbstack.dev/" target="_blank">OrbStack</a> on Mac) installed and **running** before you install. Installation is free and takes a couple of minutes.

**Quick check — run this first:**

```bash
docker ps
```

If you see a `CONTAINER ID` table (or a "no containers" row), Docker is up and you're good to go. If you see `Cannot connect to the Docker daemon`, start Docker Desktop (macOS / Windows) or `sudo systemctl start docker` (Linux) and try again.

</div>

## Install for your platform

=== "macOS"

    Apple Silicon & Intel. Requires macOS 12 Monterey or later.

    **Install (latest):**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    The installer auto-detects Apple Silicon vs Intel and verifies against the published SHA256SUMS.

    Direct downloads:

    - [Apple Silicon (M1/M2/M3/M4) →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-arm64.tar.gz)
    - [Intel Macs →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-amd64.tar.gz)

    **System requirements:**

    - **OS:** macOS 12 Monterey or later (Apple Silicon or Intel)
    - **Docker:** Docker Desktop 4.x+ or [OrbStack](https://orbstack.dev/) — daemon must be running
    - **Python:** 3.12+ (auto-installed via [`uv`](https://astral.sh/uv) if missing)
    - **Disk:** ~30 MB for the CLI, ~2 GB once Docker images are pulled
    - **RAM:** 4 GB minimum, 8 GB recommended

    **Pin a specific version:**

    Set `NIMBUS_VERSION` on the right-hand side of the pipe (so `curl` doesn't see it and the variable reaches the installed script):

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Linux"

    x86_64 & aarch64. Tested on Ubuntu 22.04+, Debian 12+, Fedora 39+, and Arch.

    **Install (latest):**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    Direct downloads:

    - [x86_64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-amd64.tar.gz)
    - [aarch64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-arm64.tar.gz)

    **System requirements:**

    - **OS:** glibc 2.31+ (Ubuntu 22.04, Debian 12, Fedora 39, Arch)
    - **Docker:** Docker Desktop 4.x+, [OrbStack](https://orbstack.dev/), or a headless Docker Engine — daemon must be running
    - **Python:** 3.12+ (auto-installed via [`uv`](https://astral.sh/uv) if missing)
    - **Disk:** ~30 MB for the CLI, ~2 GB once Docker images are pulled
    - **RAM:** 4 GB minimum, 8 GB recommended

    **Pin a specific version:**

    Set `NIMBUS_VERSION` on the right-hand side of the pipe (so `curl` doesn't see it and the variable reaches the installed script):

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Windows"

    PowerShell & WSL2. Administrator is not required. The installer handles PATH setup and registers Nimbus in your user profile.

    **Install (latest):**

    ```powershell
    irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

    Direct downloads:

    - [One-click: install.cmd launcher →](https://nimbus.yoodule.com/install.cmd)
    - [Windows (x64) →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-windows-amd64.tar.gz)

    **System requirements:**

    - **OS:** Windows 10 build 19041+ or Windows 11 with WSL2 enabled
    - **Docker:** Docker Desktop 4.x+ (with WSL2 backend) — daemon must be running
    - **Python:** 3.12+ (auto-installed via [`uv`](https://astral.sh/uv) if missing)
    - **Disk:** ~30 MB for the CLI, ~2 GB once Docker images are pulled
    - **RAM:** 4 GB minimum, 8 GB recommended (Qdrant + Docker)

    **Pin a specific version:**

    Set `NIMBUS_VERSION` in your shell before running the installer (so the variable reaches the installed script):

    ```powershell
    $env:NIMBUS_VERSION = "v1.0.3"; irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

---

Browse all published versions on the [releases page](https://github.com/Yoodule/nimbus/releases).

---

## Verify Before You Install

Every release ships with a `SHA256SUMS` file. The installer checksums automatically. To inspect the checksums yourself, grab the file from the [releases page](https://github.com/Yoodule/nimbus/releases) and run:

```bash
sha256sum -c --strict SHA256SUMS
```

Every release is SLSA-attested by GitHub Actions. You can view the attestation on the [releases page](https://github.com/Yoodule/nimbus/releases).

---

## Upgrade

The CLI upgrades itself in place. Your `mcp.json`, `.env`, OAuth tokens, and the Qdrant index are preserved:

```bash
nimbus upgrade
```

To upgrade to a specific version:

```bash
nimbus upgrade --version v1.0.3
```

---

## Uninstall

Removes the CLI, the gateway, the local Docker stack, and the install directory in one step:

```bash
nimbus uninstall
```

If you want to keep your config (mcp.json, .env, tokens) for a future reinstall, pass `--keep-config`:

```bash
nimbus uninstall --keep-config
```

---

## What Gets Installed

The installer writes everything under `~/.nimbus/` (or `$NIMBUS_HOME` if you set it):

```
~/.nimbus/
├── nimbus                # CLI shim
├── nimbus-gateway-*      # Compiled gateway binary
├── mcp.json              # Server registry
├── servers/              # Bundled MCP servers
├── .env                  # Local config (OPENROUTER_API_KEY, QDRANT_URL, …)
└── logs/                 # Runtime logs
```

It also adds `export NIMBUS_HOME` and `PATH` to your shell config (`~/.zshrc`, `~/.bashrc`, or `$PROFILE` on Windows) so `nimbus` is on your PATH in new shells.

---

## FAQ

### The installer says "arm64 not found" on my Apple Silicon Mac.

That message is from an outdated installer. Run `nimbus upgrade` to pull the latest, or fetch a fresh copy of the script directly:

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

The current installer follows GitHub's CDN redirect, detects your architecture, and fails fast with an actionable error if the asset is genuinely missing.

### Can I install on a machine without Docker?

Yes. The CLI and gateway run natively. The bundled MCP stack (Playwright browser, Postgres agent DB, Qdrant) uses Docker, but you can skip it with `nimbus start --no-deps` and point Nimbus at remote MCP servers via `mcp.json` instead.

### How big is the download?

The CLI tarball is ~30 MB compressed. The Docker images it pulls on first start add another ~2 GB (Qdrant, Playwright, Postgres). If you're bandwidth-constrained, the `--no-deps` start mode skips the Docker pull.

### Where do my OAuth tokens live?

In-memory by default — re-approve on restart. Set `NIMBUS_PERSIST_TOKENS=1` in `~/.nimbus/.env` to encrypt them at rest under `~/.nimbus/tokens/`.

### Does this work on Apple Silicon under Rosetta?

Yes — set `NIMBUS_HOST_ARCH=amd64` before the install command to pull the Intel build. We don't ship a universal binary because the gatekeeper tooling adds 60+ MB for a small subset of users; Rosetta handles it transparently.

### How do I run multiple Nimbus instances on the same host?

Nimbus binds to fixed host ports (`3000`, `8088`, `6333`, `5433`, `6080`, `8006`, `8007`, `8081`), so the default install is single-instance. To run a second, clone the repo, remap ports in `compose.yaml`, set a unique `NIMBUS_HOME`, and set `COMPOSE_PROJECT_NAME` so the two stacks don't collide. Full details in the [homepage FAQ → Multiple Instances](../#how-many-instances-of-nimbus-can-you-run-at-a-time).

### The install hangs or curl fails — what now?

Most common cause: a corporate proxy intercepting TLS. Set `HTTPS_PROXY` and try again. If the issue is the CDN specifically, the install script accepts `NIMBUS_VERSION` to pin a known-good release, and you can also download the tarball directly from the [releases page](https://github.com/Yoodule/nimbus/releases) and untar it into `~/.nimbus/` by hand — the binary is self-contained.

---

<div style="text-align: center; margin: 48px 0 24px 0; padding: 32px; background: #0a0a0a; border: 1px solid #262626; border-radius: 12px;">
  <p style="color: #a3a3a3; font-size: 1.05em; margin: 0 0 16px 0;">
    Want a guided setup? Schedule a 1-on-1 onboarding session and we'll walk through your workspace.
  </p>
  <a href="https://calendly.com/sundayj/30min" target="_blank" style="display: inline-flex; align-items: center; gap: 8px; background: #ffffff; color: #000000; text-decoration: none; font-weight: 600; padding: 12px 24px; border-radius: 8px; font-size: 1em;">
    Schedule Onboarding Session →
  </a>
</div>
