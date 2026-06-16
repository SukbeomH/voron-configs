# Eddy Z Homing Fake Position Fix

## Symptom
- User observed Z homing moving too fast and happening at a corner instead of the expected safe Z home position.

## Evidence
- Runtime toolhead state reported homed_axes=xyz and position 0,0,0 after restart even without deliberate physical homing.
- Active config included [delayed_gcode KINEMATIC_POSITION] from plr.cfg.
- That delayed gcode ran SET_KINEMATIC_POSITION X=0, Y=0, Z=0 after 0.2 seconds.
- Klippy log after restart showed repeated SET_KINEMATIC_POSITION pos=0.000,0.000,0.000 set_homed=xyz.

## Root Cause
- The PLR startup helper was automatically marking all axes as homed at machine origin.
- This invalidated the position trust required before safe Z homing with the new Eddy probe.

## Change
- Set plr.cfg delayed_gcode KINEMATIC_POSITION initial_duration to 0 so it does not run automatically after startup.
- Kept PLR file included and kept manual SET_FAKE_Z macro available.

## Validation Target
- After restart, printer should be ready with homed_axes empty, not xyz.
- Next physical test should be explicit G28 X Y followed by G28 Z under user observation.
