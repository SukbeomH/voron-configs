# Voron documentation index

작성일: 2026-06-30
대상 호스트: `voronrpi4b` / `192.168.0.29`

이 디렉터리는 사람이 읽는 장기 문서의 canonical 위치다. `context/`는 작업별 증거, live snapshot, diff, 임시 테스트 산출물을 보관하는 곳으로 둔다.

## Current operations

현재 설정이나 운영 판단에 직접 쓰는 문서다.

1. [BufferPLUS + BDWidth motion mismatch monitor](operations/buffer-bdwidth-motion-monitor.md)
   - 버퍼는 이송 중인데 BDWidth 이동량이 없는 조건을 fault로 볼지 판단하는 기준.
   - 향후 `scripts/monitor_buffer_bdwidth.py` 구현 기준 문서.
2. [BD Pressure Z Endstop + BTT Eddy Scan](operations/bdpressure-z-endstop-eddy-scan.md)
   - BD Pressure 물리 switch를 Z endstop으로 쓰고 Eddy scan mesh를 유지하는 절차.
3. [Eddy Tap Z 기준점 변동 및 direct mesh 중복 보정 사고 기록](operations/eddy-tap-zero-reference-direct-mesh-incident-2026-07-14.md)
   - `mesh_pps: 0,0` direct 경로에서 `zero_reference_position`이 두 번 적용된 첫 레이어 Z 오류의 원인, 설정 우회, 검증 및 재발 방지 절차.

## Research

조사 결과, 설계 후보, 장기 검토용 문서다. 현재 운영 절차로 그대로 적용하기 전에 live 설정과 다시 대조해야 한다.

1. [Klipper optional 구성 조사 및 테스트 기록](research/klipper-optional-config-research-2026-06-13.md)
   - Klipper include/optional bundle 가능성 조사와 테스트 기록.
2. [Research review plan](research/research-review-plan.md)
   - API 계약 검토 템플릿. Voron 운영 절차 문서는 아니며 참고 템플릿으로 보관한다.

## Archive

구형 구조, 과거 판단, 대체된 운용 흐름이다. 현재 적용 전에 반드시 current operations 문서와 active config를 우선 확인한다.

1. [Cartographer + BD Pressure + BD Width 운용 순서](archive/cartographer-bdpressure-bdwidth-flow.md)
   - 2026-06-12 기준의 이전 probe/BD Pressure/BDWidth 운용 흐름.

## Plans

구현 전 계획이나 감사 계획은 `docs/superpowers/plans/`에 둔다.

현재 항목:

1. [BD Pressure / Cartographer PRINT_START audit plan](superpowers/plans/2026-06-12-bdpressure-cartographer-print-start-audit.md)

## Routing rules

1. 새 운영 절차는 `docs/operations/`에 둔다.
2. 조사 기록이나 아직 적용하지 않은 설계안은 `docs/research/`에 둔다.
3. 대체된 문서는 삭제하지 말고 `docs/archive/`로 이동한다.
4. 작업별 live snapshot, 로그, diff, 실험 파일은 `context/YYYY-MM-DD-or-topic/`에 둔다.
5. `context/README.md`는 작업 에이전트용 현재성 포인터로 유지하되, 장기 문서의 canonical index는 이 파일이다.
