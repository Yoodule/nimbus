# 문제 해결

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  <code>nimbus</code> 가 기대대로 동작하지 않으면 <code>nimbus doctor</code> 부터 시작하세요. Docker 접근성, CLI/게이트웨이 버전 차이, 컨테이너 상태, 설치가 최신 릴리스에서 뒤처졌는지 여부를 다루는 상태 대시보드를 출력합니다. 대부분의 문제는 여기서 드러납니다.
</p>

`doctor` 가 증상을 다루고 있지 않다면, 아래 섹션은 의심되는 컴포넌트가 아니라 **볼 수 있는 증상** 별로 정리되어 있습니다. 가장 가까운 항목을 고르세요.

---

## 여기서부터: `nimbus doctor`

```bash
nimbus doctor
```

네 가지를 확인하고 각 검사마다 한 줄을 출력합니다:

- **Docker 프로브** — 데몬에 접근할 수 있는가? 새 머신이 `nimbus start` 가 곧 실패할 때쯤 거짓으로 "모두 정상"을 보지 않도록 가장 먼저 실행됩니다.
- **CLI / 게이트웨이 차이** — 실행 중인 게이트웨이 컨테이너가 CLI 보다 한 단계 이상의 마이너 버전 뒤처져 있는가? 차이가 나는 CLI 는 경고는 띄우지만 시작을 거부하지는 않습니다.
- **컨테이너 상태** — gateway, postgres, redis, qdrant 컨테이너가 정상인가?
- **업데이트 신선도** — GitHub 에 더 새로운 릴리스가 있는가? (내장된 minisign 공개키가 placeholder 인 dev 빌드에서는 건너뜁니다.)

종료 코드는 항상 `0` 입니다 — `doctor` 는 실패하지 않으며, CI 와 모니터링에서 상태 체크로 사용할 수 있도록 경고만 표시합니다.

---

## 설치 문제

### 설치 후 `nimbus` 가 `PATH` 에 없습니다

설치 프로그램은 `export NIMBUS_HOME=~/.nimbus` 와 `PATH` 변경을 `~/.zshrc`, `~/.bashrc`, Windows 의 `$PROFILE` 에 기록합니다. 새 셸을 열거나 현재 셸에서 rc 를 `source` 하세요:

```bash
# macOS / Linux — 실제로 사용하는 셸을 선택
source ~/.zshrc
source ~/.bashrc
```

그래도 `nimbus` 가 없으면 설치가 조용히 실패한 것일 수 있습니다. 설치 로그(성공한 실행의 끝에 경로가 출력됩니다)를 확인하고 명시적인 스크립트로 다시 실행하세요:

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

### Apple Silicon 에서 "arm64 not found" 가 표시됩니다

이 메시지는 오래된 설치 프로그램에서 나옵니다. 스크립트의 새 복사본을 받아 다시 실행하세요:

