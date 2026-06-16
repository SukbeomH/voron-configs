# Eddy Temperature Compensation Setup

Date: 2026-06-16

## Change
- Added temperature drift calibration automation options to printer_eddy.cfg [temperature_probe btt_eddy].
- No printer restart, heater command, homing, probing, or movement was executed during this config edit.

## Current Live State Before Edit
- temperature_probe btt_eddy compensation_enabled was false.
- temperature_probe btt_eddy current temperature was about 48.9C, so calibration should start later from cold.

## Intended Calibration Command After Restart And Cooldown
- TEMPERATURE_PROBE_CALIBRATE PROBE=btt_eddy TARGET=80 STEP=2 METHOD=tap
- Use TEMPERATURE_PROBE_COMPLETE if coil temperature plateaus below target.
- SAVE_CONFIG after calibration completes, then commit the generated drift_calibration block.
