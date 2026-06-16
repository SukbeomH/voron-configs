# Bed Mesh Default Save

## Summary
- Committed the successful default bed mesh generated after reducing rear mesh clearance.
- Mesh scan completed with rear limit mesh_max Y near 210.
- No motion command, RESTART, or FIRMWARE_RESTART was run during this commit.

## Runtime State Captured
- bed_mesh.profile_name: default
- bed_mesh mesh_min: 15,25
- bed_mesh mesh_max: 235,209.96000000000004
- probe_count: 9 by 9
- quad_gantry_level.applied: true
- toolhead position at capture: X125 Y120 Z8

## Config Change
- printer.cfg gained SAVE_CONFIG block [bed_mesh default].
- Saved mesh uses bicubic interpolation with mesh_x_pps=2 and mesh_y_pps=2.

## Files Captured
- config-diff.patch: SAVE_CONFIG bed mesh diff.
- printer-current.cfg: current printer.cfg including saved mesh.
- printer-saveconfig-backup-20260616_163800.cfg: automatic backup from Klipper SAVE_CONFIG.
- objects-current.json: Moonraker runtime object snapshot.
- printer-info-current.json: Moonraker printer info.
- klippy-tail-current.log: recent Klippy log tail.
- save-config-backups.txt: current 20260616 SAVE_CONFIG backups.

## Next Step
- Small first-layer print test under direct observation.
- Adjust Z offset only after observing first-layer result.
