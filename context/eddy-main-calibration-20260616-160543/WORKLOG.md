# Eddy Main Calibration Save

## Summary
- Saved BTT Eddy Duo main distance calibration with Klipper SAVE_CONFIG.
- Klipper restarted and returned to ready state.
- Generated calibration data is stored in the printer.cfg SAVE_CONFIG block.
- Eddy temperature calibration reference recorded as 42.517413 C.

## Observed Values
- User-reported Z calibration temperature: 42.52 C
- User-reported total frequency range: 28435.294 Hz
- Saved probe_eddy_current btt_eddy.reg_drive_current: 16
- Saved temperature_probe btt_eddy.calibration_temp: 42.517413

## Verification
- Moonraker printer/info returned ready after restart.
- probe_eddy_current btt_eddy runtime object is present.
- temperature_probe btt_eddy runtime object is present and not in calibration mode.
- Klippy log shows eddy MCU configured after restart.

## Safety Notes
- Main Eddy distance calibration is persisted.
- Temperature drift compensation is still disabled because no drift calibration is configured.
- Do not run full PRINT_START, QGL, or mesh until Z homing is tested deliberately after this save.
- Tap calibration remains separate and should be done only after normal Eddy Z homing is verified.

## Files Captured
- printer-info-after-save.json: Moonraker printer info after restart.
- objects-eddy-after-save.json: Eddy probe and temperature probe runtime objects.
- klippy-tail-after-save.log: Klippy log tail after restart.
- config-diff-after-save.patch: Git diff containing SAVE_CONFIG calibration block.
- git-status-after-save.txt: Git status at capture time.
- save-config-backups.txt: Klipper SAVE_CONFIG backup file list.
- printer-saveconfig-backup-20260616_160343.cfg: Copy of automatic pre-save backup file.
- printer-current-after-save.cfg: Current printer.cfg snapshot after SAVE_CONFIG.
