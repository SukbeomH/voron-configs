# Eddy hardware phase 1 verification - 20260616-141126

## Summary
- Main MCU and EBB USB devices are visible again.
- BTT Eddy Duo is still not visible as a USB serial device, RP2040 USB device, or BOOTSEL mass-storage device.
- Klipper remains stopped on mcu eddy connection because the configured serial path does not exist yet.

## Next hardware checks
1. Verify Eddy Duo USB-C cable is a data cable and is connected to the Pi/hub.
2. Put Eddy Duo into BOOTSEL mode while plugging USB; host should show RPI-RP2 or vendor 2e8a.
3. After Eddy enumerates, flash Klipper RP2040 USB firmware and update printer_eddy.cfg serial if needed.
