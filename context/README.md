# Voron Config Context Index

Last updated: 2026-06-12 Asia/Seoul
Host: `voronrpi4b` / `192.168.0.29`
Config root: `/home/sukbeom/printer_data/config`
Branch: `codex/bdpressure-option2-20260612-142732`

This is the agent-friendly entry point for this printer config. Read it before editing macros, probe ownership, BD Pressure, Cartographer, BD Width, filament sensors, Moonraker, or USB serial settings.

## 1. Current Runtime Status

Last verified in this thread after USB hub replacement:

```text
Moonraker: active, `/server/info` reachable on `127.0.0.1:7125`
Klipper: `/printer/info` state `ready`, state_message `Printer is ready`
Main MCU: connected on the new CH340 by-path
EBBusb: connected by-id
Cartographer: connected by-id
BD Pressure object: `bdpressure bd_pa`, state `STOP`
BD Width object: `bdwidth fila_width_0`, loaded and queryable
Filament sensors: PB6/PB5 objects loaded, currently unverified physically
```

Important Moonraker note: during this work Moonraker failed to start because `moonraker.conf` had duplicate `[mcu_flasher ebb_usb]` sections. The obsolete first block was removed from the active file so Moonraker could start. `moonraker.conf` already had unrelated uncommitted edits; do not stage it broadly without reviewing the full diff.

Before any motion, probing, heat, or restart-sensitive command, verify current state:

```bash
ssh sukbeom@192.168.0.29 'curl -s http://127.0.0.1:7125/printer/info'
ssh sukbeom@192.168.0.29 'curl -s http://127.0.0.1:7125/server/info'
ssh sukbeom@192.168.0.29 'ls -l /dev/serial/by-path /dev/serial/by-id'
```

## 2. USB Serial Map After Hub Replacement

Use by-path for generic CH340 devices. Do not use `/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0` for these because multiple CH340 devices collide.

```text
Main MCU:    /dev/serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.4:1.0-port0 -> ttyUSB1
BD Pressure: /dev/serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.1:1.0-port0 -> ttyUSB0
BD Width:    /dev/serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.2:1.0-port0 -> ttyUSB2
Buffer:      /dev/serial/by-id/usb-STMicroelectronics_FLY_BUFFER_F072C8_CDC_in_FS_Mode_206D326E5346-if00 -> ttyACM0
Cartographer:/dev/serial/by-id/usb-Cartographer_614e_160011000A43565537353020-if00 -> ttyACM1
EBBusb:      /dev/serial/by-id/usb-Klipper_stm32g0b1xx_500031000650505539323520-if00 -> ttyACM2
```

Identification evidence:

```text
Main MCU: verified with Klipper console at 250000 baud; reports stm32h723xx.
BD Width: verified by serial query `G00;` at 500000 baud; response `pandapi3dV1.2`.
BD Pressure: remaining CH340 after main MCU and BD Width identification; Klipper loads `bdpressure bd_pa` on this path and reaches ready. Direct serial version queries did not produce a response, so treat physical identity as path-by-elimination plus Klipper-load evidence.
```

If the hub, cable, or port changes, redo discovery before editing config:

```bash
ssh sukbeom@192.168.0.29 'ls -l /dev/serial/by-path /dev/serial/by-id && lsusb -t'
ssh sukbeom@192.168.0.29 'for d in /dev/ttyUSB* /dev/ttyACM*; do echo ===$d===; udevadm info -q property -n "$d" | egrep "DEVPATH|ID_MODEL|ID_SERIAL|ID_PATH"; done'
```

## 3. Git Safety Rules

The worktree may contain unrelated dirty files. Do not stage broad patterns.

Known unrelated or user-generated dirty paths seen during this work include:

```text
.moonraker.conf.bkp
moonraker.conf
crowsnest.conf
printer_toolhead_usb.cfg
scripts/reset_crowsnest.sh
variables.cfg
printer_hexa_distro_fusion.cfg deleted
ukam/* deleted
ShakeTune_results/*
macros.cfg.bak-20260612-135203
mcu_firmware/*
scripts/show_usb_serial_info.sh*
```

Use scoped status before staging:

```bash
ssh sukbeom@192.168.0.29 'cd ~/printer_data/config && git status --short -- printer.cfg macros.cfg printer_bd_pressure_usb.cfg printer_bdwidth.cfg printer_filament_sensors.cfg printer_cartographer.cfg printer_mainboard.cfg docs/cartographer-bdpressure-bdwidth-flow.md context/README.md'
```

## 4. Active Include Graph

The active root file is `printer.cfg`.

```ini
[include printer_toolhead_usb.cfg]
[include printer_bd_pressure_usb.cfg]
[include printer_cartographer.cfg]
[include printer_mainboard.cfg]
[include printer_filament_sensors.cfg]
[include printer_bdwidth.cfg]
[include macros.cfg]
```

Core files:

```text
printer.cfg                    main MCU serial and include order
printer_bd_pressure_usb.cfg     BD Pressure USB module, stock `[probe]`, PA_CALIBRATE, PA_E
printer_cartographer.cfg        Cartographer MCU and scanner/touch config
printer_mainboard.cfg           XY/Z steppers; Z endstop uses `cartographer_probe:z_virtual_endstop`
printer_bdwidth.cfg             BD Width USB module
printer_filament_sensors.cfg    EBBusb PB6/PB5 filament switch sensors and status/assert macros
macros.cfg                      PRINT_START, PRINT_END, SET_Z_FROM_PROBE, CLEAN_NOZZLE, CQGL
```

