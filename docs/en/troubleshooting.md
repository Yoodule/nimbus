# Troubleshooting

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  If <code>nimbus</code> isn't behaving, start with <code>nimbus doctor</code> — it prints a health dashboard covering Docker reachability, CLI/gateway version skew, container health, and whether your install is behind the latest release. Most issues show up there.
</p>

If `doctor` doesn't cover your symptom, the sections below are organized by **what you're seeing** rather than which component you suspect — pick the closest match.

---

## Start here: `nimbus doctor`

```bash
nimbus doctor
```

It checks four things and prints one line per check:

- **Docker probe** — is the daemon reachable? This runs first so a fresh machine doesn't see misleading "everything's fine" output while `nimbus start` is about to fail.
- **CLI / gateway skew** — is the running gateway container older than your CLI by more than a minor version? A skewed CLI will warn but won't refuse to start.
- **Container health** — are the gateway, postgres, redis, and qdrant containers healthy?
- **Update freshness** — is there a newer release on GitHub? (Skipped on dev builds where the embedded minisign pubkey is a placeholder.)

Exit code is always `0` — `doctor` never fails, it surfaces warnings so it stays usable as a status check from CI and monitoring.

---

## Install problems

### `nimbus` is not on my `PATH` after install

The installer writes `export NIMBUS_HOME=~/.nimbus` and `PATH` updates to `~/.zshrc`, `~/.bashrc`, or `$PROFILE` (Windows). Open a new shell, or `source` your rc file in the current one:

```bash
# macOS / Linux — pick whichever shell you actually use
source ~/.zshrc
source ~/.bashrc
```

If `nimbus` is still missing, the install may have failed silently. Check the install log (it prints the path at the end of a successful run) and re-run with the explicit script:

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

### The installer says "arm64 not found" on Apple Silicon

That message is from an outdated installer. Pull a fresh copy of the script and re-run:

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

The current installer follows GitHub's CDN redirect, detects your architecture via `uname -m`, and fails fast with an actionable error if the asset is genuinely missing.

### The install hangs or `curl` fails

The most common cause is a corporate proxy intercepting TLS:

```bash
HTTPS_PROXY=http://your-proxy:port curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

If the CDN itself is the problem, pin a known-good version with `NIMBUS_VERSION`:

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.2 bash
```

