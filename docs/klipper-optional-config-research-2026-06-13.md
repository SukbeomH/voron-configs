# Klipper optional 구성 조사 및 테스트 기록

작성일: 2026-06-13
대상 호스트: voronrpi4b (192.168.0.29)
작성 목적: USB 허브 기반 주변 장치를 Klipper에서 optional 하게 분리할 수 있는지 공식 최신 정보와 실제 테스트로 검증

## 결론

1. Klipper에는 일반적인 의미의 "하드웨어 섹션 runtime optional" 기능이 없다.
2. 공식적으로 기대할 수 있는 수단은 `[include]` 기반의 정적 파일 분리다.
3. 최신 upstream 구현 기준으로 `[include optional/*.cfg]` 는 빈 매치(파일 0개)를 허용한다.
4. 따라서 허브 뒤 장치(BD Pressure, BD Width, BME280 등)는 optional bundle로 빼는 방식이 현실적이다.
5. 다만 baseline 매크로가 `PA_CALIBRATE`, `SET_BDWIDTH`, `QUERY_TOOLHEAD_AIR` 같은 명령을 직접 호출하면 runtime 호환용 no-op stub가 필요하다.

## 확인 기준

- Klipper master 최신 문서와 소스 동작 확인
- 실제 호스트에서 별도 임시 디렉터리를 만들어 include 파서 테스트 수행
- 실제 Voron config tree를 복제해 optional bundle 구조로 재배치한 뒤 parse 테스트 수행

## 실제 테스트 결과

### 테스트 1: 직접 include는 파일이 없으면 실패
- 구성: `[include optional/bd_pressure.cfg]`
- optional 디렉터리 비어 있음
- 결과: 실패
- 오류: `Include file ... does not exist`

### 테스트 2: wildcard include는 디렉터리가 비어 있어도 통과
- 구성: `[include optional/*.cfg]`
- optional 디렉터리 비어 있음
- 결과: 통과

### 테스트 3: wildcard include에 파일이 있으면 정상 포함
- 구성: `[include optional/*.cfg]`
- optional/bd_pressure.cfg 존재
- 결과: 통과

### 테스트 4: 현재 Voron config를 복제해 optional bundle 제거 후 parse
- optional 후보 제거:
  - printer_bd_pressure_usb.cfg
  - printer_bdwidth.cfg
  - printer_bme280_toolhead.cfg
- printer.cfg에 `[include optional/*.cfg]` 추가
- optional 디렉터리 비워 둠
- 결과: parse 통과

### 테스트 5: 같은 구조에서 optional 파일을 optional/에 다시 넣고 parse
- 결과: parse 통과

### 테스트 6: runtime 호환용 stub 파일 추가 후 parse
- 추가한 stub:
  - `PA_CALIBRATE`
  - `SET_BDWIDTH`
  - `QUERY_TOOLHEAD_AIR`
- 결과: parse 통과

## 현재 Voron에 대한 실무 설계안

### baseline에 둘 것
- printer_toolhead_usb.cfg
- printer_cartographer.cfg
- printer_mainboard.cfg
- mainsail.cfg
- macros.cfg
- chopper_tune.cfg
- mcu_flasher.cfg
- 필요 시 filament sensor는 운영 정책에 따라 baseline 유지

### optional bundle로 뺄 것
- printer_bd_pressure_usb.cfg
- printer_bdwidth.cfg
- printer_bme280_toolhead.cfg

### 권장 include 구조

```ini
[include mcu_flasher.cfg]
[include chopper_tune.cfg]
[include mainsail.cfg]
[include printer_toolhead_usb.cfg]
[include printer_cartographer.cfg]
[include printer_mainboard.cfg]
[include compat_optional_missing.cfg]
[include optional/*.cfg]
[include printer_toolhead_rgb.cfg]
[include printer_filament_sensors.cfg]
[include klippain-shaketune.cfg]
[include macros.cfg]
```

## 왜 compat_optional_missing.cfg 가 필요한가

현재 baseline 쪽에서 optional 장치 명령을 참조하는 부분이 있다.

확인된 참조:
- macros.cfg
  - `PA_CALIBRATE`
  - `SET_BDWIDTH NAME=fila_width_0 COMMAND=ENABLE`
  - `SET_BDWIDTH NAME=fila_width_0 COMMAND=DISABLE`
- printer_filament_sensors.cfg
  - `SET_BDWIDTH NAME=fila_width_0 COMMAND=QUERY`

따라서 optional bundle이 빠진 상태에서도 baseline을 유지하려면 no-op 매크로가 필요하다.

예시:

```ini
[gcode_macro PA_CALIBRATE]
gcode:
  { action_respond_info("PA_CALIBRATE unavailable: optional bd_pressure bundle not loaded") }

[gcode_macro SET_BDWIDTH]
gcode:
  { action_respond_info("SET_BDWIDTH unavailable: optional bdwidth bundle not loaded") }

[gcode_macro QUERY_TOOLHEAD_AIR]
gcode:
  { action_respond_info("QUERY_TOOLHEAD_AIR unavailable: optional toolhead_air bundle not loaded") }
```

## 한계

이 방식은 "하드웨어 자동 감지"가 아니다.

의미하는 것:
- restart 전에 어떤 cfg 파일을 포함할지 정적으로 선택
- optional bundle이 없으면 baseline만으로 startup 가능하게 설계

의미하지 않는 것:
- Klipper가 장치 존재를 보고 자동으로 config 섹션을 생략
- 일반 config section을 Jinja if/else 로 조건부 활성화
- 포함된 파일의 장치가 없을 때 soft-fail 자동 처리

## 다음 단계 제안

1. live config 수정 전에 branch/backup 확보
2. optional bundle 디렉터리와 compat file 초안 작성
3. baseline 모드에서 printer ready 검증
4. 허브 on 상태에서 optional bundle을 다시 로드해 기능 회복 검증
