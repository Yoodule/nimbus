# 故障排查

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  如果 <code>nimbus</code> 行为不符合预期,先运行 <code>nimbus doctor</code>：它会输出一个健康仪表板,涵盖 Docker 可达性、CLI/网关版本差异、容器健康状况,以及你的安装是否落后于最新版本。大多数问题都会在这里暴露。
</p>

如果 `doctor` 没有覆盖你的症状,下面的章节按 **你看到的现象** 而不是怀疑的组件来组织——选择最接近的一条。

---

## 从这里开始：`nimbus doctor`

```bash
nimbus doctor
```

它会检查四项内容,每项打印一行:

- **Docker 探针**——守护进程是否可达？该检查先于其他一切执行,这样新机器在 `nimbus start` 即将失败时,不会先看到误导性的"一切正常"。
- **CLI / 网关版本差**——正在运行的网关容器是否比你的 CLI 落后一个次要版本以上？版本差过大的 CLI 会发出警告,但不会拒绝启动。
- **容器健康**——gateway、postgres、redis 和 qdrant 容器是否健康？
- **更新新鲜度**——GitHub 上是否有更新的版本？（在 dev 构建中,内嵌的 minisign 公钥为占位符时会跳过此项。）

退出码始终为 `0` —— `doctor` 永远不会失败,只会显示警告,这样它可以作为 CI 和监控中的状态检查使用。

---

## 安装问题

### 安装后 `nimbus` 不在我的 `PATH` 中

安装脚本会将 `export NIMBUS_HOME=~/.nimbus` 和 `PATH` 更新写入 `~/.zshrc`、`~/.bashrc` 或 Windows 的 `$PROFILE`。打开一个新的 shell,或在当前 shell 中 `source` rc 文件:

```bash
# macOS / Linux —— 选择你实际使用的 shell
source ~/.zshrc
source ~/.bashrc
```

如果 `nimbus` 仍然找不到,可能是安装静默失败。检查安装日志(成功执行的末尾会打印路径)并用显式脚本重新运行:

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

### 在 Apple Silicon 上安装器报告 "arm64 not found"

这条消息来自过时的安装器。拉取一份新的脚本并重新运行:

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

当前安装器遵循 GitHub 的 CDN 重定向,通过 `uname -m` 检测架构,如果资产确实缺失会以可操作的错误快速失败。

### 安装卡住或 `curl` 失败

最常见的原因是公司代理拦截了 TLS:

```bash
HTTPS_PROXY=http://your-proxy:port curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

如果问题就出在 CDN 上,可以用 `NIMBUS_VERSION` 钉住一个已知可用的版本:

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.2 bash
```

