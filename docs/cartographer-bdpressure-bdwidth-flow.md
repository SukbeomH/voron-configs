# Cartographer + BD Pressure + BD Width 운용 순서

작성일: 2026-06-12
대상 호스트: `voronrpi4b` / `192.168.0.29`

## 1. 역할 분리

1. Cartographer는 Z homing, QGL 이후 Z 재확인, bed mesh scan을 담당한다.
2. BD Pressure는 표준 Klipper `[probe]`로 로드하지만, `PRINT_START`에서는 최종 출력 직전 Z 기준 확인에 사용한다.
3. BD Pressure PA 기능은 `PA_CALIBRATE`로 압력 선행값을 자동 보정한다.
4. BD Width는 `printer_bdwidth.cfg`로 다시 활성화하고, `PRINT_START`에서 `SET_BDWIDTH NAME=fila_width_0 COMMAND=ENABLE`로 켠다.

## 2. 장치와 설정 기준

1. Cartographer plugin은 `cartographer3d-plugin 1.8.0` 이상이어야 한다.
2. `[cartographer]`에는 `register_as_probe: false`를 둔다.
3. Z endstop은 `cartographer_probe:z_virtual_endstop`를 사용한다.
4. BD Pressure `[probe]`는 `^EBBusb:PB8`을 사용한다.
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
2. 필라멘트 센서 상태를 확인한다.
3. 베드 가열을 시작하고 노즐은 150도 대기 온도로 올린다.
4. `G28`로 Cartographer 기반 homing을 수행한다.
5. 베드 목표 온도에 도달할 때까지 대기한다.
6. 150도에서 노즐을 청소한다.
7. `CQGL`로 QGL이 안 된 경우에만 `QUAD_GANTRY_LEVEL`을 실행한다.
8. `CARTOGRAPHER_TOUCH_HOME`으로 QGL 이후 Cartographer Z 기준을 재확인한다.
9. `BED_MESH_CALIBRATE ADAPTIVE=1`로 Cartographer mesh를 생성한다.
10. mesh 직후 `CLEAN_NOZZLE`로 잔여물을 제거한다. 이전 출력 잔여물이 BD nozzle probe에 끼지 않게 하기 위한 단계다.
11. `SET_Z_FROM_PROBE`로 BD Pressure nozzle probe를 사용해 최종 Z 기준을 동기화한다.
12. upstream `klipper/README.md` 방식대로 `PA_SAFE_Z=30` 높이의 `PA_PARK_X=240`, `PA_PARK_Y=240` poop position으로 이동한다.
13. `PA_CALIBRATE`로 BD Pressure PA 자동 보정을 실행한다. `PA_E` 내부 좌표는 upstream 기본값을 유지하고, 사전 위치 이동으로 공중 압출 높이만 보장한다.
14. PA 공중 압출 후 `CLEAN_NOZZLE`을 다시 실행해 purge 전 노즐 끝 상태를 정리한다.
15. `SET_BDWIDTH NAME=fila_width_0 COMMAND=ENABLE`로 BD Width를 활성화한다.
16. 출력 온도를 최종 확인한다.
17. purge line을 출력하고 print를 시작한다.

## 4. 주의할 점

1. `SET_Z_FROM_PROBE`는 `BED_MESH_CALIBRATE ADAPTIVE=1` 직후 `CLEAN_NOZZLE` 다음에 둔다. PA는 공중 압출이며 Z 기준을 재정의하지 않으므로, PA 이후에는 purge 전 노즐 청소만 다시 수행한다.
2. `G28 Z`와 `CQGL`은 Cartographer 기준이어야 한다. BD Pressure가 Z homing 전체를 맡으면 "BD는 최종 Z만 담당"이라는 운용 목표와 다르다.
3. `PROBE`는 BD Pressure `[probe]`를 의미한다. Cartographer probe 동작은 `CARTOGRAPHER_SCAN_PROBE`, `CARTOGRAPHER_TOUCH_PROBE`, `CARTOGRAPHER_TOUCH_HOME`처럼 prefix가 붙은 명령을 사용한다.
4. BD Width include를 켜면 `SET_BDWIDTH`가 반드시 G-code help에 보여야 한다.
5. `PA_CALIBRATE`/`PA_E` 내부 좌표는 upstream `bd_pressure.cfg` 기본값을 유지한다. `PA_PARK_X/Y`는 upstream README의 사전 poop position 이동값이며, 내부 PA 경로를 재정의하지 않는다.
6. by-path serial은 USB 포트를 바꾸면 달라진다. 포트를 변경한 경우 `/dev/serial/by-path`를 다시 확인해야 한다.

## 5. 기본 검증 명령

```bash
curl -s http://127.0.0.1:7125/printer/info
curl -s http://127.0.0.1:7125/printer/gcode/help
curl -s "http://127.0.0.1:7125/printer/objects/query?probe&cartographer&bdpressure%20bd_pa&bdwidth%20fila_width_0"
```

기대값:

1. `printer/info`는 `state: ready`여야 한다.
2. `PROBE`, `QUERY_PROBE`, `SET_Z_FROM_PROBE`, `CARTOGRAPHER_TOUCH_HOME`, `CARTOGRAPHER_SCAN_PROBE`, `BED_MESH_CALIBRATE`, `PA_CALIBRATE`, `SET_BDWIDTH`가 등록되어야 한다.
3. `probe` 객체는 BD Pressure `[probe]`이고, Cartographer는 별도 `cartographer` 객체로 유지되어야 한다.
4. `bdpressure bd_pa`는 대기 상태에서 `STOP`이어야 한다.

## 6. Filament path sensors

1. `extruder_entry_filament` uses `^!EBBusb:PB6` and represents the extruder path entry sensor.
2. `extruder_exit_filament` uses `^!EBBusb:PB5` and represents the extruder/toolhead path exit sensor.
3. `ASSERT_TOOLHEAD_FILAMENT` requires both sensors to detect filament before `PRINT_START` continues.
4. `pause_on_runout` is kept disabled until both sensors are physically verified.
