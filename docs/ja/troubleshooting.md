# トラブルシューティング

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  <code>nimbus</code> が期待通りに動作しない場合は、まず <code>nimbus doctor</code> を実行してください。Docker への到達性、CLI/ゲートウェイのバージョンスキュー、コンテナーの健全性、インストールが最新リリースより遅れていないかを網羅するヘルスダッシュボードを出力します。ほとんどの問題はここに出てきます。
</p>

`doctor` が症状をカバーしていない場合、以下のセクションは疑わしいコンポーネントではなく **目に見える症状** で構成されています。最も近いものを選んでください。

---

## まずここから：`nimbus doctor`

```bash
nimbus doctor
```

次の 4 つを確認し、それぞれ 1 行ずつ出力します：

- **Docker プローブ** — daemon に到達できるか？新しいマシンが `nimbus start` の失敗直前に「すべて正常」と誤表示しないように、これは最初に実行されます。
- **CLI / ゲートウェイ スキュー** — 実行中のゲートウェイコンテナーが CLI より 1 つ以上のマイナーバージョン古くないか？スキューがある CLI は警告は出しますが起動拒否はしません。
- **コンテナーの健全性** — gateway、postgres、redis、qdrant コンテナーは健全か？
- **アップデートの新しさ** — GitHub に新しいリリースはあるか？（埋め込まれた minisign 公開鍵がプレースホルダーの dev ビルドではスキップされます。）

終了コードは常に `0` — `doctor` は失敗しません。CI や監視からのステータスチェックとして使えるように、警告を表示する設計です。

---

## インストールの問題

### インストール後に `nimbus` が `PATH` にない

インストーラは `export NIMBUS_HOME=~/.nimbus` と `PATH` 更新を `~/.zshrc`、`~/.bashrc`、または Windows の `$PROFILE` に書き込みます。新しいシェルを開くか、現在のシェルで rc を `source` してください：

```bash
# macOS / Linux — 実際に使用しているシェルを選択
source ~/.zshrc
source ~/.bashrc
```

それでも `nimbus` が見つからない場合、インストールがサイレントに失敗した可能性があります。インストールログ（成功した実行の最後にパスが出力されます）を確認し、明示的なスクリプトで再実行してください：

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

### Apple Silicon で「arm64 not found」と表示される

このメッセージは古いインストーラが出しています。スクリプトの新しいコピーを取得して再実行してください：

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

現行のインストーラは GitHub の CDN リダイレクトに従い、`uname -m` でアーキテクチャを検出し、成果物が本当に見つからない場合は実用的なエラーで早期失敗します。

### インストールが固まる、または `curl` が失敗する

最も一般的な原因は、企業プロキシが TLS を傍受していることです：

```bash
HTTPS_PROXY=http://your-proxy:port curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

CDN 自体が問題の場合は、`NIMBUS_VERSION` で動作確認済みのバージョンに固定してください：

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.2 bash
```

