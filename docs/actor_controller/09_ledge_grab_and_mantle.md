# Ledge Grab and Mantle Implementation Guide

## Goal

Add ledge grab and mantle as optional actor capabilities that help low-speed traversal without stealing control during fast movement or spray-driven routes.

## Dependencies

- [shared_agent_rules.md](shared_agent_rules.md)
- [03_ground_air_movement_and_jump.md](03_ground_air_movement_and_jump.md)
- [08_wall_movement.md](08_wall_movement.md)

## Implementation Scope

Implement ledge detection, ledge grab, and mantle. Do not implement slide or new wall movement behavior here.

Required scripts:

- `actor_controller_ledge.gml`
- `actor_controller_state.gml`
- `actor_controller_collision.gml`
- `actor_controller_debug.gml`

## Data and Function Responsibilities

- Track ledge candidate position, ledge normal, ledge object, ledge coyote timer, mantle start/end positions, mantle timer, and time in state.
- Implement `actor_controller_find_ledge()`, `actor_controller_can_ledge_grab()`, `actor_controller_try_ledge_grab()`, `actor_controller_start_mantle()`, `actor_controller_update_mantle()`, and `actor_controller_finish_mantle()`.
- Use wall and clearance probes to confirm a reachable ledge and enough space to stand.
- Gate ledge grab by ability flag, movement state, input intent, vertical direction, and maximum grab speed.
- Do not grab ledges at high speed when doing so would interrupt spray or speedrun expression.
- Keep mantle deterministic and short; do not rely on animation timing for physics.
- Emit or record ledge grab and mantle events.

## Acceptance Criteria

- Actor can grab a valid ledge at low or moderate speed.
- Actor does not grab ledges when moving too fast for the configured threshold.
- Ledge grab requires valid wall/ledge geometry and stand-up clearance.
- Mantle moves the actor to a valid stand position without clipping.
- Actor can cancel or exit ledge state according to input/state rules.
- Actors without ledge ability flag cannot ledge grab.

## Testing Checklist

- Approach a ledge slowly and verify grab.
- Approach the same ledge at high speed and verify no forced grab.
- Mantle from a grabbed ledge and verify final standing position.
- Try grabbing with blocked stand-up space and verify it fails.
- Lose ledge contact and verify state exits.
- Disable ledge ability flag and verify behavior is unavailable.
- Confirm debug draw shows ledge probes and candidate data.

## Definition of Done

Ledge grab and mantle are optional, probe-driven, stat-gated movement assists that never override high-speed movement expression.
