# 配置

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  Nimbus 通过 <code>~/.nimbus/.env</code> 中的环境变量进行配置。多数设置都有安全的默认值，下面列出的是你真正会修改的那些。
</p>

## 注册模式

Nimbus 通过单个环境变量 `NIMBUS_SIGN_UP_MODE` 控制哪些人可以通过 `/sign-up` 创建账户。默认值为 admin-gated（管理员门控）模式：第一次注册创建管理员，然后自助注册被锁定。

### 三种模式

| 模式 | 行为 | 典型用例 |
| --- | --- | --- |
| `first_user_only` *(默认)* | 第一次注册创建管理员。之后，`/sign-up` 重定向到 `/sign-in`。 | 自托管单人运维安装、内部公司工具 |
| `open` | 任何人都可以注册。新账户获得默认角色。 | 面向公网的部署、多租户 SaaS |
| `closed` | 没有人可以注册。管理员必须通过 CLI / SQL / 直接插入数据库来创建用户。 | 锁定的环境、演示安装 |

默认值是 `first_user_only`，因为它是唯一可以无需手动干预就能完成引导的模式：新安装接受第一次注册（通过 Better Auth 的 admin 插件成为管理员），然后关闭。想要开放注册的运维人员只需设置一次 `NIMBUS_SIGN_UP_MODE=open`，之后安装就会持续接受注册。

### 如何修改

使用 `nimbus config` CLI —— 它是 `~/.nimbus/.env` 的轻量封装，自动处理引号，无需手动编辑文件：

```bash
nimbus config set NIMBUS_SIGN_UP_MODE open        # 或 "closed"，或 "first_user_only"
nimbus stop && nimbus start
```

三步搞定。需要重启，让仪表板在下次启动时加载新值。

### 实用子命令

```bash
nimbus config get NIMBUS_SIGN_UP_MODE             # 打印当前值
nimbus config list                               # 显示 ~/.nimbus/.env 中的所有键
nimbus config unset NIMBUS_SIGN_UP_MODE          # 清除该行 → 恢复为运行时默认值
```

### 为什么默认是 admin-gated

自托管软件有着"默认 = 开放注册"导致安全事故的悠久历史：带有开放 `/sign-up` 端点的新安装，在上线后几分钟内就会变成公开的账户铸造机。Nimbus 在 2026 年 8 月通过将默认值切换为 `first_user_only` 堵住了这个漏洞 —— 安装能够干净地完成引导（运维人员的第一次注册成为管理员），从那一刻起，自助注册即被锁定，除非运维人员通过 `NIMBUS_SIGN_UP_MODE=open` 主动选择开放。

如果不想切换模式就添加团队成员，有两种选择：

- 把环境变量临时改为 `open`，重启，分享 `/sign-up`，等对方注册完成后改回 `first_user_only`。
- 直接向 `user` 表插入行 —— 模式定义在 `dashboard/src/lib/db/pg/schema.pg.ts` 中。插入前先用 Better Auth 的 `scrypt`（使用 `node:crypto scrypt`，`@noble/hashes` 作为回退）对密码进行哈希。

### 验证当前模式

仪表板的登录页在允许注册时会显示 "Sign up" 页脚。如果看到了页脚，说明注册已开放，或者你是新安装的第一个用户。如果没看到，说明这是一个已有用户存在的 closed-mode 安装。

查看原始值，运行 `nimbus config get NIMBUS_SIGN_UP_MODE` —— 或者用 `nimbus config list` 一次性查看所有键。