[releases ページ](https://github.com/Yoodule/nimbus/releases)から tarball を直接ダウンロードし、`~/.nimbus/` に手動で展開することもできます。バイナリは自己完結型です。

### インストールは成功したが `nimbus start` が Docker に到達できないと言う

Docker はインストール済みだが daemon が起動していません。起動してください：

- **macOS / Windows** — Docker Desktop（または OrbStack）を開く。メニューバーの鯨アイコンはアニメーションではなく停止している必要があります。
- **Linux** — `sudo systemctl start docker`、systemd を使っていない場合は `sudo dockerd`。

`docker ps` で確認してください。`Cannot connect to the Docker daemon` と表示される場合は daemon がまだ準備できていません。数秒待ってから再試行してください。

---

## コンテナーの問題

### コンテナーが繰り返し再起動する

`docker ps` で 1 つのコンテナーが `Restarting` 状態になっています。最も一般的な原因は、古い `.env` に由来するボリュームの古さです：

```bash
docker logs nimbus-gateway-1 --tail 100    # または nimbus-postgres-1 / nimbus-redis-1 / nimbus-qdrant-1
```

具体的なエラーを探してください。Postgres または Redis の認証エラーの場合、`.env` の認証情報はローテーション済みですが、名前付きボリュームには古いものが残っています。復旧：

```bash
nimbus stop
# 古いボリュームを脇に退け、init をクリーンに再実行します。
# nimbus start は新しいボリュームに新しい認証情報を自動生成します；
# 古いボリュームは -corrupt-<timestamp> として残るので必要なら確認できます。
docker volume rm nimbus_postgres_data
nimbus start
```

以前の `nimbus recover-pg-role` / `nimbus recover-redis-password` サブコマンドは廃止されました — このフローがサポートされている復旧パスです。

### `nimbus start` が「port already in use」と言う

Nimbus は固定のホストポートをバインドします（3000 dashboard、8088 gateway、6080 noVNC、5433 postgres、6379 redis、6333/6334 qdrant）。ホスト上で他のプロセスがすでにこれらのポートを占有している場合、`start` は競合ポート番号を明記して失敗します。

競合しているプロセスを見つけて停止してください：

```bash
# macOS / Linux
sudo lsof -iTCP:8088 -sTCP:LISTEN
```

長期的なマルチインスタンス構成については、[ダウンロードページ](download.md#how-do-i-run-multiple-nimbus-instances-on-the-same-host)の **複数インスタンス** セクションを参照してください。

### ダッシュボードが「gateway unreachable」と言う

ダッシュボードは `http://localhost:3000` で動作しています。読み込みはできるがすべてのアクションが「gateway unreachable」を返す場合、ゲートウェイコンテナーが実際に 8088 で待ち受けていません。以下を確認してください：

```bash
docker ps | grep gateway
docker logs nimbus-gateway-1 --tail 50
curl -s http://localhost:8088/version
```

Apple Silicon + Rosetta でよくある原因はプラットフォームの不一致です — ゲートウェイイメージは `linux/arm64` ですが、ランタイムが `amd64` を要求しています。`nimbus start` の前に `NIMBUS_HOST_ARCH=arm64` を設定してください。

---

## OAuth 関連の問題

### Approve をクリックしたときに「OAuth callback failed」

デフォルトでは、ゲートウェイは OAuth コールバックを `http://localhost:8088/oauth/callback` に着地させようとします。トンネルやリモートブラウザの背後で Nimbus を実行している場合、登録されている URL と一致しないため、プロバイダがコールバックを拒否します。

修正は、`NIMBUS_URL`（ダッシュボードの OAuth プロキシが使用）と `OAUTH_REDIRECT_BASE`（ゲートウェイが使用）を、プロバイダがリダイレクトすべき公開 URL に設定することです。両方は [`.env.example`](https://github.com/Yoodule/nimbus/blob/main/.env.example) に記載されています。

### Upwork OAuth：「redirect_uri_mismatch」

Upwork の OAuth プロバイダは `redirect_uri` の一致に対して厳格です。インストーラの `UPWORK_REDIRECT_URI` は、Upwork 開発者コンソールに登録されているものと、末尾のスラッシュを含め 1 文字ずつ一致している必要があります。

`redirect_uri_mismatch` が出た場合は、`~/.nimbus/.env` の値を確認してください：

```bash
nimbus config get UPWORK_REDIRECT_URI
```

…Upwork コンソールの値とバイト単位で比較してください。修正後、ゲートウェイコンテナーを再起動します：

```bash
nimbus stop && nimbus start
```

### 再起動後にトークンが消える

仕様です。デフォルトでは OAuth トークンはメモリ上だけに存在し、再起動のたびに再認可が必要です。これは共有 / マルチユーザーのホストにとってより安全なデフォルトです。トークンを永続化したい場合は、ダウンロード FAQ の [OAuth 永続化セクション](download.md#where-do-my-oauth-tokens-live)を参照してください。

---

## MCP サーバーの問題

### バンドルされた MCP サーバーが起動しない

`docker logs nimbus-gateway-1 --tail 200` で、stdio サブプロセスがインポートエラーまたは環境変数の不足で死んでいるのが表示されます。よくある 2 つの原因：

1. **API キーが不足** — `~/.nimbus/.env` で該当する `*_API_KEYS`（複数形、カンマ区切り）を確認してください。ゲートウェイとダッシュボードは複数形を読み取り、単数形にフォールバックします。プールが空 ⇒ プロバイダが 401 を返します。
2. **Python バージョンの不一致** — バンドルされた MCP サーバーは `uv run python` 経由で動作します。システムの Python が 3.12 未満の場合、`uv` が初回呼び出し時に新しいものを取得するため、初回は ~30 秒かかることがあります。

### `find_tools` が何も返さない

`find_tools` は Qdrant ベクトルインデックス上のセマンティック検索です。結果が空ということは：

- Qdrant に到達できない — `docker ps | grep qdrant` が健全と表示し、`curl http://localhost:6333/healthz` が 200 を返す必要があります。
- インデックスがまだ構築されていない — ゲートウェイは初回起動時にツール説明を取り込みます。1 分待ってから再試行してください。5 分経っても空のままの場合は再起動します：`nimbus stop && nimbus start`。

### `mcp.json` にサーバーを追加したのに表示されない

2 つの可能性があります：

1. **`mcp.json` の構文エラー** — ゲートウェイは不正な形式のエントリをサイレントにスキップします。以下で検証してください：
   ```bash
   nimbus mcp list
   ```
   新しいサーバーがリストにない場合、JSON が原因です。末尾のカンマやエスケープされていないバックスラッシュが定番の原因です。

2. **ゲートウェイがリロードされていない** — `mcp.json` はコンテナー起動時に読み込まれます。編集後：
   ```bash
   nimbus stop && nimbus start
   ```

HTTP サーバーの場合、URL はゲートウェイコンテナーの内側から到達可能である必要があります — ホストマシンの `localhost` は Docker 内の `localhost` とは *異なります*。代わりに `host.docker.internal:<port>` を使用してください。

---

## OpenRouter / モデルの問題

### 初めてのチャットで「Invalid API key」

CLI は最初の `nimbus start` で `OPENROUTER_API_KEY` を要求し、`~/.nimbus/.env` に書き込みます。このプロンプトをスキップしたか、キーが古い場合は：

```bash
nimbus config set OPENROUTER_API_KEYS sk-or-v1-...
nimbus stop && nimbus start
```

**複数形** に注意してください：`OPENROUTER_API_KEYS`（複数キー用にカンマ区切り、単数形へのフォールバックあり）。空のキー、または間違ったキープールでは、すべてのリクエストが `Authorization` ヘッダなしで送信され、プロバイダは 401 を返します。

### 特定のモデル ID で「Model not found」

Nimbus のデフォルトは `openrouter/free` です。`--model <id>` を渡したモデルが OpenRouter に存在しない場合、404 が返ります。モデル ID は [openrouter.ai/models](https://openrouter.ai/models) で確認してください — 頻繁に変更されます。

Ollama モデルの場合、ルーティングプレフィックスは `ollama/<model-name>`（例：`ollama/llama3.1`）です。プレフィックスなしのベア ID は OpenRouter とみなされます。

### 埋め込みの失敗

埋め込みのデフォルトは `nvidia/llama-nemotron-embed-vl-1b-v2:free`（2048-dim、フリーティア）です。このモデルが利用できない、またはレート制限されている場合は、フォールバックを設定してください：

```bash
nimbus config set EMBEDDING_MODEL openai/text-embedding-3-small
nimbus stop && nimbus start
```

これにより、次回起動時にすべてのツール説明が Qdrant に再取り込みされます — コールドキャッシュでは 1 分のインデックス作成時間を予期してください。

---

## 復旧

### 「Nimbus was installed by a different version」

以前のインストールが、`.env` と一致しなくなった認証情報で Postgres または Redis ボリュームを凍結したままだったことを意味します。修正は：

```bash
nimbus stop && nimbus start
```

`start` は不一致を自動検出し、現在の `.env` に対してロール / パスワードを再初期化します。古い `recover-pg-role` / `recover-redis-password` サブコマンドは廃止されました。

### すべてを消去してやり直す

```bash
nimbus uninstall
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
nimbus start
```

これで CLI、すべてのコンテナー、すべての名前付きボリューム、`~/.nimbus/` が削除されます。OAuth トークン、`.env`、Qdrant に保存されたツール説明は失われます。初回起動時に再認可してください。

### CLI の以前のバージョンにロールバックしたい

```bash
nimbus update --version v1.0.1
```

（または必要なバージョン。）CLI の自己更新は、`nimbus update` と同じアトミック置換 + SHA256 + minisign パスを、特定のリリースに固定して使用します。

---

## それでも解決しない？

[Nimbus トラッカー](https://github.com/Yoodule/nimbus/issues)に Issue を作成する際に、以下を添付してください：

- `nimbus doctor` の出力
- ホストのプラットフォームとアーキテクチャ（macOS / Linux では `uname -a`、Windows では `systeminfo`）
- 関連するコンテナーログ：`docker logs nimbus-gateway-1 --tail 200`（または `nimbus-postgres-1` / `nimbus-redis-1` / `nimbus-qdrant-1`）
- 関連しそうな `~/.nimbus/logs/` の内容

CLI は決して `.env` や OAuth トークンを送信しません —  redact はあなた自身で行う必要がありますが、それ以外の診断情報は共有しても安全です。
