# Foundation Actor Loop Implementation Guide

## Goal

Create the smallest reusable actor-controller loop that can be owned by `obj_player` without putting movement logic in the object event. This feature establishes constants, enums, core structs, default stats, a controller update shell, instance sync, and initial debug text.

## Dependencies

- Read [shared_agent_rules.md](shared_agent_rules.md).
- No previous feature guides are required.

## Implementation Scope

Implement only the generic foundation. Do not implement real platforming physics, spray, slopes, walls, ledges, slide, or advanced collision in this guide.

Required GameMaker assets:

- `actor_controller_constants.gml`
- `actor_controller_enums.gml`
- `actor_controller_structs.gml`
- `actor_controller_stats.gml`
- `actor_controller_input.gml`
- `actor_controller_core.gml`
- `actor_controller_debug.gml`
- minimal `player_input.gml` and `player_stats.gml`, if player-specific scripts do not already exist
- minimal `obj_player` Create, Step, and Draw/Draw GUI event forwarding

## Data and Function Responsibilities

- Define version, debug, simulation, assist timing, and spray default macros.
- Define required enums and ability flags from the shared rules.
- Add constructors for `ActorStats`, `ActorInputFrame`, `ActorController`, `ActorForce`, `ActorSurfaceInfo`, and `ActorContactInfo`.
- Add `actor_stats_create_default()`, `actor_stats_create_player_elephant()`, `actor_stats_clone()`, and `actor_stats_validate()` with placeholder validation.
- Add `actor_input_frame_create_empty()` and `player_input_build_frame()` with movement/jump/spray/aim fields populated as data.
- Add `actor_controller_create()`, `actor_controller_update()`, `actor_controller_begin_step()`, `actor_controller_end_step()`, `actor_controller_set_position()`, `actor_controller_set_velocity()`, and `actor_controller_apply_to_instance()`.
- Make `actor_controller_update()` cache previous frame data, clear one-frame events, store input, and return the actor without advanced movement.
- Add `actor_controller_debug_print_state()` or equivalent draw text showing state, position, velocity, grounded flags, timers, spray, water, and charge fields even if many values are still defaults.

## Acceptance Criteria

- `obj_player` creates elephant player stats and a generic `ActorController` at its instance position.
- `obj_player` Step builds an `ActorInputFrame`, calls `actor_controller_update()`, and applies controller position back to the instance.
- Controller state uses enums, not strings.
- Tuning defaults live in stats or macros.
- Debug text can be toggled and renders without errors.
- Every new function has full JSDoc.

## Testing Checklist

- Start a room containing `obj_player` and confirm no create/step/draw errors.
- Confirm controller `x/y` and instance `x/y` stay synchronized.
- Confirm input frame fields change when pressing movement, jump, spray, and aim controls.
- Confirm debug text shows controller version, state, position, velocity, grounded flags, timers, water, and charge.
- Review object events to confirm they only create data, call controller functions, apply outputs, and draw debug.

## Definition of Done

The player object is driven by a generic controller struct, the core data model exists, debug text exposes the runtime shell, and no mechanic beyond the minimal loop has been implemented.
