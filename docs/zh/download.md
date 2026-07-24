# 下载 Nimbus

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  面向生产 AI Agent 的统一 MCP 网关。一条命令即可安装 CLI、网关及所有捆绑的 MCP 服务器 —— 经过 SHA256 校验、无需注册、本地运行。
</p>

<div class="prereq-callout" markdown="1">

**前置条件:** 安装 Nimbus 前,需要先安装并**运行** <a href="https://www.docker.com/products/docker-desktop/" target="_blank">Docker Desktop</a>(Mac 上也可以使用 <a href="https://orbstack.dev/" target="_blank">OrbStack</a>)。安装免费,只需几分钟。

**快速检查 —— 请先运行以下命令:**

```bash
docker ps
```

如果看到 `CONTAINER ID` 表格(或一行"no containers"),说明 Docker 已启动,可以继续。如果看到 `Cannot connect to the Docker daemon`,请启动 Docker Desktop(macOS / Windows)或执行 `sudo systemctl start docker`(Linux)后重试。

</div>

## 根据你的平台安装

=== "macOS"

    支持 Apple Silicon 和 Intel。需要 macOS 12 Monterey 或更高版本。

    **安装(最新版本):**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    安装程序会自动检测 Apple Silicon 还是 Intel,并对照已发布的 SHA256SUMS 进行校验。

    直接下载:

    - [Apple Silicon(M1/M2/M3/M4)→](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-arm64.tar.gz)
    - [Intel Mac →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-amd64.tar.gz)

    **系统要求:**

    - **操作系统:** macOS 12 Monterey 或更高版本(Apple Silicon 或 Intel)
    - **Docker:** Docker Desktop 4.x+ 或 [OrbStack](https://orbstack.dev/) —— 守护进程必须处于运行状态
    - **Python:** 3.12+(如果未安装,会通过 [`uv`](https://astral.sh/uv) 自动安装)
    - **磁盘:** CLI 约需 30 MB,拉取 Docker 镜像后约 2 GB
    - **内存:** 最低 4 GB,推荐 8 GB

    **固定到特定版本:**

    将 `NIMBUS_VERSION` 设置在管道的右侧(这样 `curl` 看不到它,变量会到达已安装的脚本):

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Linux"

    支持 x86_64 和 aarch64。已在 Ubuntu 22.04+、Debian 12+、Fedora 39+ 和 Arch 上测试。

    **安装(最新版本):**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    直接下载:

    - [x86_64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-amd64.tar.gz)
    - [aarch64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-arm64.tar.gz)

    **系统要求:**

    - **操作系统:** glibc 2.31+(Ubuntu 22.04、Debian 12、Fedora 39、Arch)
    - **Docker:** Docker Desktop 4.x+、[OrbStack](https://orbstack.dev/),或无头 Docker Engine —— 守护进程必须处于运行状态
    - **Python:** 3.12+(如果未安装,会通过 [`uv`](https://astral.sh/uv) 自动安装)
    - **磁盘:** CLI 约需 30 MB,拉取 Docker 镜像后约 2 GB
    - **内存:** 最低 4 GB,推荐 8 GB

    **固定到特定版本:**

    将 `NIMBUS_VERSION` 设置在管道的右侧(这样 `curl` 看不到它,变量会到达已安装的脚本):

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Windows"

    支持 PowerShell 和 WSL2。不需要管理员权限。安装程序会处理 PATH 设置并将 Nimbus 注册到你的用户配置中。

    **安装(最新版本):**

    ```powershell
    irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

    直接下载:

    - [一键:install.cmd 启动器 →](https://nimbus.yoodule.com/install.cmd)
    - [Windows(x64)→](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-windows-amd64.tar.gz)

    **系统要求:**

    - **操作系统:** Windows 10 build 19041+ 或启用了 WSL2 的 Windows 11
    - **Docker:** Docker Desktop 4.x+(使用 WSL2 后端)—— 守护进程必须处于运行状态
    - **Python:** 3.12+(如果未安装,会通过 [`uv`](https://astral.sh/uv) 自动安装)
    - **磁盘:** CLI 约需 30 MB,拉取 Docker 镜像后约 2 GB
    - **内存:** 最低 4 GB,推荐 8 GB(Qdrant + Docker)

    **固定到特定版本:**

    在运行安装程序前,先在 shell 中设置 `NIMBUS_VERSION`(这样变量会到达已安装的脚本):

    ```powershell
    $env:NIMBUS_VERSION = "v1.0.3"; irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

---

在 [releases 页面](https://github.com/Yoodule/nimbus/releases) 浏览所有已发布的版本。

---

## 安装前验证

每个发布版本都附带一个 `SHA256SUMS` 文件。安装程序会自动校验。如需自行检查校验和,请从 [releases 页面](https://github.com/Yoodule/nimbus/releases) 获取该文件并执行:

```bash
sha256sum -c --strict SHA256SUMS
```

每个发布版本都由 GitHub Actions 提供 SLSA 签名。你可以在 [releases 页面](https://github.com/Yoodule/nimbus/releases) 查看签名证明。

---

## 升级

CLI 会原地升级自身。`mcp.json`、`.env`、OAuth 令牌和 Qdrant 索引都会保留:

```bash
nimbus upgrade
```

升级到特定版本:

```bash
nimbus upgrade --version v1.0.3
```

---

## 卸载

一步移除 CLI、网关、本地 Docker 栈和安装目录:

```bash
nimbus uninstall
```

如果希望保留你的配置(mcp.json、.env、令牌)以便将来重新安装,请加上 `--keep-config`:

```bash
nimbus uninstall --keep-config
```

---

## 安装的内容

安装程序会将所有内容写入 `~/.nimbus/` 目录(或你设置的 `$NIMBUS_HOME`):

```
~/.nimbus/
├── nimbus                # CLI 垫片
├── nimbus-gateway-*      # 编译后的网关二进制文件
├── mcp.json              # 服务器注册表
├── servers/              # 捆绑的 MCP 服务器
├── .env                  # 本地配置(OPENROUTER_API_KEY、QDRANT_URL、…)
└── logs/                 # 运行日志
```

它还会将 `export NIMBUS_HOME` 和 `PATH` 添加到你的 shell 配置文件(`~/.zshrc`、`~/.bashrc` 或 Windows 上的 `$PROFILE`),以便在新的 shell 中 `nimbus` 位于 PATH 上。

---

## FAQ

### 在我的 Apple Silicon Mac 上,安装程序提示"arm64 not found"。

该消息来自过时的安装程序。请运行 `nimbus upgrade` 拉取最新版,或直接获取最新脚本:

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

当前的安装程序会跟踪 GitHub 的 CDN 重定向,检测你的架构,并在资源确实缺失时以可操作的错误快速失败。

### 我可以在没有 Docker 的机器上安装吗?

可以。CLI 和网关以原生方式运行。捆绑的 MCP 栈(Playwright 浏览器、Postgres Agent 数据库、Qdrant)使用 Docker,但你可以通过 `nimbus start --no-deps` 跳过它,并通过 `mcp.json` 让 Nimbus 指向远程 MCP 服务器。

### 下载体积有多大?

CLI 压缩包约 30 MB。首次启动时拉取的 Docker 镜像还会再增加约 2 GB(Qdrant、Playwright、Postgres)。如果你的带宽有限,可以使用 `--no-deps` 启动模式跳过 Docker 拉取。

### 我的 OAuth 令牌存放在哪里?

默认情况下存放在内存中 —— 重启时需要重新授权。在 `~/.nimbus/.env` 中设置 `NIMBUS_PERSIST_TOKENS=1` 即可在 `~/.nimbus/tokens/` 下加密保存。

### 在 Apple Silicon 上通过 Rosetta 运行可以吗?

可以 —— 在安装命令前设置 `NIMBUS_HOST_ARCH=amd64` 以获取 Intel 版本。我们不提供通用二进制,因为 Gatekeeper 工具会为少数用户额外增加 60 MB 以上;Rosetta 会透明地进行翻译。

### 如何在同一台主机上运行多个 Nimbus 实例? {#how-do-i-run-multiple-nimbus-instances-on-the-same-host}

Nimbus 绑定到固定的主机端口(`3000`、`8088`、`6333`、`5433`、`6080`、`8006`、`8007`、`8081`),因此默认安装是单实例的。要运行第二个实例,请克隆仓库,在 `compose.yaml` 中重新映射端口,设置唯一的 `NIMBUS_HOME`,并设置 `COMPOSE_PROJECT_NAME` 以避免两个栈发生冲突。详细步骤请参阅下方的[多实例部分](#how-do-i-run-multiple-nimbus-instances-on-the-same-host)。

### 安装卡住或 curl 失败 —— 怎么办?

最常见的原因是公司代理拦截了 TLS。请设置 `HTTPS_PROXY` 后重试。如果问题出在 CDN,安装脚本接受 `NIMBUS_VERSION` 以固定到已知可用的发布版本,也可以从 [releases 页面](https://github.com/Yoodule/nimbus/releases) 直接下载 tarball 并手动解压到 `~/.nimbus/` —— 该二进制是自包含的。

---

<div style="text-align: center; margin: 48px 0 24px 0; padding: 32px; background: #0a0a0a; border: 1px solid #262626; border-radius: 12px;">
  <p style="color: #a3a3a3; font-size: 1.05em; margin: 0 0 16px 0;">
    想要获得指导性设置?预约一对一的上线辅导,我们将一起浏览你的工作区。
  </p>
  <a href="https://calendly.com/sundayj/30min" target="_blank" style="display: inline-flex; align-items: center; gap: 8px; background: #ffffff; color: #000000; text-decoration: none; font-weight: 600; padding: 12px 24px; border-radius: 8px; font-size: 1em;">
    预约上线辅导 →
  </a>
</div>
