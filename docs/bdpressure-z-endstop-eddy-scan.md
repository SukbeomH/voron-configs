# BD Pressure Z Endstop + BTT Eddy Scan

작성일: 2026-06-19
대상 호스트: `voronrpi4b` / `192.168.0.29`

## 목표

1. BD Pressure의 물리 switch 출력을 Z endstop으로 사용한다.
2. BTT Eddy는 Klipper stock probe object로 유지해 QGL과 `BED_MESH_CALIBRATE METHOD=scan`을 계속 담당한다.
3. BD Pressure를 Klipper `[probe]`로 정의하지 않는다. `[probe]`를 정의하면 Eddy scan probe 소유권과 충돌할 수 있다.

## 적용된 설정

`printer_mainboard.cfg`:

```ini
[stepper_z]
endstop_pin: ^EBBusb:PB8
position_endstop: 0
position_min: -5
```

`printer_eddy.cfg`:

```ini
[probe_eddy_current btt_eddy]
```

Eddy 설정은 유지한다. `PRINT_START`의 mesh 단계도 계속 다음 명령을 사용한다.

```gcode
BED_MESH_CALIBRATE METHOD=scan ADAPTIVE=1
```

`printer_bd_pressure_usb.cfg`의 `[bdpressure bd_pa]`는 PA 보정과 BD Pressure 상태 명령용으로 유지한다.

## 호스트에서 pull 후 검증 순서

호스트가 켜지고 배선 정비가 끝난 뒤, 움직임 명령 전에 먼저 설정과 endstop 상태를 확인한다.

```bash
cd ~/printer_data/config
git pull
```

Klipper restart 후:

```gcode
QUERY_ENDSTOPS
PA_RESET
QUERY_ENDSTOPS
```

확인 기준:

1. 노즐이 베드에 닿지 않은 상태에서 Z endstop이 open이어야 한다.
2. 손으로 BD Pressure를 살짝 눌렀을 때 Z endstop이 TRIGGERED로 바뀌어야 한다.
3. 반대로 동작하면 `endstop_pin`의 `!` 반전 여부를 수정해야 한다.
4. 신호가 항상 TRIGGERED 또는 항상 open이면 배선, `EBBusb:PB8`, pullup `^`, BD Pressure reset 상태를 먼저 확인한다.

상태가 맞을 때만 저속 Z homing을 진행한다.

```gcode
G28 X Y
G28 Z
```

그 다음에만 QGL과 Eddy scan mesh를 확인한다.

```gcode
QUAD_GANTRY_LEVEL
G28 Z
BED_MESH_CALIBRATE METHOD=scan ADAPTIVE=1
```

## 주의

호스트 종료 상태에서 레포만 수정한 변경이다. 실제 BD Pressure 출력 핀은 이전 백업 설정의 `EBBusb:PB8` 근거를 사용했다. 정비 중 배선이 달라졌다면 pull 후 첫 restart 전에 `printer_mainboard.cfg`의 `endstop_pin`을 실제 핀에 맞게 고친다.
