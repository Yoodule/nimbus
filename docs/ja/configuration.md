# 設定

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  Nimbusは <code>~/.nimbus/.env</code> の環境変数で設定します。ほとんどの設定には安全なデフォルト値があり、以下は実際に触ることになる項目です。
</p>

## 登録モード

Nimbusは、たった1つの環境変数 `NIMBUS_SIGN_UP_MODE` によって `/sign-up` でのアカウント作成を制御します。デフォルトは admin-gated（管理者ゲート）モードで、最初の登録が管理者を作成し、その後の自己登録はロックされます。

### 3つのモード

| モード | 動作 | 主な用途 |
| --- | --- | --- |
| `first_user_only` *(デフォルト)* | 最初の登録が管理者を作成します。それ以降、`/sign-up` は `/sign-in` にリダイレクトされます。 | セルフホストのシングルオペレーター、社内ツール |
| `open` | 誰でも登録できます。新しいアカウントにはデフォルトロールが付与されます。 | 公開環境、マルチテナント SaaS |
| `closed` | 誰も登録できません。管理者は CLI / SQL / DB への直接挿入でユーザーを発行する必要があります。 | ロックダウン環境、デモ環境 |

デフォルトが `first_user_only` なのは、手動操作なしでブートストラップできる唯一のモードだからです。新規インストールは最初の登録を許可し（Better Auth の admin プラグインによって管理者になります）、その時点で閉じます。公開登録を有効にしたい場合は一度 `NIMBUS_SIGN_UP_MODE=open` を設定すれば、それ以降は登録を受け付け続けます。

### 変更方法

`nimbus config` CLI を使用してください — クォートの処理も自動で行われ、ファイルを手で編集する必要がない `~/.nimbus/.env` の薄いラッパーです：

```bash
nimbus config set NIMBUS_SIGN_UP_MODE open        # または "closed"、"first_user_only"
nimbus stop && nimbus start
```

3コマンドで完了します。ダッシュボードが次の起動時に新しい値を読み込むよう、再起動が必要です。

### 便利なサブコマンド

```bash
nimbus config get NIMBUS_SIGN_UP_MODE             # 現在の値を出力
nimbus config list                               # ~/.nimbus/.env のすべてのキーを表示
nimbus config unset NIMBUS_SIGN_UP_MODE          # 行を削除 → ランタイムデフォルトに戻る
```

### なぜデフォルトが admin-gated なのか

セルフホストソフトウェアは、「デフォルト = 公開登録」がセキュリティインシデントにつながる歴史を長く繰り返してきました。公開された `/sign-up` エンドポイントを持つ新規インストールは、公開から数分で公開アカウント発行マシンになります。Nimbus は 2026 年 8 月にデフォルトを `first_user_only` に切り替えることでこの問題を塞ぎました — インストールはきれいにブートストラップされ（最初の登録がオペレーターの管理者になり）、以降の自己登録はオペレーターが `NIMBUS_SIGN_UP_MODE=open` を選択しない限りロックされます。

モードを切り替えずにチームメンバーを追加するには、2つの選択肢があります：

- 一時的に環境変数を `open` に変更し、再起動して `/sign-up` を共有し、その方の登録が終わったら `first_user_only` に戻します。
- `user` テーブルに直接行を挿入します — スキーマは `dashboard/src/lib/db/pg/schema.pg.ts` にあります。挿入前に Better Auth の `scrypt`（`node:crypto scrypt` を使用し、`@noble/hashes` がフォールバック）でパスワードをハッシュ化してください。

### 現在のモードの確認

ダッシュボードのログインページは、登録が許可されているときに「Sign up」フッターを表示します。フッターが見えるなら、登録がオープンであるか、新規インストールの最初のユーザーです。フッターが見えないなら、既存ユーザーがいる closed-mode のインストールです。

生の値を確認するには `nimbus config get NIMBUS_SIGN_UP_MODE` を実行します — または `nimbus config list` ですべてのキーを一度に表示できます。