# Configuration

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  Nimbus is configured through environment variables in <code>~/.nimbus/.env</code>. Most settings have safe defaults; the ones below are the ones you'll actually touch.
</p>

## Sign-up mode

Nimbus controls who can create an account via `/sign-up` through one env var, `NIMBUS_SIGN_UP_MODE`. The default is admin-gated — the first signup creates the admin, then self-registration locks.

### The three modes

| Mode | What happens | Typical use case |
| --- | --- | --- |
| `first_user_only` *(default)* | The first signup creates the admin. After that, `/sign-up` redirects to `/sign-in`. | Self-hosted single-operator installs, internal company tools |
| `open` | Anyone can sign up. New accounts get the default role. | Public-facing deployments, multi-tenant SaaS |
| `closed` | Nobody can sign up. The admin must mint users via CLI / SQL / direct DB insert. | Locked-down environments, demo installs |

The default is `first_user_only` because it's the only mode that bootstraps without manual intervention: a fresh install accepts the first signup (which becomes admin via Better Auth's admin plugin), then closes. Operators who want open registration set `NIMBUS_SIGN_UP_MODE=open` once and the install keeps accepting sign-ups from then on.

### How to change it

Use the `nimbus config` CLI — it's a thin wrapper around `~/.nimbus/.env` that handles quoting and avoids hand-editing the file:

```bash
nimbus config set NIMBUS_SIGN_UP_MODE open        # or "closed", or "first_user_only"
nimbus stop && nimbus start
```

Three commands, restart required so the dashboard picks up the new value on next boot.

### Useful sub-commands

```bash
nimbus config get NIMBUS_SIGN_UP_MODE             # print the current value
nimbus config list                               # show every key in ~/.nimbus/.env
nimbus config unset NIMBUS_SIGN_UP_MODE          # clear the line → falls back to runtime default
```

### Why it's admin-gated by default

Self-hosted software has a long history of "default = open registration" creating security incidents: a fresh install with an open `/sign-up` endpoint becomes a public account-minting machine within minutes of going live. Nimbus closed that hole in August 2026 by switching the default to `first_user_only` — the install bootstraps cleanly (the operator's first signup becomes admin), and from that point on, self-registration is locked unless the operator opts back in via `NIMBUS_SIGN_UP_MODE=open`.

If you want to add a teammate without flipping the mode, you have two options:

- Flip the env var to `open`, restart, share `/sign-up`, then flip it back to `first_user_only` once they're registered.
- Insert the row directly into the `user` table — the schema lives in `dashboard/src/lib/db/pg/schema.pg.ts`. Hash the password with Better Auth's `scrypt` (used at `node:crypto scrypt` with `@noble/hashes` as a fallback) before inserting.

### Verifying the current mode

The dashboard's sign-in page renders a "Sign up" footer whenever registration is allowed. If you see the footer, sign-up is open or you're the first user on a fresh install. If you don't, you're on a closed-mode install with existing users.

For the raw value, `nimbus config get NIMBUS_SIGN_UP_MODE` prints it — or use `nimbus config list` for every key at once.