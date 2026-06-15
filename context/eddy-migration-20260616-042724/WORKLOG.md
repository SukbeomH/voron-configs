# Eddy migration work log

timestamp: 20260616-042724
host: voronrpi4b
config_path: /home/sukbeom/printer_data/config
branch_before: master
head_before: f7e147d

Initial observation: Eddy USB/RP2040 not visible under /dev/serial/by-id at start of implementation.

User instruction: proceed linearly on master; no separate branch.
Implementation note: Eddy USB is not present yet, so serial must be verified after connecting/flashing Eddy Duo.

Applied config edits:
- Added printer_eddy.cfg for BTT Eddy Duo USB on mainline Klipper.
- Removed active Cartographer and BD Pressure includes from printer.cfg.
- Replaced Cartographer touch macro calls with Eddy-compatible G28 Z re-home calls.
- Removed BD Pressure PA calibration path from PRINT_START and FILAMENT_STATUS.
- Kept BDWidth active.
- Removed stale Cartographer/old mesh SAVE_CONFIG sections after backup.

Post-edit checks:

Serial devices:
total 0
lrwxrwxrwx 1 root root 13 Jun 16 01:43 usb-1a86_USB_Serial-if00-port0 -> ../../ttyUSB2

Verification after FIRMWARE_RESTART:
{"result":{"state":"startup","state_message":"\nPrinter is not ready\nThe klippy host software is attempting to connect.  Please\nretry in a few moments.\n","hostname":"voronrpi4b","klipper_path":"/home/sukbeom/klipper","python_path":"/home/sukbeom/klippy-env/bin/python","process_id":1958,"user_id":1000,"group_id":1000,"log_file":"/home/sukbeom/printer_data/logs/klippy.log","config_file":"/home/sukbeom/printer_data/config/printer.cfg","software_version":"v0.13.0-699-gc707dd19-dirty","cpu_info":"4 core ?"}}
Observed blocker: main MCU configured as by-path 1.2.4 is not present; dmesg shows ttyUSB1 / usb 1-1.2.4 disconnected. Eddy USB/RP2040 is also not present yet.
Current /dev/serial/by-id:
total 0
lrwxrwxrwx 1 root root 13 Jun 16 01:43 usb-1a86_USB_Serial-if00-port0 -> ../../ttyUSB2
Current /dev/serial/by-path:
total 0
lrwxrwxrwx 1 root root 13 Jun 16 01:33 platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.1:1.0-port0 -> ../../ttyUSB0
lrwxrwxrwx 1 root root 13 Jun 16 01:33 platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.2.3.1:1.0-port0 -> ../../ttyUSB2
lrwxrwxrwx 1 root root 13 Jun 16 01:33 platform-fd500000.pcie-pci-0000:01:00.0-usbv2-0:1.2.1:1.0-port0 -> ../../ttyUSB0
lrwxrwxrwx 1 root root 13 Jun 16 01:33 platform-fd500000.pcie-pci-0000:01:00.0-usbv2-0:1.2.3.1:1.0-port0 -> ../../ttyUSB2

Git history:
pre_migration_checkpoint_commit: 9450808