```bash
curl -fsSL https://raw.githubusercontent.com/Yoodule/nimbus/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

현재 설치 프로그램은 GitHub 의 CDN 리디렉션을 따르고, `uname -m` 으로 아키텍처를 감지하며, 자산이 정말 없을 때는 즉시 actionable 오류로 실패합니다.

### 설치가 멈추거나 `curl` 이 실패합니다

가장 흔한 원인은 TLS 를 가로채는 회사 프록시입니다:

```bash
HTTPS_PROXY=http://your-proxy:port curl -fsSL https://nimbus.yoodule.com/install.sh | bash
```

CDN 자체가 문제라면 `NIMBUS_VERSION` 으로 검증된 버전을 고정하세요:

```bash
curl -fsSL https://nimbus.yoodule.com/install.sh | NIMBUS_VERSION=v1.0.2 bash
```

[releases 페이지](https://github.com/Yoodule/nimbus/releases) 에서 tarball 을 직접 받아 `~/.nimbus/` 에 직접 풀어도 됩니다 — 바이너리는 self-contained 입니다.

### 설치는 성공했지만 `nimbus start` 가 Docker 에 접근할 수 없다고 합니다

Docker 는 설치돼 있지만 데몬이 실행 중이지 않습니다. 시작하세요:

- **macOS / Windows** — Docker Desktop (또는 OrbStack) 을 엽니다. 메뉴 바의 고래 아이콘이 애니메이션이 아닌 고정 상태여야 합니다.
- **Linux** — `sudo systemctl start docker`, systemd 가 아니면 `sudo dockerd`.

`docker ps` 로 확인하세요. `Cannot connect to the Docker daemon` 이 보이면 데몬이 아직 준비되지 않은 것입니다 — 잠시 기다렸다가 다시 시도하세요.

---

## 컨테이너 문제

### 컨테이너가 계속 재시작됩니다

`docker ps` 에서 한 컨테이너가 `Restarting` 상태입니다. 가장 흔한 원인은 이전 `.env` 에서 남은 오래된 볼륨입니다:

```bash
docker logs nimbus-gateway-1 --tail 100    # 또는 nimbus-postgres-1 / nimbus-redis-1 / nimbus-qdrant-1
```

구체적인 에러를 찾으세요. Postgres 나 Redis 인증 실패라면 `.env` 의 자격 증명은 회전했지만 명명된 볼륨에는 이전 값이 남아 있는 것입니다. 복구:

```bash
nimbus stop
# 오래된 볼륨을 옆으로 옮겨 init 가 깨끗하게 다시 실행되도록 합니다.
# nimbus start 는 새 볼륨에서 새 자격 증명을 자동 생성합니다;
# 기존 볼륨은 -corrupt-<timestamp> 로 보존되어 필요 시 확인할 수 있습니다.
docker volume rm nimbus_postgres_data
nimbus start
```

이전 `nimbus recover-pg-role` / `nimbus recover-redis-password` 서브커맨드는 더 이상 존재하지 않습니다 — 이 흐름이 지원되는 복구 경로입니다.

### `nimbus start` 가 "port already in use" 라고 합니다

Nimbus 는 고정 호스트 포트 (3000 dashboard, 8088 gateway, 6080 noVNC, 5433 postgres, 6379 redis, 6333/6334 qdrant) 를 바인딩합니다. 호스트의 다른 프로세스가 이 포트 중 하나를 이미 점유하고 있으면 `start` 가 충돌 포트 번호를 명시하며 실패합니다.

충돌하는 프로세스를 찾아 종료하세요:

```bash
# macOS / Linux
sudo lsof -iTCP:8088 -sTCP:LISTEN
```

장기적인 다중 인스턴스 구성은 [다운로드 페이지](download.md#how-do-i-run-multiple-nimbus-instances-on-the-same-host) 의 **다중 인스턴스** 섹션을 참고하세요.

### 대시보드가 "gateway unreachable" 라고 합니다

대시보드는 `http://localhost:3000` 에서 실행됩니다. 로딩은 되지만 모든 동작이 "gateway unreachable" 을 반환한다면 게이트웨이 컨테이너가 실제로 8088 에서 수신 대기 중이 아닙니다. 확인:

```bash
docker ps | grep gateway
docker logs nimbus-gateway-1 --tail 50
curl -s http://localhost:8088/version
```

Apple Silicon + Rosetta 에서 흔한 원인은 플랫폼 불일치입니다 — 게이트웨이 이미지는 `linux/arm64` 인데 런타임이 `amd64` 를 요구합니다. `nimbus start` 전에 `NIMBUS_HOST_ARCH=arm64` 를 설정하세요.

---

## OAuth 문제

### Approve 를 클릭했을 때 "OAuth callback failed"

기본적으로 게이트웨이는 OAuth 콜백을 `http://localhost:8088/oauth/callback` 으로 착지시키려 합니다. 터널 뒤나 원격 브라우저에서 Nimbus 를 실행 중이라면, 등록된 URL 과 일치하지 않아 공급자가 콜백을 거부합니다.