You can also download the tarball directly from the [releases page](https://github.com/Yoodule/nimbus/releases) and untar it into `~/.nimbus/` by hand — the binary is self-contained.

### Install succeeds but `nimbus start` says Docker isn't reachable

Docker is installed but the daemon isn't running. Start it:

- **macOS / Windows** — open Docker Desktop (or OrbStack). The whale icon in the menu bar should be solid, not animated.
- **Linux** — `sudo systemctl start docker`, or `sudo dockerd` if you're not on systemd.

Verify with `docker ps`. If you see `Cannot connect to the Docker daemon`, the daemon isn't up yet — give it a few seconds and retry.

---

## Container problems

### A container keeps restarting

`docker ps` shows one container in a `Restarting` state. The most common cause is a stale volume from an older `.env`:

```bash
docker logs nimbus-gateway-1 --tail 100    # or nimbus-postgres-1 / nimbus-redis-1 / nimbus-qdrant-1
```

Look for the specific error. If it's a Postgres or Redis auth failure, your `.env` rotated credentials but the named volume still has the old ones. Recovery:

```bash
nimbus stop
# Move the stale volume aside so init re-runs cleanly. nimbus start
# auto-generates fresh credentials on a fresh volume; the old one is
# preserved as -corrupt-<timestamp> in case you need to inspect it.
docker volume rm nimbus_postgres_data
nimbus start
```

The earlier `nimbus recover-pg-role` / `nimbus recover-redis-password` subcommands are gone — this flow is the supported recovery path.

### `nimbus start` says "port already in use"

Nimbus binds fixed host ports (3000 dashboard, 8088 gateway, 6080 noVNC, 5433 postgres, 6379 redis, 6333/6334 qdrant). If something else on the host already holds one of these ports, `start` will fail with the conflicting port number.

Find and stop the conflicting process:

```bash
# macOS / Linux
sudo lsof -iTCP:8088 -sTCP:LISTEN
```

For a long-term multi-instance setup, see the **Multiple instances** section in the [Download page](download.md#how-do-i-run-multiple-nimbus-instances-on-the-same-host).

### The dashboard says "gateway unreachable"

The dashboard runs at `http://localhost:3000`. If it loads but every action returns "gateway unreachable," the gateway container isn't actually listening on 8088. Check:

```bash
docker ps | grep gateway
docker logs nimbus-gateway-1 --tail 50
curl -s http://localhost:8088/version
```

A common cause on Apple Silicon under Rosetta is a platform mismatch — the gateway image is `linux/arm64` but the runtime wants `amd64`. Set `NIMBUS_HOST_ARCH=arm64` before `nimbus start`.

---

## OAuth problems

### "OAuth callback failed" when I click Approve

The gateway tries to land the OAuth callback on `http://localhost:8088/oauth/callback` by default. If you're running Nimbus behind a tunnel or remote browser, the provider will reject the callback because the URL doesn't match what's registered.

The fix is to set `NIMBUS_URL` (used by the dashboard's OAuth proxy) and `OAUTH_REDIRECT_BASE` (used by the gateway) to the public URL the provider should bounce to. Both are documented in [`.env.example`](https://github.com/Yoodule/nimbus/blob/main/.env.example).

### Upwork OAuth: "redirect_uri_mismatch"

Upwork's OAuth provider is strict about exact `redirect_uri` matching. The installer's `UPWORK_REDIRECT_URI` must equal what's registered in the Upwork developer console — character for character, including the trailing slash.

If you see `redirect_uri_mismatch`, check the value in `~/.nimbus/.env`:

```bash
nimbus config get UPWORK_REDIRECT_URI
```

…and compare it byte-for-byte with the Upwork console. After fixing, restart the gateway container:

```bash
nimbus stop && nimbus start
```

### Tokens disappeared after restart

That's by design. By default, OAuth tokens live in memory only — every restart is a fresh re-authorization. This is the safer default for shared / multi-user hosts.

---

## MCP server problems

### A bundled MCP server fails to start

`docker logs nimbus-gateway-1 --tail 200` will show the stdio subprocess dying with an import error or missing env var. The two usual culprits:

1. **Missing API key** — check `~/.nimbus/.env` for the relevant `*_API_KEYS` (plural, comma-separated). The gateway and dashboard both read the plural form and fall back to the singular; empty pool ⇒ the provider returns 401.
2. **Python version skew** — bundled MCP servers run via `uv run python`. If you have a system Python older than 3.12, `uv` will fetch a newer one on first invocation, which can take ~30 seconds the first time.

### `find_tools` returns nothing

`find_tools` is semantic search over the Qdrant vector index. Empty results mean either:

- Qdrant isn't reachable — `docker ps | grep qdrant` should show healthy; `curl http://localhost:6333/healthz` should return 200.
- The index hasn't been built yet — the gateway ingests tool descriptions on first start. Wait a minute, then retry. If still empty after 5 minutes, restart: `nimbus stop && nimbus start`.

### I added a server to `mcp.json` but it's not appearing

Two possibilities:

1. **Syntax error in `mcp.json`** — the gateway silently skips malformed entries. Validate with:
   ```bash
   nimbus mcp list
   ```
   If your new server isn't in the list, JSON is the issue. A trailing comma or unescaped backslash is the usual offender.

2. **The gateway hasn't reloaded** — `mcp.json` is read on container start. After editing:
   ```bash
   nimbus stop && nimbus start
   ```

For HTTP servers, the URL must be reachable from inside the gateway container — `localhost` from your host machine is *not* the same as `localhost` inside Docker. Use `host.docker.internal:<port>` instead.

---

## OpenRouter / model problems

### "Invalid API key" on first chat

The CLI prompts for `OPENROUTER_API_KEY` on the very first `nimbus start` and writes it to `~/.nimbus/.env`. If you skipped that prompt or the key is stale:

```bash
nimbus config set OPENROUTER_API_KEYS sk-or-v1-...
nimbus stop && nimbus start
```

Note the plural: `OPENROUTER_API_KEYS` (comma-separated for multiple keys, with fallback to the singular form). An empty or wrong key pool makes every request leave with no `Authorization` header and the provider returns 401.

To **add** a key to an existing pool without overwriting the others, use `append` (dedup by default; pass `--force` to allow duplicates). To drop a key from the pool, use `remove`:

```bash
nimbus config append OPENAI_API_KEYS sk-newkey
nimbus config remove OPENAI_API_KEYS sk-oldkey
```

!!! note "Added in CLI v1.0.5"
    `nimbus config append`, `prepend`, and `remove` were introduced in v1.0.5. Earlier releases don't recognize these subcommands — run `nimbus update` first.

### "Model not found" for a specific model ID

Nimbus defaults to `openrouter/free`. If you pass `--model <id>` and the model doesn't exist on OpenRouter, you'll get a 404. Check the model ID at [openrouter.ai/models](https://openrouter.ai/models) — they change frequently.

For Ollama models, the routing prefix is `ollama/<model-name>` (e.g. `ollama/llama3.1`). Bare IDs without the prefix are assumed to be OpenRouter.

### Embeddings failing

Embeddings default to `nvidia/llama-nemotron-embed-vl-1b-v2:free` (2048-dim, free tier). If that model is unavailable or rate-limited, set a fallback:

```bash
nimbus config set EMBEDDING_MODEL openai/text-embedding-3-small
nimbus stop && nimbus start
```

This re-ingests every tool description into Qdrant on the next start — expect a minute of indexing time on a cold cache.

---

## Recovery

### "Nimbus was installed by a different version"

Means a prior install left a Postgres or Redis volume frozen under credentials that no longer match your `.env`. The fix:

```bash
nimbus stop && nimbus start
```

`start` auto-detects the mismatch and re-initializes the role/password against the live `.env`. The earlier `recover-pg-role` / `recover-redis-password` subcommands are gone.

### Wipe everything and start fresh

```bash
nimbus uninstall
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
nimbus start
```

This removes the CLI, all containers, all named volumes, and `~/.nimbus/`. You'll lose OAuth tokens, `.env`, and any tool descriptions stored in Qdrant. Re-authorize on first launch.

### I want to roll back to a previous CLI version

```bash
nimbus update --version v1.0.1
```

(Or whichever version you need.) The CLI self-update uses the same atomic replace + SHA256 + minisign path as `nimbus update`, just pinned to a specific release.

---

## Still stuck?

Open an issue on the [Nimbus tracker](https://github.com/Yoodule/nimbus/issues) with:

- Output of `nimbus doctor`
- Host platform and architecture (`uname -a` on macOS/Linux, `systeminfo` on Windows)
- Relevant container logs: `docker logs nimbus-gateway-1 --tail 200` (or `nimbus-postgres-1` / `nimbus-redis-1` / `nimbus-qdrant-1`)
- Anything from `~/.nimbus/logs/` that looks related

The CLI never sends your `.env` or OAuth tokens — those are yours to redact, but the rest of the diagnostics are safe to share.