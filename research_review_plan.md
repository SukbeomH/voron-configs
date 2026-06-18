# Research Review Plan

## 2.1 API 계약 레지스트리 (대상 API A)

| method명 | gateway URL | 필수 파라미터 | 선택 파라미터 | 응답 핵심 필드 | 마지막 확인일(YYYY-MM-DD) | 확인 환경(샌드박스/프로덕션) | 참고 문서 URL |
|---|---|---|---|---|---|---|---|
| `POST /v1/...` | `https://api-gateway.example.com/v1/...` | `client_id`, `timestamp`, `sign`, `payload` | `locale`, `request_id` | `code`, `message`, `data.result`, `data.trace_id` | 2026-05-27 | 샌드박스 | https://docs.example.com/api-a |

- 근거 URL: https://docs.example.com/api-a

## 2.2 API 계약 레지스트리 (대상 API B)

| method명 | gateway URL | 필수 파라미터 | 선택 파라미터 | 응답 핵심 필드 | 마지막 확인일(YYYY-MM-DD) | 확인 환경(샌드박스/프로덕션) | 참고 문서 URL |
|---|---|---|---|---|---|---|---|
| `GET /v2/...` | `https://api-gateway.example.com/v2/...` | `access_token`, `merchant_id` | `page`, `page_size`, `updated_after` | `success`, `error_code`, `items[]`, `next_cursor` | 2026-05-27 | 샌드박스 | https://docs.example.com/api-b |

- 근거 URL: https://docs.example.com/api-b

## 2.3 API 계약 레지스트리 (대상 API C)

| method명 | gateway URL | 필수 파라미터 | 선택 파라미터 | 응답 핵심 필드 | 마지막 확인일(YYYY-MM-DD) | 확인 환경(샌드박스/프로덕션) | 참고 문서 URL |
|---|---|---|---|---|---|---|---|
| `PUT /v3/...` | `https://api-gateway.example.com/v3/...` | `api_key`, `sign`, `resource_id` | `dry_run`, `metadata` | `status`, `error`, `updated_at`, `resource` | 2026-05-27 | 프로덕션 | https://docs.example.com/api-c |

- 근거 URL: https://docs.example.com/api-c

## 변경 감시 항목

구현팀은 정기 점검 시 아래 항목을 API별로 체크한다.

- sign 규칙 변경 여부
  - 예: 해시 알고리즘(SHA256/HMAC), 문자열 정렬 규칙, 인코딩 규칙(UTF-8), nonce/timestamp 포함 여부
- 필수 파라미터 변경 여부
  - 예: 신규 필수 필드 추가, 기존 필수 필드 optional 전환, 타입/포맷 변경
- 에러코드 스키마 변경 여부
  - 예: `error_code` 타입(number/string), `error_message` 위치, 하위 `details` 구조 변경
- 응답 필드 nullable 변화 여부
  - 예: 기존 non-null 필드의 null 허용 전환 또는 반대 변경

## 검증 로그 위치

샘플 호출 결과(JSON)는 아래 경로에 저장한다.

- `logs/api-contract-validation/YYYY-MM-DD/<api-name>/<method>.json`
