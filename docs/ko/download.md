# Nimbus 다운로드

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  프로덕션 AI 에이전트를 위한 통합 MCP 게이트웨이. 한 줄의 명령으로 CLI, 게이트웨이, 그리고 모든 번들 MCP 서버를 설치합니다 — SHA256 검증, 가입 불필요, 로컬 실행.
</p>

<div class="prereq-callout" markdown="1">

**사전 요구 사항:** Nimbus를 설치하기 전에 <a href="https://www.docker.com/products/docker-desktop/" target="_blank">Docker Desktop</a> (또는 Mac에서는 <a href="https://orbstack.dev/" target="_blank">OrbStack</a>) 이 설치되어 **실행 중**이어야 합니다. 설치는 무료이며 몇 분이면 끝납니다.

**빠른 확인 — 먼저 실행해 보세요.**

```bash
docker ps
```

`CONTAINER ID` 표 (또는 "no containers" 행)가 보이면 Docker가 실행 중이며 바로 진행할 수 있습니다. `Cannot connect to the Docker daemon` 이 보이면 Docker Desktop (macOS / Windows) 을 시작하거나 (Linux) `sudo systemctl start docker` 를 실행한 뒤 다시 시도하세요.

</div>

## 플랫폼별 설치

=== "macOS"

    Apple Silicon & Intel. macOS 12 Monterey 이상이 필요합니다.

    **최신 버전 설치:**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    설치 스크립트가 Apple Silicon과 Intel을 자동으로 감지하고 게시된 SHA256SUMS 로 검증합니다.

    직접 다운로드:

    - [Apple Silicon (M1/M2/M3/M4) →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-arm64.tar.gz)
    - [Intel Mac →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-darwin-amd64.tar.gz)

    **시스템 요구 사항:**

    - **OS:** macOS 12 Monterey 이상 (Apple Silicon 또는 Intel)
    - **Docker:** Docker Desktop 4.x+ 또는 [OrbStack](https://orbstack.dev/) — 데몬이 실행 중이어야 함
    - **Python:** 3.12+ (없을 경우 [`uv`](https://astral.sh/uv) 로 자동 설치)
    - **디스크:** CLI 약 30 MB, Docker 이미지 풀 후 약 2 GB
    - **메모리:** 최소 4 GB, 권장 8 GB

    **특정 버전 고정:**

    `curl` 이 변수를 보지 않고 설치 스크립트에만 전달되도록, 파이프의 오른쪽에 `NIMBUS_VERSION` 을 설정하세요.

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Linux"

    x86_64 & aarch64. Ubuntu 22.04+, Debian 12+, Fedora 39+, Arch에서 테스트되었습니다.

    **최신 버전 설치:**

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | bash
    ```

    직접 다운로드:

    - [x86_64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-amd64.tar.gz)
    - [aarch64 →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-linux-arm64.tar.gz)

    **시스템 요구 사항:**

    - **OS:** glibc 2.31+ (Ubuntu 22.04, Debian 12, Fedora 39, Arch)
    - **Docker:** Docker Desktop 4.x+, [OrbStack](https://orbstack.dev/), 또는 헤드리스 Docker Engine — 데몬이 실행 중이어야 함
    - **Python:** 3.12+ (없을 경우 [`uv`](https://astral.sh/uv) 로 자동 설치)
    - **디스크:** CLI 약 30 MB, Docker 이미지 풀 후 약 2 GB
    - **메모리:** 최소 4 GB, 권장 8 GB

    **특정 버전 고정:**

    `curl` 이 변수를 보지 않고 설치 스크립트에만 전달되도록, 파이프의 오른쪽에 `NIMBUS_VERSION` 을 설정하세요.

    ```bash
    curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.3 bash
    ```

=== "Windows"

    PowerShell & WSL2. 관리자 권한은 필요하지 않습니다. 설치 프로그램이 PATH 설정을 처리하고 사용자 프로필에 Nimbus를 등록합니다.

    **최신 버전 설치:**

    ```powershell
    irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

    직접 다운로드:

    - [원클릭: install.cmd 실행 →](https://nimbus.yoodule.com/install.cmd)
    - [Windows (x64) →](https://github.com/Yoodule/nimbus/releases/latest/download/nimbus-windows-amd64.tar.gz)

    **시스템 요구 사항:**

    - **OS:** Windows 10 빌드 19041+ 또는 WSL2가 활성화된 Windows 11
    - **Docker:** Docker Desktop 4.x+ (WSL2 백엔드) — 데몬이 실행 중이어야 함
    - **Python:** 3.12+ (없을 경우 [`uv`](https://astral.sh/uv) 로 자동 설치)
    - **디스크:** CLI 약 30 MB, Docker 이미지 풀 후 약 2 GB
    - **메모리:** 최소 4 GB, 권장 8 GB (Qdrant + Docker)

    **특정 버전 고정:**

    설치 프로그램을 실행하기 전에 셸에 `NIMBUS_VERSION` 을 설정하세요 (설치 스크립트로 변수가 전달되도록).

    ```powershell
    $env:NIMBUS_VERSION = "v1.0.3"; irm https://nimbus.yoodule.com/install.ps1 | iex
    ```

---

[releases 페이지](https://github.com/Yoodule/nimbus/releases) 에서 게시된 모든 버전을 확인하세요.

---

## 설치 전 검증

모든 릴리스에는 `SHA256SUMS` 파일이 함께 제공됩니다. 설치 프로그램이 자동으로 체크섬을 확인합니다. 직접 확인하려면 [releases 페이지](https://github.com/Yoodule/nimbus/releases) 에서 파일을 받아 실행하세요.

```bash
sha256sum -c --strict SHA256SUMS
```

모든 릴리스는 GitHub Actions로 SLSA 증명됩니다. [releases 페이지](https://github.com/Yoodule/nimbus/releases) 에서 증명을 확인할 수 있습니다.

---

## 업그레이드

CLI는 자체적으로 제자리 업그레이드됩니다. `mcp.json`, `.env`, OAuth 토큰, Qdrant 인덱스는 보존됩니다.

```bash
nimbus upgrade
```

특정 버전으로 업그레이드:

```bash
nimbus upgrade --version v1.0.3
```

---

## 제거

CLI, 게이트웨이, 로컬 Docker 스택, 설치 디렉터리를 한 번에 제거합니다.

```bash
nimbus uninstall
```

재설치를 위해 설정 (`mcp.json`, `.env`, 토큰) 을 보존하려면 `--keep-config` 를 전달하세요.

```bash
nimbus uninstall --keep-config
```

---

## 설치되는 항목

설치 프로그램은 모든 것을 `~/.nimbus/` (또는 `NIMBUS_HOME` 을 설정한 경우 `$NIMBUS_HOME`) 아래에 작성합니다.

```
~/.nimbus/
├── nimbus                # CLI shim
├── nimbus-gateway-*      # 컴파일된 게이트웨이 바이너리
├── mcp.json              # 서버 레지스트리
├── servers/              # 번들된 MCP 서버
├── .env                  # 로컬 설정 (OPENROUTER_API_KEY, QDRANT_URL, …)
└── logs/                 # 런타임 로그
```

또한 셸 설정 파일 (`~/.zshrc`, `~/.bashrc`, Windows에서는 `$PROFILE`) 에 `export NIMBUS_HOME` 과 `PATH` 를 추가해 새 셸에서도 `nimbus` 가 PATH에 잡히도록 합니다.

---

## FAQ

### Apple Silicon Mac에서 설치 프로그램이 "arm64 not found" 라고 합니다.

오래된 설치 프로그램의 메시지입니다. `nimbus upgrade` 로 최신 버전을 받거나, 스크립트를 직접 새로 받아 실행하세요.

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

현재 설치 프로그램은 GitHub의 CDN 리디렉션을 따르고 아키텍처를 감지합니다. 자산이 실제로 누락된 경우에만 즉시 실패하며 어떤 자산이 문제인지 명확한 오류로 알려줍니다.

### Docker 없이 설치할 수 있나요?

가능합니다. CLI와 게이트웨이는 네이티브로 실행됩니다. 번들된 MCP 스택 (Playwright 브라우저, Postgres 에이전트 DB, Qdrant) 은 Docker를 사용하지만 `nimbus start --no-deps` 로 건너뛰고 대신 `mcp.json` 으로 원격 MCP 서버를 가리키도록 구성할 수 있습니다.

### 다운로드 크기는 얼마인가요?

CLI 타르볼은 압축 상태로 약 30 MB입니다. 첫 시작 시 Docker 이미지를 추가로 약 2 GB 가져옵니다 (Qdrant, Playwright, Postgres). 대역폭이 제한적인 경우 `--no-deps` 시작 모드로 Docker 풀을 건너뛸 수 있습니다.

### OAuth 토큰은 어디에 저장되나요?

기본적으로는 메모리에만 존재 — 재시작 시 다시 승인해야 합니다. `~/.nimbus/.env` 에 `NIMBUS_PERSIST_TOKENS=1` 을 설정하면 `~/.nimbus/tokens/` 아래에 암호화되어 저장됩니다.

### Apple Silicon에서 Rosetta로 동작하나요?

네 — 설치 명령 전에 `NIMBUS_HOST_ARCH=amd64` 를 설정하면 Intel 빌드를 받습니다. 게이트키퍼 도구로 인해 60 MB 이상 늘어나는 데 비해 소수의 사용자에게만 해당하므로 유니버설 바이너리는 제공하지 않습니다. Rosetta가 투명하게 처리합니다.

### 한 호스트에서 Nimbus 인스턴스를 여러 개 실행하려면?

Nimbus는 고정 호스트 포트 (`3000`, `8088`, `6333`, `5433`, `6080`, `8006`, `8007`, `8081`) 에 바인딩하므로 기본 설치는 단일 인스턴스입니다. 두 번째 인스턴스를 실행하려면 저장소를 클론하고 `compose.yaml` 에서 포트를 재매핑한 뒤, 고유한 `NIMBUS_HOME` 을 설정하고, 두 스택이 충돌하지 않도록 `COMPOSE_PROJECT_NAME` 을 설정하세요. 자세한 내용은 아래 [다중 인스턴스 섹션](#how-do-i-run-multiple-nimbus-instances-on-the-same-host) 을 참고하세요.

### 설치가 멈추거나 curl 이 실패합니다 — 어떻게 하나요?

가장 흔한 원인은 회사 프록시가 TLS를 가로채는 경우입니다. `HTTPS_PROXY` 를 설정하고 다시 시도하세요. CDN 자체가 문제라면 설치 스크립트가 알려진 정상 릴리스를 고정할 수 있도록 `NIMBUS_VERSION` 을 받아들이며, [releases 페이지](https://github.com/Yoodule/nimbus/releases) 에서 타르볼을 직접 받아 `~/.nimbus/` 에 풀어 놓을 수도 있습니다 — 바이너리는 자체 완결형입니다.

---

<div style="text-align: center; margin: 48px 0 24px 0; padding: 32px; background: #0a0a0a; border: 1px solid #262626; border-radius: 12px;">
  <p style="color: #a3a3a3; font-size: 1.05em; margin: 0 0 16px 0;">
    가이드가 함께하는 설정을 원하시나요? 1:1 온보딩 세션을 예약하시면 워크스페이스를 함께 살펴드립니다.
  </p>
  <a href="https://calendly.com/sundayj/30min" target="_blank" style="display: inline-flex; align-items: center; gap: 8px; background: #ffffff; color: #000000; text-decoration: none; font-weight: 600; padding: 12px 24px; border-radius: 8px; font-size: 1em;">
    온보딩 세션 예약 →
  </a>
</div>