## 5. Probe Ownership Truth Table

```text
Standard Klipper `[probe]`: BD Pressure
Cartographer scanner/touch object: `cartographer`
Cartographer endstop chip: `cartographer_probe`
G28 Z / safe_z_home: Cartographer via `cartographer_probe:z_virtual_endstop`
BED_MESH_CALIBRATE ADAPTIVE=1: Cartographer scan path in current PRINT_START
SET_Z_FROM_PROBE: custom macro that uses BD Pressure `PROBE` then `SET_KINEMATIC_POSITION`
QUAD_GANTRY_LEVEL / CQGL: stock Klipper QGL consumes standard `[probe]`, so it is BD Pressure-backed in this architecture
```

BD Pressure probe sampling intentionally follows the upstream-tolerant policy for QGL use: `samples: 2`, `sample_retract_dist: 3`, `samples_tolerance: 0.03`, and double `PA_RESET` in `activate_gcode`. Do not tighten this without fresh `PROBE_ACCURACY` evidence.

`register_as_probe: false` in `printer_cartographer.cfg` is intentional. It prevents Cartographer from owning the stock `probe` object while still allowing `cartographer_probe:z_virtual_endstop` for Z homing.

If the hard requirement becomes "BD Pressure must never be used for QGL", this cannot be fixed by PRINT_START ordering alone. It requires an architecture change, such as making Cartographer the stock `[probe]` again or adding a named BD Pressure probe path separate from stock `[probe]`.

## 6. PRINT_START Flow

Current intended order:

```text
1. Reset runtime Z offset with `SET_GCODE_OFFSET Z=0`.
2. Filament sensors are monitor-only by default; `REQUIRE_FILAMENT=1` makes them hard-abort.
3. Start bed heat and hold nozzle at 150 C standby.
4. `G28` using Cartographer Z virtual endstop.
5. Wait for bed target.
6. Clean nozzle on rear brush at standby temperature.
7. `CQGL`; note this currently uses BD Pressure because QGL consumes stock `[probe]`.
8. `CARTOGRAPHER_TOUCH_HOME` after QGL.
9. `BED_MESH_CALIBRATE ADAPTIVE=1` using Cartographer mesh scan.
10. `CLEAN_NOZZLE` immediately after mesh to remove residue before BD final Z.
11. `SET_Z_FROM_PROBE` using BD Pressure final nozzle probe.
12. Skip BD Pressure PA calibration by default; only `PRINT_START RUN_PA=1` parks at upstream-style `Z30`, `X240 Y240` and runs `PA_CALIBRATE`.
13. If `RUN_PA=1`, clean nozzle again after PA air extrusion.
14. `SET_BDWIDTH NAME=fila_width_0 COMMAND=ENABLE`.
15. Confirm final nozzle temperature and run purge line.
```

Do not run full `PRINT_START` or `PA_CALIBRATE` without user approval because both can heat and extrude.

## 7. BD Pressure PA Policy

Active file: `printer_bd_pressure_usb.cfg`

Source-backed policy:

```text
PA_E exists upstream and is an internal helper.
Do not expose or forward PA_X0/PA_X1/PA_X2/PA_X3/PA_Y_START/PA_Y_STEP/PA_LINES unless a new source-backed reason exists.
PandaPi/BD Pressure docs show moving to high Z and a poop position, then calling PA_CALIBRATE.
The poop position is a pre-PA park position, not a rewrite of PA_E internal XY geometry.
```

Current `PRINT_START` PA policy:

```text
RUN_PA=0 by default; PRINT_START does not run PA_CALIBRATE on every print.
RUN_PA=1 opts into BD Pressure PA calibration before purge.
PA_SAFE_Z=30
PA_PARK_X=240
PA_PARK_Y=240
```

## 8. Filament Sensors

Active file: `printer_filament_sensors.cfg`

```text
extruder entry sensor: EBBusb PB6 -> `extruder_entry_filament`
extruder exit sensor:  EBBusb PB5 -> `extruder_exit_filament`
pause_on_runout: False for both until physical verification
PRINT_START default: monitor-only with `FILAMENT_STATUS`
PRINT_START REQUIRE_FILAMENT=1: calls `ASSERT_TOOLHEAD_FILAMENT` and hard-aborts if either sensor is false
```

The file `Klipper configs  Macros and sensor configs.txt` is obsolete example material only. It contains older EBBCan PB3/PB4 examples and must not be included directly.

## 9. Verification Commands

Safe verification that does not heat or move:

```bash
ssh sukbeom@192.168.0.29 'curl -s http://127.0.0.1:7125/printer/info'
ssh sukbeom@192.168.0.29 'curl -s http://127.0.0.1:7125/printer/gcode/help | grep -E "PA_CALIBRATE|PA_E|PRINT_START|SET_Z_FROM_PROBE|CARTOGRAPHER_TOUCH_HOME|SET_BDWIDTH|FILAMENT_STATUS"'
ssh sukbeom@192.168.0.29 'curl -s "http://127.0.0.1:7125/printer/objects/query?probe&cartographer&bdpressure%20bd_pa&bdwidth%20fila_width_0&filament_switch_sensor%20extruder_entry_filament&filament_switch_sensor%20extruder_exit_filament"'
```

Expected high-level state after config-only edits:

```text
/printer/info state: ready
probe object exists and is BD Pressure-backed
cartographer object exists
bdpressure bd_pa state: STOP
bdwidth fila_width_0 object exists
filament_switch_sensor extruder_entry_filament exists
filament_switch_sensor extruder_exit_filament exists
```
