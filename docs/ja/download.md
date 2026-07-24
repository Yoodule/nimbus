# Nimbus をダウンロード

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  本番 AI エージェント向けの統合 MCP ゲートウェイ。1 つのコマンドで CLI、ゲートウェイ、すべての同梱 MCP サーバーをインストール — SHA256 で検証、会員登録不要、ローカルで動作。
</p>

<div class="prereq-callout" markdown="1">

**前提条件:** Nimbus のインストール前に <a href="https://www.docker.com/products/docker-desktop/" target="_blank">Docker Desktop</a> (Mac の場合は <a href="https://orbstack.dev/" target="_blank">OrbStack</a>) がインストールされ、**実行中** である必要があります。インストールは無料で、数分で完了します。

**クイックチェック — まずこれを実行:**

```bash
docker ps
```

`CONTAINER ID` の表 (または「no containers」の行) が表示されれば Docker は起動済みで、そのまま進められます。`Cannot connect to the Docker daemon` と表示された場合は Docker Desktop (macOS / Windows) を起動するか、Linux では `sudo systemctl start docker` を実行してから再試行してください。

</div>

## お使いのプラットフォームでインストール

=== "macOS"

    Apple Silicon と Intel に対応。macOS 12 Monterey 以降が必要です。

    **インストール (最新版):**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    インストーラーが Apple Silicon か Intel かを自動検出し、公開されている SHA256SUMS と照合します。

    直接ダウンロード:

    - [Apple Silicon (M1/M2/M3/M4) →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-arm64.tar.gz)
    - [Intel Mac →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-amd64.tar.gz)

    **システム要件:**

    - **OS:** macOS 12 Monterey 以降 (Apple Silicon または Intel)
    - **Docker:** Docker Desktop 4.x+ または [OrbStack](https://orbstack.dev/) — デーモンが実行中であること
    - **Python:** 3.12+ (未インストールの場合は [`uv`](https://astral.sh/uv) 経由で自動インストール)
    - **ディスク:** CLI 用に約 30 MB、Docker イメージ取得後は約 2 GB
    - **RAM:** 最低 4 GB、推奨 8 GB

    **特定バージョンを指定:**

    `NIMBUS_VERSION` をパイプの右側に設定してください (`curl` から見えず、変数がインストール済みスクリプトに届くように):

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Linux"

    x86_64 と aarch64 に対応。Ubuntu 22.04+、Debian 12+、Fedora 39+、Arch で動作確認済み。

    **インストール (最新版):**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    直接ダウンロード:

    - [x86_64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-amd64.tar.gz)
    - [aarch64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-arm64.tar.gz)

    **システム要件:**

    - **OS:** glibc 2.31+ (Ubuntu 22.04、Debian 12、Fedora 39、Arch)
    - **Docker:** Docker Desktop 4.x+、[OrbStack](https://orbstack.dev/)、またはヘッドレスの Docker Engine — デーモンが実行中であること
    - **Python:** 3.12+ (未インストールの場合は [`uv`](https://astral.sh/uv) 経由で自動インストール)
    - **ディスク:** CLI 用に約 30 MB、Docker イメージ取得後は約 2 GB
    - **RAM:** 最低 4 GB、推奨 8 GB

    **特定バージョンを指定:**

    `NIMBUS_VERSION` をパイプの右側に設定してください (`curl` から見えず、変数がインストール済みスクリプトに届くように):

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Windows"

    PowerShell と WSL2 に対応。管理者権限は不要です。インストーラーが PATH 設定を行い、Nimbus をユーザープロファイルに登録します。

    **インストール (最新版):**

    ```powershell
    irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

    直接ダウンロード:

    - [ワンクリック: install.cmd ランチャー →](https://nimbus.yoodule.com/install.cmd)
    - [Windows (x64) →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-windows-amd64.tar.gz)

    **システム要件:**

    - **OS:** Windows 10 ビルド 19041+ または WSL2 が有効な Windows 11
    - **Docker:** Docker Desktop 4.x+ (WSL2 バックエンド) — デーモンが実行中であること
    - **Python:** 3.12+ (未インストールの場合は [`uv`](https://astral.sh/uv) 経由で自動インストール)
    - **ディスク:** CLI 用に約 30 MB、Docker イメージ取得後は約 2 GB
    - **RAM:** 最低 4 GB、推奨 8 GB (Qdrant + Docker)

    **特定バージョンを指定:**

    インストーラー実行前にシェルで `NIMBUS_VERSION` を設定してください (変数がインストール済みスクリプトに届くように):

    ```powershell
    $env:NIMBUS_VERSION = "v1.0.3"; irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

---

公開されているすべてのバージョンは [releases ページ](https://github.com/Yoodule/nimbus/releases) で確認できます。

---

## インストール前に検証

すべてのリリースには `SHA256SUMS` ファイルが同梱されています。インストーラーが自動的にチェックサムを検証します。ご自身でチェックサムを確認する場合は、[releases ページ](https://github.com/Yoodule/nimbus/releases) からファイルを取得して以下を実行してください:

```bash
sha256sum -c --strict SHA256SUMS
```

すべてのリリースは GitHub Actions によって SLSA 署名されています。署名証明は [releases ページ](https://github.com/Yoodule/nimbus/releases) で確認できます。

---

## アップグレード

CLI はその場で自身をアップグレードします。`mcp.json`、`.env`、OAuth トークン、Qdrant インデックスは保持されます:

```bash
nimbus upgrade
```

特定のバージョンにアップグレードするには:

```bash
nimbus upgrade --version v1.0.3
```

---

## アンインストール

CLI、ゲートウェイ、ローカルの Docker スタック、インストールディレクトリを 1 ステップで削除します:

```bash
nimbus uninstall
```

将来的に再インストールするため、設定 (mcp.json、.env、トークン) を残しておきたい場合は `--keep-config` を指定してください:

```bash
nimbus uninstall --keep-config
```

---

## インストールされるもの

インストーラーはすべてを `~/.nimbus/` (または設定した `$NIMBUS_HOME`) の下に書き込みます:

```
~/.nimbus/
├── nimbus                # CLI シム
├── nimbus-gateway-*      # コンパイル済みゲートウェイバイナリ
├── mcp.json              # サーバーレジストリ
├── servers/              # 同梱の MCP サーバー
├── .env                  # ローカル設定 (OPENROUTER_API_KEY、QDRANT_URL、…)
└── logs/                 # 実行ログ
```

さらに `export NIMBUS_HOME` と `PATH` をシェル設定ファイル (`~/.zshrc`、`~/.bashrc`、Windows の `$PROFILE`) に追加し、新しいシェルでも `nimbus` が PATH に含まれるようにします。

---

## FAQ

### Apple Silicon Mac で「arm64 not found」と表示される。

そのメッセージは古いインストーラーによるものです。`nimbus upgrade` を実行して最新版を取得するか、インストールスクリプトを直接ダウンロードしてください:

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

現在のインストーラーは GitHub の CDN リダイレクトに従い、アーキテクチャを検出し、アセットが本当に欠落している場合は分かりやすいエラーで迅速に失敗します。

### Docker がないマシンにもインストールできますか?

はい。CLI とゲートウェイはネイティブで動作します。同梱の MCP スタック (Playwright ブラウザー、Postgres エージェント DB、Qdrant) は Docker を使用しますが、`nimbus start --no-deps` でスキップし、`mcp.json` 経由で Nimbus をリモート MCP サーバーに向けることができます。

### ダウンロードサイズはどれくらいですか?

CLI の tarball は圧縮状態で約 30 MB です。初回起動時に取得される Docker イメージでさらに約 2 GB (Qdrant、Playwright、Postgres) 追加されます。帯域が限られている場合は、`--no-deps` 起動モードで Docker プル をスキップできます。

### OAuth トークンはどこに保存されますか?

デフォルトではメモリ内 — 再起動時に再承認が必要です。`~/.nimbus/.env` で `NIMBUS_PERSIST_TOKENS=1` を設定すると、`~/.nimbus/tokens/` 配下に暗号化して保存されます。

### Apple Silicon で Rosetta 経由で動作しますか?

はい — インストールコマンドの前に `NIMBUS_HOST_ARCH=amd64` を設定して Intel ビルドを取得してください。Gatekeeper ツールが 60 MB 以上追加するため、少数のユーザー向けにユニバーサルバイナリは配布していません。Rosetta が透過的に処理します。

### 同じホストで Nimbus インスタンスを複数実行するには? {#how-do-i-run-multiple-nimbus-instances-on-the-same-host}

Nimbus は固定のホストポート (`3000`, `8088`, `6333`, `5433`, `6080`, `8006`, `8007`, `8081`) にバインドするため、デフォルトのインストールは単一インスタンスです。2 つ目を実行するには、リポジトリをクローンし、`compose.yaml` でポートを再マッピングし、固有の `NIMBUS_HOME` を設定し、2 つのスタックが衝突しないように `COMPOSE_PROJECT_NAME` を設定してください。詳細は下記の [複数インスタンスセクション](#how-do-i-run-multiple-nimbus-instances-on-the-same-host) を参照してください。

### インストールがハングする、curl が失敗する場合 — どうすればいいですか?

最も多い原因は、企業プロキシが TLS を傍受していることです。`HTTPS_PROXY` を設定して再試行してください。問題が CDN 特有の場合、インストールスクリプトは `NIMBUS_VERSION` を受け付けて動作確認済みのリリースに固定でき、また [releases ページ](https://github.com/Yoodule/nimbus/releases) から tarball を直接ダウンロードして手動で `~/.nimbus/` に展開することもできます — バイナリは自己完結しています。

---

<div style="text-align: center; margin: 48px 0 24px 0; padding: 32px; background: #0a0a0a; border: 1px solid #262626; border-radius: 12px;">
  <p style="color: #a3a3a3; font-size: 1.05em; margin: 0 0 16px 0;">
    ガイド付きセットアップをご希望ですか? 1 対 1 のオンボーディングセッションを予約いただければ、ワークスペースを一緒に確認します。
  </p>
  <a href="https://calendly.com/sundayj/30min" target="_blank" style="display: inline-flex; align-items: center; gap: 8px; background: #ffffff; color: #000000; text-decoration: none; font-weight: 600; padding: 12px 24px; border-radius: 8px; font-size: 1em;">
    オンボーディングセッションを予約 →
  </a>
</div>
