# BD Pressure + Cartographer + BD Width PRINT_START Audit Plan

Status: implemented inline on 2026-06-12 Asia/Seoul.

## Implemented Outcomes

1. USB serial paths were rediscovered after hub replacement and remapped by-path for CH340 devices.
2. Moonraker startup was restored by removing the duplicate active `[mcu_flasher ebb_usb]` section from `moonraker.conf`; the file still has unrelated dirty history and must be reviewed before staging.
3. BD Pressure PA flow was restored to upstream-style behavior: `PRINT_START` parks at `Z30`, `X240 Y240`, then calls `PA_CALIBRATE` without forwarding custom PA_E geometry parameters.
4. `SET_Z_FROM_PROBE` was moved to immediately after `BED_MESH_CALIBRATE ADAPTIVE=1` and post-mesh `CLEAN_NOZZLE`.
5. PA now runs after final Z, followed by nozzle cleaning, BD Width enable, final heating, and purge.
6. Filament sensors PB6/PB5 remain configured but are monitor-only by default; `PRINT_START REQUIRE_FILAMENT=1` opts into hard-abort.
7. QGL ownership is documented: current stock `QUAD_GANTRY_LEVEL` uses BD Pressure because BD owns standard `[probe]`.
8. `context/README.md` was added as the current runtime/config index for future agents.

## Safe Verification

Do not run full `PRINT_START` or `PA_CALIBRATE` without user approval because they can heat and extrude.

Safe checks:

```bash
curl -s http://127.0.0.1:7125/printer/info
curl -s http://127.0.0.1:7125/printer/gcode/help
curl -s "http://127.0.0.1:7125/printer/objects/query?probe&cartographer&bdpressure%20bd_pa&bdwidth%20fila_width_0&filament_switch_sensor%20extruder_entry_filament&filament_switch_sensor%20extruder_exit_filament"
```
