# Nimbus Cloud

<p style="color: #a3a3a3; font-size: 1.1em; margin: -8px 0 32px 0;">
  Managed Nimbus — 운영은 우리가, 결과는 사용자가.
</p>

---

## 제공 내용

- **몇 달이 아닌 며칠 만에 출시하세요.** 24시간 안에 Nimbus 인스턴스를 프로비저닝해 드립니다. 팀은 인프라가 아닌 워크플로에 집중할 수 있습니다.
- **주 10시간을 되찾아 오세요.** 패치, Docker 업그레이드, 스택 온콜 로테이션이 없습니다 — 팀은 자신만 할 수 있는 일에 집중합니다.
- **장애 대응은 우리가 합니다.** 24/7 모니터링하며 사람의 판단이 필요한 순간에만 사용자를 깨웁니다.
- **다운타임 없이 업그레이드.** 새 Nimbus 버전이 무중단으로 배포되며 모든 변경에 사용자가 승인합니다.

---

## 동작 방식

1. **가입.** 적합성과 범위를 확인하는 15분 통화.
2. **프로비저닝.** 사용자 리전에 전용 Nimbus 인스턴스를 만들고 MCP 서버와 OAuth 연결을 구성합니다.
3. **도구 연결.** 동일한 Nimbus, 동일한 MCP 서버 — 사용자가 새로 배울 것은 없습니다.

---

## 요금

워크로드당 과금되며 사용량에 따라 확장됩니다. 팀마다 사용 규모가 다르므로 견적제로 운영합니다.

<div style="margin: 16px 0 0 0;">
  <a href="https://calendly.com/sundayj/30min" target="_blank" style="display: inline-flex; align-items: center; gap: 8px; background: #ffffff; color: #000000; text-decoration: none; font-weight: 600; padding: 12px 24px; border-radius: 8px; font-size: 1em;">
    견적 문의하기 →
  </a>
</div>

---

## 보안 & SLA

- 전송 중 및 저장 시 암호화
- SOC 2 — 진행 중 (2026년 4분기 목표)
- 99.9% 가용성 SLA, 미달 시 크레딧 제공
- 미국 및 EU 리전, 데이터는 사용자가 선택한 위치에 머무름

---

## Cloud vs self-host

| | Self-host | Cloud |
|---|---|---|
| 첫 워크플로까지의 시간 | 몇 시간 (사용자의 시간) | 몇 시간 (우리의 시간) |
| 가용성 책임 | 사용자 | SLA와 함께 Yoodule |
| 온콜 | 사용자 | Yoodule |
| 업그레이드 & 패치 | 사용자가 직접 실행 | Yoodule이 실행, 사용자가 승인 |
| 비용 | 무료 + 사용자의 시간 | 월 정액 + 시간 0 |
| 데이터 위치 | 사용자 머신 | US 또는 EU, 선택 가능 |
| 이전 | 해당 없음 | 설정, mcp.json, OAuth 토큰 원클릭 내보내기 |

---

## FAQ

**나중에 self-host에서 cloud로 이전할 수 있나요?**
네. `mcp.json`, `.env`, OAuth 토큰을 원클릭으로 가져올 수 있습니다. 통화에서 함께 컷오버를 진행합니다.

**cloud에서 self-host로 다시 돌아갈 수 있나요?**
네. 동일한 원클릭 내보내기를 어떤 Nimbus 설치에 대해서도 실행할 수 있습니다.

**데이터는 어디에 저장되나요?**
가입 시 선택하는 US 또는 EU. 사전에 알리지 않고 이동하지 않습니다.

**Yoodule이 접근할 수 있는 것은 무엇인가요?**
Nimbus 인스턴스의 런타임 로그와 워크플로가 생성한 MCP 서버 출력뿐입니다. 사용자의 소스 코드, CRM, 이메일 내용은 읽지 않습니다.

**해지할 수 있나요?**
언제든 가능합니다. 데이터 내보내기는 그대로 보존됩니다.

**어떤 리전을 사용할 수 있나요?**
US-East, US-West, EU-Frankfurt. 요청 시 추가 가능합니다.

---

<div style="text-align: center; margin: 48px 0 24px 0; padding: 32px; background: #0a0a0a; border: 1px solid #262626; border-radius: 12px;">
  <p style="color: #a3a3a3; font-size: 1.1em; margin: 0 0 20px 0;">
    가이드가 함께하는 워크스루를 원하시나요? 30분 통화를 예약해 인스턴스를 함께 설계해 봅시다.
  </p>
  <a href="https://calendly.com/sundayj/30min" target="_blank" style="display: inline-flex; align-items: center; gap: 8px; background: #ffffff; color: #000000; text-decoration: none; font-weight: 600; padding: 14px 28px; border-radius: 8px; font-size: 1.05em;">
    통화 예약 →
  </a>
  <p style="color: #737373; font-size: 0.9em; margin: 16px 0 0 0;">
    또는 <a href="mailto:hello@yoodule.com" style="color: #a3a3a3;">hello@yoodule.com</a> 으로 직접 이메일을 보내 주셔도 됩니다.
  </p>
</div>
