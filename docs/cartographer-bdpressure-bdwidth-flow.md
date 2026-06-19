# Cartographer + BD Pressure + BD Width 운용 순서

작성일: 2026-06-12
대상 호스트: `voronrpi4b` / `192.168.0.29`

> Historical note, 2026-06-19: this document describes the older
> Cartographer-owned probe architecture. The active repository now uses
> BD Pressure as the physical Z endstop on `^EBBusb:PB8` and keeps BTT Eddy
> as the stock probe for QGL and `BED_MESH_CALIBRATE METHOD=scan`.
> See `docs/bdpressure-z-endstop-eddy-scan.md` for the current pull-and-test
> procedure.

## 1. 역할 분리

1. Cartographer는 표준 Klipper `probe`, Z homing, QGL, final Z touch, bed mesh scan을 담당한다.
2. BD Pressure는 표준 `[probe]`로 로드하지 않는다. PA 기능(`PA_CALIBRATE`, `PA_E`, `PA_RESET`)만 유지한다.
3. BD Pressure PA 기능은 `PRINT_START RUN_PA=1` 또는 수동 `PA_CALIBRATE`로만 실행한다.
4. BD Width는 `printer_bdwidth.cfg`로 다시 활성화하고, `PRINT_START`에서 `SET_BDWIDTH NAME=fila_width_0 COMMAND=ENABLE`로 켠다.

## 2. 장치와 설정 기준

1. Cartographer plugin은 `cartographer3d-plugin 1.8.0` 이상이어야 한다.
2. `[cartographer]`에는 `register_as_probe: true`를 둔다.
3. Z endstop은 `probe:z_virtual_endstop`를 사용한다.
4. BD Pressure `[probe]` 블록은 정의하지 않는다.
5. BD Pressure USB serial은 by-path로 고정한다.
6. BD Width USB serial도 by-path로 고정한다. BD Pressure와 BD Width 모두 CH340 계열이라 `/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0`는 충돌 가능성이 있다.

현재 주요 경로:

```ini
BD Pressure: /dev/serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.1:1.0-port0
BD Width:    /dev/serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.2:1.0-port0
Main MCU:    /dev/serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.4:1.0-port0
Cartographer:/dev/serial/by-id/usb-Cartographer_614e_160011000A43565537353020-if00
EBBusb:      /dev/serial/by-id/usb-Klipper_stm32g0b1xx_500031000650505539323520-if00
```

## 3. PRINT_START 순서

1. `SET_GCODE_OFFSET Z=0`으로 이전 런타임 Z 오프셋을 초기화한다.
2. 필라멘트 센서는 기본 monitor-only로 상태를 출력한다. `PRINT_START REQUIRE_FILAMENT=1`일 때만 hard-abort한다.
3. 베드 가열을 시작하고 노즐은 150도 대기 온도로 올린다.
4. `G28`로 Cartographer 기반 homing을 수행한다.
5. 베드 목표 온도에 도달할 때까지 대기한다.
6. 150도에서 노즐을 청소한다.
7. `CQGL`로 QGL이 안 된 경우에만 `QUAD_GANTRY_LEVEL`을 실행한다.
8. `CARTOGRAPHER_TOUCH_HOME`으로 QGL 이후 Cartographer Z 기준을 재확인한다.
9. `BED_MESH_CALIBRATE ADAPTIVE=1`로 Cartographer mesh를 생성한다.
10. mesh 직후 `CLEAN_NOZZLE`로 잔여물을 제거한다.
11. `CARTOGRAPHER_TOUCH_HOME`으로 post-mesh cleaning 이후 최종 Z 기준을 다시 잡는다.
12. 기본값은 BD Pressure PA 자동 보정을 건너뛴다. `PRINT_START RUN_PA=1`일 때만 upstream 방식대로 `PA_SAFE_Z=30`, `PA_PARK_X=240`, `PA_PARK_Y=240` poop position으로 이동한 뒤 `PA_CALIBRATE`를 실행한다.
13. `RUN_PA=1`이면 PA 공중 압출 후 `CLEAN_NOZZLE`을 다시 실행해 purge 전 노즐 끝 상태를 정리한다.
14. `SET_BDWIDTH NAME=fila_width_0 COMMAND=ENABLE`로 BD Width를 활성화한다.
15. 출력 온도를 최종 확인한다.
16. purge line을 출력하고 print를 시작한다.

## 4. 주의할 점

1. `SET_Z_FROM_PROBE`는 deprecated이며 `PRINT_START`에서 호출하지 않는다. 이 매크로는 stock `PROBE` 결과로 `SET_KINEMATIC_POSITION`을 수행하므로 final Z 경로에 넣지 않는다.
2. `G28 Z`는 `probe:z_virtual_endstop` 기준이다. Cartographer가 stock `probe`를 소유하므로 `CQGL`/`QUAD_GANTRY_LEVEL`도 Cartographer-backed probe를 사용한다.
3. QGL front points는 Cartographer `y_offset: 43`과 `stepper_y position_min: 1`을 고려해 `Y45`에 둔다. GitHub 이전 Cartographer-probe 설정의 `Y0` front points는 현재 구조에서 복원하지 않는다.
4. Do not restore BD Pressure `[probe]` unless intentionally returning to split-probe architecture. If BD Pressure `[probe]` is restored, QGL and `PROBE` will use BD Pressure again.
5. BD Width include를 켜면 `SET_BDWIDTH`가 반드시 G-code help에 보여야 한다.
6. `PA_CALIBRATE`/`PA_E` 내부 좌표는 upstream `bd_pressure.cfg` 기본값을 유지한다. `PA_PARK_X/Y`는 upstream README의 사전 poop position 이동값이며, 내부 PA 경로를 재정의하지 않는다.
7. by-path serial은 USB 포트를 바꾸면 달라진다. 포트를 변경한 경우 `/dev/serial/by-path`를 다시 확인해야 한다.

## 5. 기본 검증 명령

```bash
curl -s http://127.0.0.1:7125/printer/info
curl -s http://127.0.0.1:7125/printer/gcode/help
curl -s "http://127.0.0.1:7125/printer/objects/query?probe&cartographer&bdpressure%20bd_pa&bdwidth%20fila_width_0"
```

기대값:

1. `printer/info`는 `state: ready`여야 한다.
2. `PROBE`, `QUERY_PROBE`, `PROBE_ACCURACY`, `SET_Z_FROM_PROBE`, `CARTOGRAPHER_TOUCH_HOME`, `CARTOGRAPHER_SCAN_PROBE`, `BED_MESH_CALIBRATE`, `PA_CALIBRATE`, `SET_BDWIDTH`가 등록되어야 한다.
3. `probe` 객체는 Cartographer-backed stock probe이고, BD Pressure는 `bdpressure bd_pa` 객체로만 유지되어야 한다.
4. `bdpressure bd_pa`는 대기 상태에서 `STOP`이어야 한다.

## 6. Filament path sensors

1. `extruder_entry_filament` uses `^!EBBusb:PB6` and represents the extruder path entry sensor.
2. `extruder_exit_filament` uses `^!EBBusb:PB5` and represents the extruder/toolhead path exit sensor.
3. `PRINT_START` defaults to monitor-only and calls `FILAMENT_STATUS` so unverified PB5/PB6 wiring does not block prints.
4. `PRINT_START REQUIRE_FILAMENT=1` calls `ASSERT_TOOLHEAD_FILAMENT` and requires both sensors to detect filament.
5. `pause_on_runout` is kept disabled until both sensors are physically verified.