해결책은 `NIMBUS_URL` (대시보드의 OAuth 프록시가 사용) 과 `OAUTH_REDIRECT_BASE` (게이트웨이가 사용) 를 공급자가 리디렉션해야 할 공개 URL 로 설정하는 것입니다. 둘 다 [`.env.example`](https://github.com/Yoodule/nimbus/blob/main/.env.example) 에 문서화돼 있습니다.

### Upwork OAuth: "redirect_uri_mismatch"

Upwork 의 OAuth 공급자는 `redirect_uri` 의 정확한 일치를 엄격히 요구합니다. 설치 프로그램의 `UPWORK_REDIRECT_URI` 는 Upwork 개발자 콘솔에 등록된 값과 — 마지막 슬래시까지 포함해 — 한 글자도 다르지 않아야 합니다.

`redirect_uri_mismatch` 가 보이면 `~/.nimbus/.env` 의 값을 확인하세요:

```bash
nimbus config get UPWORK_REDIRECT_URI
```

…그리고 Upwork 콘솔 값과 바이트 단위로 비교하세요. 수정 후 게이트웨이 컨테이너를 재시작합니다:

```bash
nimbus stop && nimbus start
```

### 재시작 후 토큰이 사라집니다

의도된 동작입니다. 기본적으로 OAuth 토큰은 메모리에만 존재하며, 매 재시작이 새로운 재승인을 의미합니다. 공유 / 다중 사용자 호스트에서 더 안전한 기본값이기 때문입니다.

---

## MCP 서버 문제

### 번들된 MCP 서버가 시작되지 않습니다

`docker logs nimbus-gateway-1 --tail 200` 에서 import 오류나 환경 변수 누락으로 stdio 서브프로세스가 죽는 모습이 보일 겁니다. 흔한 두 가지 원인:

1. **API 키 누락** — `~/.nimbus/.env` 에서 관련 `*_API_KEYS` (복수형, 쉼표로 구분) 를 확인하세요. 게이트웨이와 대시보드는 모두 복수형을 읽고 단수형으로 폴백합니다. 풀이 비어 있으면 ⇒ 공급자가 401 을 반환합니다.
2. **Python 버전 차이** — 번들된 MCP 서버는 `uv run python` 으로 실행됩니다. 시스템 Python 이 3.12 보다 낮으면 `uv` 가 첫 호출 시 더 높은 버전을 가져오며, 첫 호출은 ~30 초 걸릴 수 있습니다.

### `find_tools` 가 아무것도 반환하지 않습니다

`find_tools` 는 Qdrant 벡터 인덱스에 대한 시맨틱 검색입니다. 결과가 비어 있다면:

- Qdrant 에 접근할 수 없음 — `docker ps | grep qdrant` 가 healthy 로 표시되고, `curl http://localhost:6333/healthz` 가 200 을 반환해야 합니다.
- 인덱스가 아직 구축되지 않음 — 게이트웨이는 첫 시작 시 도구 설명을 수집합니다. 1 분 정도 기다린 뒤 다시 시도하세요. 5 분이 지나도 계속 비어 있으면 재시작: `nimbus stop && nimbus start`.

### `mcp.json` 에 서버를 추가했는데 표시되지 않습니다

두 가지 가능성이 있습니다:

1. **`mcp.json` 의 구문 오류** — 게이트웨이는 잘못된 형식의 항목을 조용히 건너뜁니다. 다음으로 검증:
   ```bash
   nimbus mcp list
   ```
   새 서버가 목록에 없다면 JSON 문제입니다. 마지막 쉼표나 이스케이프되지 않은 백슬래시가 흔한 원인입니다.

2. **게이트웨이가 리로드되지 않음** — `mcp.json` 은 컨테이너 시작 시 읽힙니다. 수정 후:
   ```bash
   nimbus stop && nimbus start
   ```

HTTP 서버의 경우 URL 은 게이트웨이 컨테이너 내부에서 접근 가능해야 합니다 — 호스트의 `localhost` 는 Docker 내부의 `localhost` 와 *같지 않습니다*. 대신 `host.docker.internal:<port>` 를 사용하세요.

---

## OpenRouter / 모델 문제

### 첫 채팅에서 "Invalid API key"

CLI 는 첫 `nimbus start` 시 `OPENROUTER_API_KEY` 를 입력받고 `~/.nimbus/.env` 에 기록합니다. 그 프롬프트를 건너뛰었거나 키가 오래되었다면:

```bash
nimbus config set OPENROUTER_API_KEYS sk-or-v1-...
nimbus stop && nimbus start
```

**복수형** 임에 주의하세요: `OPENROUTER_API_KEYS` (복수 키는 쉼표로 구분, 단수형으로 폴백). 비어 있거나 잘못된 키 풀은 모든 요청을 `Authorization` 헤더 없이 보내게 만들어 공급자가 401 을 반환합니다.

### 특정 모델 ID 에서 "Model not found"

Nimbus 의 기본값은 `openrouter/free` 입니다. `--model <id>` 를 전달했는데 해당 모델이 OpenRouter 에 존재하지 않으면 404 가 옵니다. [openrouter.ai/models](https://openrouter.ai/models) 에서 모델 ID 를 확인하세요 — 자주 바뀝니다.

Ollama 모델의 경우 라우팅 접두사는 `ollama/<model-name>` 입니다 (예: `ollama/llama3.1`). 접두사 없는 bare ID 는 OpenRouter 로 간주됩니다.

### 임베딩 실패

임베딩의 기본값은 `nvidia/llama-nemotron-embed-vl-1b-v2:free` (2048-dim, 무료 등급) 입니다. 이 모델을 사용할 수 없거나 rate limit 이 걸렸다면 폴백을 설정하세요:

```bash
nimbus config set EMBEDDING_MODEL openai/text-embedding-3-small
nimbus stop && nimbus start
```

다음 시작 시 모든 도구 설명이 Qdrant 에 재수집됩니다 — 콜드 캐시에서는 1 분 정도의 인덱싱 시간을 예상하세요.

---

## 복구

### "Nimbus was installed by a different version"

이전 설치가 `.env` 와 더 이상 맞지 않는 자격 증명으로 Postgres / Redis 볼륨을 동결시켜 둔 경우입니다. 해결책:

```bash
nimbus stop && nimbus start
```

`start` 가 불일치를 자동 감지하고 현재 `.env` 에 맞게 role/password 를 재초기화합니다. 이전 `recover-pg-role` / `recover-redis-password` 서브커맨드는 더 이상 없습니다.

### 모두 지우고 처음부터 다시 시작

```bash
nimbus uninstall
curl -fsSL https://nimbus.yoodule.com/install.sh | bash
nimbus start
```

이 명령은 CLI, 모든 컨테이너, 모든 명명된 볼륨, `~/.nimbus/` 를 제거합니다. OAuth 토큰, `.env`, Qdrant 에 저장된 도구 설명을 잃게 됩니다. 첫 실행 시 재승인하세요.

### CLI 의 이전 버전으로 롤백하고 싶습니다

```bash
nimbus update --version v1.0.1
```

(필요한 버전을 지정하세요.) CLI 자체 업데이트는 `nimbus update` 와 같은 atomic replace + SHA256 + minisign 경로를 특정 릴리스에 고정한 방식으로 사용합니다.

---

## 여전히 막혔나요?

[Nimbus 트래커](https://github.com/Yoodule/nimbus/issues) 에 다음 내용과 함께 이슈를 열어주세요:

- `nimbus doctor` 출력
- 호스트 플랫폼과 아키텍처 (macOS / Linux 는 `uname -a`, Windows 는 `systeminfo`)
- 관련 컨테이너 로그: `docker logs nimbus-gateway-1 --tail 200` (또는 `nimbus-postgres-1` / `nimbus-redis-1` / `nimbus-qdrant-1`)
- 관련 있을 만한 `~/.nimbus/logs/` 의 모든 항목

CLI 는 `.env` 나 OAuth 토큰을 절대 전송하지 않습니다 — redact 는 직접 해야 하지만, 다른 진단 정보는 공유해도 안전합니다.
