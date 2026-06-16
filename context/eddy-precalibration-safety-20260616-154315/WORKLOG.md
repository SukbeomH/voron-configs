# Eddy pre-calibration safety gate - 20260616-154315

## Summary
- Printer remained ready after Eddy/BDWidth serial updates.
- Eddy object is present, but main probe calibration is not complete yet.
- QUERY_PROBE is not supported by probe_eddy_current.
- Current toolhead homed_axes is empty and all steppers are disabled, so displayed XYZ must not be treated as reliable physical position.
- Motion calibration is gated on local physical confirmation of nozzle/probe clearance.

## Next safe operator check
Confirm at the printer that nozzle is clear of the bed by at least several millimeters and that Eddy/mount/cable do not interfere before any G28 X/Y or manual calibration motion.
