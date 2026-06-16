# PLR Resume Interrupted Kinematic Position

## Request
- Keep startup fake kinematic homing disabled.
- Run the PLR kinematic position setup only when the interrupt resume macro is used.
- Do not restart Klipper during this change.

## Change
- Left delayed_gcode KINEMATIC_POSITION initial_duration at 0.
- Added SET_KINEMATIC_POSITION X=0, Y=0, Z=0 at the start of RESUME_INTERRUPTED.
- The PLR resume shell command and SDCARD_PRINT_FILE sequence remain unchanged.

## Verification Without Restart
- Reviewed plr.cfg diff: only RESUME_INTERRUPTED gained the three SET_KINEMATIC_POSITION lines.
- Ran git diff --check with no output/errors.
- Did not run RESTART or FIRMWARE_RESTART per user instruction.

## Operational Note
- This change will take effect after the next normal Klipper config reload/restart.
- Normal homing remains protected because startup delayed fake-home stays disabled.
