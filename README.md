# Nimbus Platform Distribution
This repository contains the binary distributions and installation scripts for the Nimbus platform.

## Deployment Options

### 1. Standard VPS (Recommended)
The easiest way to deploy Nimbus is on a standard Linux VPS (Ubuntu, Debian, etc.).
```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
nimbus start
```

### 2. Deploy on Railway
If you prefer a managed PaaS, you can deploy the entire Nimbus stack (Gateway, Dashboard, Postgres, Redis, Qdrant) directly to Railway with one click.

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/template/nimbus-agent-247-employee)
