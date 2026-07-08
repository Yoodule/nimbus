# Download Nimbus

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  The unified MCP gateway for production AI agents. One command installs the CLI, the gateway, and every bundled MCP server — SHA256-verified, no sign-up, runs locally.
</p>

<div class="download-tabs" markdown>

=== "macOS"

    <div class="install-cmd" markdown>
    ```
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```
    </div>

    <p style="color: #737373; font-size: 0.9em; margin: 12px 0 24px 0;">
      Paste this in Terminal. Auto-detects Apple Silicon vs Intel, downloads the right binary, and verifies it against the published SHA256SUMS.
    </p>

    <p style="margin: 0 0 12px 0;"><strong>Verify it worked:</strong></p>

    <div class="install-cmd" markdown>
    ```
    nimbus --version
    ```
    </div>

    <p style="margin: 24px 0 8px 0;"><strong>Or download directly:</strong></p>

    - [Nimbus for Apple Silicon (M1/M2/M3/M4) — `nimbus-darwin-arm64.tar.gz`](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-arm64.tar.gz)
    - [Nimbus for Intel Macs — `nimbus-darwin-amd64.tar.gz`](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-amd64.tar.gz)

    <p style="color: #737373; font-size: 0.85em; margin: 16px 0 0 0;">
      Requires macOS 12 Monterey or later.
    </p>

=== "Linux"

    <div class="install-cmd" markdown>
    ```
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```
    </div>

    <p style="color: #737373; font-size: 0.9em; margin: 12px 0 24px 0;">
      Paste this in your shell. Tested on Ubuntu 22.04+, Debian 12+, Fedora 39+, and Arch. Auto-detects your architecture and pulls the right binary.
    </p>

    <p style="margin: 0 0 12px 0;"><strong>Verify it worked:</strong></p>

    <div class="install-cmd" markdown>
    ```
    nimbus --version
    ```
    </div>

    <p style="margin: 24px 0 8px 0;"><strong>Or download directly:</strong></p>

    - [Nimbus for x86_64 — `nimbus-linux-amd64.tar.gz`](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-amd64.tar.gz)

    <p style="color: #737373; font-size: 0.85em; margin: 16px 0 0 0;">
      Requires Python 3.12+ (auto-installed via <a href="https://astral.sh/uv" target="_blank"><code>uv</code></a> if missing).
    </p>

=== "Windows"

    <div class="install-cmd" markdown>
    ```powershell
    irm https://nimbus.yoodule.com/install.ps1 | iex
    ```
    </div>

    <p style="color: #737373; font-size: 0.9em; margin: 12px 0 24px 0;">
      Paste this in PowerShell. Administrator is not required. The installer handles PATH setup and registers Nimbus in your user profile.
    </p>

    <p style="margin: 0 0 12px 0;"><strong>Verify it worked:</strong></p>

    <div class="install-cmd" markdown>
    ```powershell
    nimbus --version
    ```
    </div>

    <p style="margin: 24px 0 8px 0;"><strong>Or use the one-click launcher:</strong></p>

    - [`install.cmd` — opens PowerShell and runs the installer](https://nimbus.yoodule.com/install.cmd)
    - [Nimbus for Windows (x64) — `nimbus-windows-amd64.tar.gz`](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-windows-amd64.tar.gz)

    <p style="color: #737373; font-size: 0.85em; margin: 16px 0 0 0;">
      Requires Windows 10 build 19041+ or later.
    </p>

</div>

---

## System Requirements

| Component | Requirement |
|-----------|-------------|
| **Python** | 3.12+ (auto-installed via [`uv`](https://astral.sh/uv) if missing) |
| **Docker** | Docker Desktop 4.x+, OrbStack, or a headless Docker Engine for the bundled MCP stack |
| **macOS** | 12 Monterey or later (Apple Silicon or Intel) |
| **Linux** | glibc 2.31+ (Ubuntu 22.04, Debian 12, Fedora 39, Arch) |
| **Windows** | Windows 10 build 19041+ with WSL2 |
| **Disk** | ~30 MB for the CLI, ~2 GB once Docker images are pulled |
| **RAM** | 4 GB minimum, 8 GB recommended (Qdrant + Docker) |

---

## Pin a Version

The one-liner above always installs the latest stable release. To pin a build, set `NIMBUS_VERSION` on the **right-hand side** of the pipe (so `curl` doesn't see it and the variable reaches the installed script):

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
```

Browse all published versions on the [releases page](https://github.com/Yoodule/nimbus/releases).

---

## Verify Before You Install

Every release ships with a `SHA256SUMS` file. The installer checksums automatically, but you can verify manually if you prefer:

```bash
curl -fsSL https://github.com/Yoodule/nimbus/releases/latest/download/SHA256SUMS -o SHA256SUMS
sha256sum -c --strict SHA256SUMS
```

The installer is also **SLSA-attested** by GitHub Actions. Inspect the provenance with [`gh attestation verify`](https://cli.github.com/manual/gh_attestation_verify).

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
