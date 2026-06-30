# BufferPLUS + BDWidth motion mismatch monitor

작성일: 2026-06-30
대상 호스트: `voronrpi4b` / `192.168.0.29`
분류: current operation

## 목적

BufferPLUS가 메인 익스트루더에 동기화되어 필라멘트를 밀고 있는데, BDWidth 위치에서는 필라멘트 이동량이 증가하지 않는 상태를 감지한다. 이 조건은 버퍼 출구 튜브 이탈, 필라멘트 끊김, 버퍼 기어 헛돎, 또는 BDWidth 센서/로그 정지를 의심할 수 있는 신호다.

## 현재 구조

1. `lll_plus.cfg`의 `[extruder_stepper buffer_stepper]`는 `extruder: extruder`로 메인 익스트루더에 묶여 있다.
2. 런타임에서 `extruder_stepper buffer_stepper.motion_queue == "extruder"`이면 버퍼 스텝퍼는 메인 익스트루더 E 이동 큐를 따라간다.
3. `[buffer]` 플러그인은 hall sensor zone에 따라 `rotation_distance`를 보정한다.
4. `bdwidth fila_width_0` Moonraker 객체는 현재 `enabled`, `filament_detected`만 노출한다.
5. BDWidth 누적 이동량은 `~/printer_data/logs/bdwidth_fila_width_0.log.csv`의 세 번째 컬럼에서 확인한다.

## 정상 동기화 기준

단순히 `buffer.state == "feeding"`인 것만으로는 실제 fault를 판단하면 안 된다. 출력 중 travel 구간이나 extrusion이 없는 구간에서는 BDWidth 이동량이 없어도 정상이다.

정상/비정상 판단은 같은 시간창에서 아래 값을 같이 비교한다.

```text
print_stats.state
gcode_move.position[3]
print_stats.filament_used
buffer.state
buffer.synced_to
extruder_stepper buffer_stepper.motion_queue
bdwidth fila_width_0.enabled
bdwidth fila_width_0.filament_detected
bdwidth_fila_width_0.log.csv 누적 이동량
```

## Fault 조건

아래 조건이 모두 참이면 버퍼 이후 필라멘트 전달 이상으로 판단한다.

```text
print_stats.state == "printing"
AND buffer.state == "feeding"
AND buffer.synced_to == "extruder"
AND extruder_stepper buffer_stepper.motion_queue == "extruder"
AND bdwidth fila_width_0.enabled == true
AND gcode_move.position[3] 또는 print_stats.filament_used 증가량 >= E_MIN
AND BDWidth 누적 이동량 증가량 <= BD_MIN
```

초기 임계값 제안:

```text
WINDOW_SECONDS = 10
E_MIN = 10.0 mm
BD_MIN = 1.0 to 2.0 mm
CONSECUTIVE_WINDOWS = 2
```

10초 창에서 E가 10mm 이상 증가했는데 BDWidth 누적 이동량이 1-2mm 이하인 상태가 2회 연속이면 `PAUSE`와 `BUFFER_DISABLE`을 걸어야 한다.

## 정상 샘플

2026-06-30 live 출력 중 10초 샘플:

```text
print_stats.state: printing
E delta: +34.647 mm
filament_used delta: +37.797 mm
BDWidth delta: +32.7 mm
buffer.state: feeding
buffer.synced_to: extruder
buffer.current_zone: middle
buffer.rd_multiplier: 1.0
extruder_stepper buffer_stepper.motion_queue: extruder
bdwidth.enabled: true
bdwidth.filament_detected: true
```

이 샘플은 fault가 아니다. 메인 익스트루더, 버퍼, BDWidth가 같은 방향으로 이동을 보고 있다.

## 오탐 조건

아래 상태에서는 pause를 걸면 안 된다.

1. `print_stats.state != "printing"`
2. 출력 중이지만 해당 시간창에 extrusion이 거의 없는 travel 구간
3. `bdwidth fila_width_0.enabled == false`
4. `bdwidth fila_width_0.filament_detected == false`
5. BDWidth 로그 파일이 갱신되지 않는 센서/플러그인 문제
6. BDWidth가 물리적으로 버퍼보다 앞쪽에 설치된 배치
7. 리트랙션/언리트랙션이 많은 짧은 시간창

BDWidth의 물리 위치가 버퍼 출구 이후, 익스트루더 진입 전 경로에 있어야 이 감지가 튜브 이탈 감지로 의미가 있다.

## 권장 대응

fault 조건이 성립하면 다음 순서가 안전하다.

```gcode
PAUSE
BUFFER_DISABLE
M118 >>> [BUFFER_BDWIDTH_FAULT] Extruder requested filament, but BDWidth saw no motion.
```

BDWidth 자체가 멈춘 것인지 필라멘트 전달이 끊긴 것인지 구분하려면 pause 후 물리 확인이 필요하다.

## 구현 방향

Klipper 매크로보다는 호스트 측 Moonraker 모니터가 적합하다. 이유는 BDWidth 누적 이동량이 Moonraker 객체에 직접 노출되지 않고 CSV 로그 파일로 기록되기 때문이다.

모니터 루프는 다음 데이터를 주기적으로 샘플링한다.

```bash
curl -s "http://127.0.0.1:7125/printer/objects/query?print_stats&gcode_move&buffer&bdwidth%20fila_width_0&extruder_stepper%20buffer_stepper"
tail -n 1 ~/printer_data/logs/bdwidth_fila_width_0.log.csv
```

BDWidth CSV 예시:

```text
06/30 13:17:05,1.764,-5843.7mm,-250111
```

세 번째 컬럼의 절댓값 차이를 `BDWidth delta`로 사용한다.

## 다음 작업 단위

1. `scripts/monitor_buffer_bdwidth.py` 형태의 호스트 모니터 초안을 만든다.
2. dry-run 모드에서 `M118`만 내도록 검증한다.
3. live 출력 중 10초 창 5회 이상 정상 샘플을 수집해 임계값을 조정한다.
4. pause 동작은 마지막 단계에서 `PAUSE`/`BUFFER_DISABLE`을 켜서 검증한다.
