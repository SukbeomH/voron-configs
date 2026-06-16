# Bed Mesh Rear Brush Clearance

## Summary
- User reported scan mesh completed normally but the toolhead/nozzle area collided with the rear nozzle brush during mesh scan.
- Reduced rear bed mesh probe limit to avoid the rear brush area.
- No motion command, RESTART, or FIRMWARE_RESTART was run during this change.

## Change
- printer.cfg [bed_mesh] mesh_max changed from 235,235 to 235,210.
- Eddy y_offset is 21.42, so the rear-most mesh scan toolhead Y changes from about 213.58 to about 188.58.
- zero_reference_position remains 120,120.
- probe_count remains 9,9 for now.

## Rationale
- The collision is rear-side physical interference, so the minimum scoped fix is lowering mesh_max Y.
- X range was not changed because the reported collision is with the rear brush, not left/right travel.

## Next Validation
- Reload config before the next mesh test.
- After reload, run BED_MESH_CALIBRATE METHOD=scan under direct observation.
- If the carriage still approaches the brush, lower mesh_max Y again, likely to 200.
