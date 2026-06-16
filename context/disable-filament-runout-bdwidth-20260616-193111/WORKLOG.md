# Disable Filament Runout And BDWidth

Date: 2026-06-16

## Scope
- Commented out printer_bdwidth.cfg include in printer.cfg.
- Commented out printer_filament_sensors.cfg include in printer.cfg.
- Commented PRINT_START filament status/assertion behavior and replaced it with a disabled warning.
- Commented PRINT_START/PRINT_END SET_BDWIDTH calls so macros do not reference an undefined object after restart.

## Runtime
- Sent SET_BDWIDTH NAME=fila_width_0 COMMAND=DISABLE once before config edits; no motion or restart was executed.
- Existing filament_switch_sensor extruder_exit_filament runtime state was already enabled=false.

## Notes
- printer_bdwidth.cfg and printer_filament_sensors.cfg were left intact as recovery references, but are no longer included.
- variables.cfg had unrelated last_file filepath changes before this work and was intentionally not staged.
