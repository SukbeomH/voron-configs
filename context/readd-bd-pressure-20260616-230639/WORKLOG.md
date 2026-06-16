# Re-add BD Pressure PA Sensor - 2026-06-16

## Scope
- Confirmed the re-added BD Pressure CH340 adapter at by-path 1.2.1 -> ttyUSB0.
- Re-enabled [include printer_bd_pressure_usb.cfg] in printer.cfg.
- Kept BDWidth disabled by leaving printer_bdwidth.cfg commented out.
- Kept filament and runout sensors disabled by leaving printer_filament_sensors.cfg commented out.
- Kept BTT Eddy as the stock probe owner. BD Pressure remains PA-only.

## Operational notes
- No Klipper restart was requested or run.
- No motion, homing, heater, or calibration commands were run.
- The bdpressure object will only become active after the next Klipper restart.
- Existing variables.cfg runtime state change was not staged.
- Existing root-level backup files and update_plr.cfg were not staged.

## Files captured
- printer-before.cfg / printer-after.cfg
- printer_bd_pressure_usb-before.cfg / printer_bd_pressure_usb-after.cfg
- serial-before.txt
- objects-before.json
- printer-info-before.json
- git-status-before.txt / git-status-after-edit.txt
- config-diff.patch