你也可以直接从 [releases 页面](https://github.com/Yoodule/nimbus/releases) 下载 tarball,手动解压到 `~/.nimbus/` —— 二进制是自包含的。

### 安装成功但 `nimbus start` 提示 Docker 不可达

Docker 已安装,但守护进程未运行。启动它:

- **macOS / Windows** —— 打开 Docker Desktop(或 OrbStack)。菜单栏的鲸鱼图标应该是静止的,而不是动画状态。
- **Linux** —— `sudo systemctl start docker`,如果你不用 systemd 就用 `sudo dockerd`。

用 `docker ps` 验证。如果看到 `Cannot connect to the Docker daemon`,说明守护进程还没准备好 —— 等几秒再试。

---

## 容器问题

### 容器反复重启

`docker ps` 显示某个容器处于 `Restarting` 状态。最常见的原因是旧 `.env` 留下的过时卷:

```bash
docker logs nimbus-gateway-1 --tail 100    # 或 nimbus-postgres-1 / nimbus-redis-1 / nimbus-qdrant-1
```

寻找具体的错误。如果是 Postgres 或 Redis 鉴权失败,说明你的 `.env` 已经轮换过凭据,但命名卷里仍然是旧值。恢复:

```bash
nimbus stop
# 把过时的卷移到一边,让 init 干净地重新执行。
# nimbus start 会在新的卷上自动生成新的凭据;
# 旧的卷会被保留为 -corrupt-<timestamp>,以防你需要检查。
docker volume rm nimbus_postgres_data
nimbus start
```

旧的 `nimbus recover-pg-role` / `nimbus recover-redis-password` 子命令已经移除 —— 上述流程是受支持的恢复路径。

### `nimbus start` 提示 "port already in use"

Nimbus 绑定固定的宿主机端口(3000 dashboard、8088 gateway、6080 noVNC、5433 postgres、6379 redis、6333/6334 qdrant)。如果宿主机上其他进程已经占用了这些端口,`start` 会失败并指出冲突的端口号。

查找并停止冲突的进程:

```bash
# macOS / Linux
sudo lsof -iTCP:8088 -sTCP:LISTEN
```

对于长期的多实例配置,请参阅[下载页面](download.md#how-do-i-run-multiple-nimbus-instances-on-the-same-host)中的 **多实例** 一节。

### 仪表板提示 "gateway unreachable"

仪表板运行在 `http://localhost:3000`。如果页面能加载但每个动作都返回 "gateway unreachable",说明网关容器实际上没有在 8088 上监听。检查:

```bash
docker ps | grep gateway
docker logs nimbus-gateway-1 --tail 50
curl -s http://localhost:8088/version
```

在 Apple Silicon 上的 Rosetta 环境下,一个常见原因是平台不匹配 —— 网关镜像是 `linux/arm64`,但运行时要求 `amd64`。在 `nimbus start` 之前设置 `NIMBUS_HOST_ARCH=arm64`。

---

## OAuth 问题

### 点击 Approve 时提示 "OAuth callback failed"

默认情况下,网关会尝试让 OAuth 回调落在 `http://localhost:8088/oauth/callback`。如果你在隧道或远程浏览器后面运行 Nimbus,提供商因 URL 与注册的不匹配而拒绝回调。

解决方法是将 `NIMBUS_URL`(仪表板 OAuth 代理使用)和 `OAUTH_REDIRECT_BASE`(网关使用)设置为提供商应当回跳到的公开 URL。两者都记录在 [`.env.example`](https://github.com/Yoodule/nimbus/blob/main/.env.example) 中。

### Upwork OAuth:"redirect_uri_mismatch"

Upwork 的 OAuth 提供商对 `redirect_uri` 的精确匹配很严格。安装器生成的 `UPWORK_REDIRECT_URI` 必须与 Upwork 开发者控制台中注册的值完全一致 —— 包括末尾的斜杠,逐字符相同。

如果看到 `redirect_uri_mismatch`,检查 `~/.nimbus/.env` 中的值:

```bash
nimbus config get UPWORK_REDIRECT_URI
```

……与 Upwork 控制台中的值进行逐字节比对。修正后,重启网关容器:

```bash
nimbus stop && nimbus start
```

### 重启后令牌消失了

这是设计如此。默认情况下,OAuth 令牌只存在于内存中 —— 每次重启都需要重新授权。这对共享 / 多用户宿主机来说是更安全的默认值。

---

## MCP 服务器问题

### 捆绑的 MCP 服务器无法启动

`docker logs nimbus-gateway-1 --tail 200` 会显示 stdio 子进程因导入错误或缺失环境变量而死亡。两个常见原因:

1. **缺少 API 密钥** —— 检查 `~/.nimbus/.env` 中相关的 `*_API_KEYS`(复数形式,逗号分隔)。网关和仪表板都读取复数形式,在缺失时回退到单数形式;键池为空 ⇒ 提供商返回 401。
2. **Python 版本差异** —— 捆绑的 MCP 服务器通过 `uv run python` 运行。如果你的系统 Python 低于 3.12,`uv` 会在首次调用时拉取较新版本,首次可能耗时约 30 秒。

### `find_tools` 不返回任何结果

`find_tools` 是对 Qdrant 向量索引的语义搜索。空结果意味着:

- 无法访问 Qdrant —— `docker ps | grep qdrant` 应该显示健康;`curl http://localhost:6333/healthz` 应返回 200。
- 索引尚未构建 —— 网关在首次启动时摄取工具描述。等一分钟后再试。如果 5 分钟后仍然为空,请重启:`nimbus stop && nimbus start`。

### 我在 `mcp.json` 中添加了服务器但没显示

两种可能:

1. **`mcp.json` 语法错误** —— 网关会静默跳过格式错误的条目。用以下命令验证:
   ```bash
   nimbus mcp list
   ```
   如果你的新服务器不在列表中,问题就出在 JSON 上。末尾多余的逗号或未转义的反斜杠是最常见的元凶。

2. **网关尚未重新加载** —— `mcp.json` 在容器启动时读取。编辑后:
   ```bash
   nimbus stop && nimbus start
   ```

对于 HTTP 服务器,URL 必须能够从网关容器内部访问 —— 宿主机上的 `localhost` 并不等于 Docker 容器内的 `localhost`。请改用 `host.docker.internal:<port>`。

---

## OpenRouter / 模型问题

### 首次聊天时提示 "Invalid API key"

CLI 在第一次 `nimbus start` 时会提示输入 `OPENROUTER_API_KEY` 并写入 `~/.nimbus/.env`。如果你跳过了该提示或密钥已过期:

```bash
nimbus config set OPENROUTER_API_KEYS sk-or-v1-...
nimbus stop && nimbus start
```

注意复数形式:`OPENROUTER_API_KEYS`(多个密钥用逗号分隔,在缺失时回退到单数形式)。空或错误的密钥池会让每个请求都不带 `Authorization` 头发出,提供商返回 401。

如需在**不覆盖**现有密钥的前提下**添加**新密钥,请使用 `append`(默认去重,加 `--force` 允许重复);从密钥池中移除某项请使用 `remove`:

```bash
nimbus config append OPENAI_API_KEYS sk-newkey
nimbus config remove OPENAI_API_KEYS sk-oldkey
```

!!! note "CLI v1.0.5 新增"
    `nimbus config append` / `prepend` / `remove` 在 v1.0.5 引入。旧版本无法识别——请先执行 `nimbus update`。

### 特定模型 ID 提示 "Model not found"

Nimbus 默认使用 `openrouter/free`。如果你传入了 `--model <id>`,但该模型在 OpenRouter 上不存在,你会收到 404。请在 [openrouter.ai/models](https://openrouter.ai/models) 上核对模型 ID —— 它们经常变化。

对于 Ollama 模型,路由前缀是 `ollama/<model-name>`(例如 `ollama/llama3.1`)。没有前缀的裸 ID 会被视为 OpenRouter。

### 嵌入失败

嵌入默认使用 `nvidia/llama-nemotron-embed-vl-1b-v2:free`(2048 维,免费层)。如果该模型不可用或被限流,请设置一个回退:

```bash
nimbus config set EMBEDDING_MODEL openai/text-embedding-3-small
nimbus stop && nimbus start
```

下次启动时会将所有工具描述重新摄取到 Qdrant —— 冷缓存下预计需要约 1 分钟的索引时间。

---

## 恢复

### "Nimbus was installed by a different version"

这意味着之前的安装将 Postgres 或 Redis 卷冻结在了与当前 `.env` 不再匹配的凭据上。解决方法:

```bash
nimbus stop && nimbus start
```

`start` 会自动检测不匹配,并根据当前 `.env` 重新初始化角色 / 密码。旧的 `recover-pg-role` / `recover-redis-password` 子命令已不存在。

### 清除一切并重新开始

```bash
nimbus uninstall
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
nimbus start
```

这会删除 CLI、所有容器、所有命名卷,以及 `~/.nimbus/`。你将丢失 OAuth 令牌、`.env` 和 Qdrant 中存储的所有工具描述。首次启动时需要重新授权。

### 我想回滚到之前的 CLI 版本

```bash
nimbus update --version v1.0.1
```

(或者你需要的版本。)CLI 的自我更新使用与 `nimbus update` 相同的原子替换 + SHA256 + minisign 路径,只是被钉在了指定的版本上。

---

## 仍然卡住？

在 [Nimbus tracker](https://github.com/Yoodule/nimbus/issues) 上开一个 issue,并附上:

- `nimbus doctor` 的输出
- 宿主机平台和架构(macOS / Linux 用 `uname -a`,Windows 用 `systeminfo`)
- 相关的容器日志:`docker logs nimbus-gateway-1 --tail 200`(或 `nimbus-postgres-1` / `nimbus-redis-1` / `nimbus-qdrant-1`)
- `~/.nimbus/logs/` 中任何看起来相关的内容

CLI 永远不会发送你的 `.env` 或 OAuth 令牌 —— 这些由你来脱敏,但其余诊断信息是可以安全分享的。
