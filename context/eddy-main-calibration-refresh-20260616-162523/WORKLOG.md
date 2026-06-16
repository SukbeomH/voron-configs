# Eddy Main Calibration Refresh

## Summary
- Committed the latest uncommitted Eddy SAVE_CONFIG calibration values from printer.cfg.
- Captured the latest Klipper SAVE_CONFIG backup printer-20260616_161901.cfg inside this context directory.
- Did not run motion commands or restart Klipper during this commit.

## New Saved Values
- temperature_probe btt_eddy calibration_temp: 42.930078
- probe_eddy_current btt_eddy reg_drive_current remains: 16
- Calibration table was replaced by the latest SAVE_CONFIG output.

## Runtime Snapshot
- Printer info and Eddy runtime objects were captured before commit.
- Current runtime reported toolhead homed at X125 Y120 Z3.690921499997478.
- quad_gantry_level.applied was false and bed mesh profile was empty at capture time.

## Files Captured
- config-diff.patch: printer.cfg SAVE_CONFIG diff.
- printer-current.cfg: current printer.cfg snapshot.
- printer-saveconfig-backup-20260616_161901.cfg: copy of latest automatic Klipper backup.
- objects-current.json: Moonraker object snapshot.
- printer-info-current.json: Moonraker printer info.
- klippy-tail-current.log: Klippy log tail.
- save-config-backups.txt: available 20260616 SAVE_CONFIG backups.

## Additional Captured Value
- Current printer.cfg also includes probe_eddy_current btt_eddy tap_threshold: 1477.172.
- Latest automatic Klipper backup printer-20260616_162515.cfg was copied into this context directory.
