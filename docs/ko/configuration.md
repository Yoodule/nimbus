# 설정

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  Nimbus는 <code>~/.nimbus/.env</code>의 환경 변수를 통해 설정합니다. 대부분의 설정은 안전한 기본값을 가지고 있으며, 아래는 실제로 손대게 될 설정들입니다.
</p>

## 가입 모드

Nimbus는 단일 환경 변수 `NIMBUS_SIGN_UP_MODE`를 통해 `/sign-up`을 통한 계정 생성을 제어합니다. 기본값은 admin-gated(관리자 게이트) 모드입니다. 첫 번째 가입이 관리자를 생성하면, 이후 자기 등록은 잠깁니다.

### 세 가지 모드

| 모드 | 동작 | 일반적인 사용 사례 |
| --- | --- | --- |
| `first_user_only` *(기본값)* | 첫 번째 가입이 관리자를 생성합니다. 이후에 `/sign-up`은 `/sign-in`으로 리디렉션됩니다. | 자체 호스팅 단일 운영자 설치, 사내 도구 |
| `open` | 누구나 가입할 수 있습니다. 새 계정은 기본 역할을 받습니다. | 공개용 배포, 다중 테넌트 SaaS |
| `closed` | 아무도 가입할 수 없습니다. 관리자는 CLI / SQL / 직접 DB 삽입을 통해 사용자를 발급해야 합니다. | 잠긴 환경, 데모 설치 |

기본값이 `first_user_only`인 이유는, 수동 개입 없이 부트스트랩할 수 있는 유일한 모드이기 때문입니다. 신규 설치는 첫 번째 가입을 받아들이고 (Better Auth의 admin 플러그인을 통해 관리자가 됨), 그다음 닫힙니다. 공개 등록을 원하는 운영자는 한 번 `NIMBUS_SIGN_UP_MODE=open`으로 설정하면 그 이후로 계속 가입을 받습니다.

### 변경 방법

`nimbus config` CLI를 사용하세요 — 따옴표 처리도 자동으로 되고, 파일을 직접 손댈 필요가 없는 `~/.nimbus/.env` 래퍼입니다:

```bash
nimbus config set NIMBUS_SIGN_UP_MODE open        # 또는 "closed", 또는 "first_user_only"
nimbus stop && nimbus start
```

세 줄이면 충분합니다. 대시보드가 다음 부팅 시 새 값을 읽도록 재시작이 필요합니다.

### 유용한 하위 명령

```bash
nimbus config get NIMBUS_SIGN_UP_MODE             # 현재 값 출력
nimbus config list                               # ~/.nimbus/.env의 모든 키 표시
nimbus config unset NIMBUS_SIGN_UP_MODE          # 라인 제거 → 런타임 기본값으로 복귀
```

### 기본값이 admin-gated인 이유

자체 호스팅 소프트웨어는 "기본값 = 공개 등록"이 보안 사고로 이어진 오랜 역사를 가지고 있습니다. 공개된 `/sign-up` 엔드포인트가 있는 신규 설치는 공개된 후 몇 분 만에 공개 계정 발급 머신이 됩니다. Nimbus는 2026년 8월에 기본값을 `first_user_only`로 전환하여 이 문제를 차단했습니다 — 설치가 깔끔하게 부트스트랩되고 (운영자의 첫 번째 가입이 관리자가 됨), 그 시점부터는 운영자가 `NIMBUS_SIGN_UP_MODE=open`을 명시적으로 선택하지 않는 한 자기 등록이 잠깁니다.

모드를 전환하지 않고 팀원을 추가하려면 두 가지 방법이 있습니다:

- 환경 변수를 `open`으로 바꾸고, 재시작하고, `/sign-up`을 공유한 다음, 가입이 끝난 후 다시 `first_user_only`로 돌려놓습니다.
- `user` 테이블에 직접 행을 삽입합니다 — 스키마는 `dashboard/src/lib/db/pg/schema.pg.ts`에 있습니다. 삽입 전에 Better Auth의 `scrypt` (`node:crypto scrypt` 사용, `@noble/hashes`가 폴백)로 비밀번호를 해시하세요.

### 현재 모드 확인

대시보드의 로그인 페이지는 등록이 허용될 때마다 "Sign up" 푸터를 표시합니다. 푸터가 보이면 가입이 열려 있거나, 빈 설치의 첫 번째 사용자입니다. 보이지 않는다면, 기존 사용자가 있는 closed-mode 설치입니다.

원시 값을 보려면 `nimbus config get NIMBUS_SIGN_UP_MODE`을 실행하세요 — 또는 `nimbus config list`로 모든 키를 한 번에 볼 수 있습니다.