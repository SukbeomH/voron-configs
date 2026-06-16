# Eddy cable swap ready verification - 20260616-152612

## Summary
- Eddy Duo now enumerates as /dev/serial/by-id/usb-Klipper_rp2040_50445059387D401C-if00.
- printer_eddy.cfg serial updated to the real Eddy by-id.
- BDWidth CH340 moved from by-path 1.2.1 to 1.2.3.1 after USB cabling changed.
- FIRMWARE_RESTART returned Moonraker printer/info state ready.

## Remaining setup
- Run Eddy calibrations before real probing/printing.
- Do not delete Cartographer/BD Pressure plugin files until Eddy homing, mesh scan, and first print are verified.
