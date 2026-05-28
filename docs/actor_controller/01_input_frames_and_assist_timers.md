# Input Frames and Assist Timers Implementation Guide

## Goal

Make input source-agnostic and add the first feel helpers: button edges, jump buffering, and coyote timers. The controller must consume `ActorInputFrame` data only.

## Dependencies

- [shared_agent_rules.md](shared_agent_rules.md)
- [00_foundation_actor_loop.md](00_foundation_actor_loop.md)

## Implementation Scope

Implement player and AI/script input frame helpers plus controller-owned assist timers. Do not implement jump execution here except for timer consumption helpers needed by later guides.

Required scripts:

- `actor_controller_input.gml`
- `actor_controller_core.gml`
- timer helpers in `actor_controller_jump.gml` or `actor_controller_state.gml`
- `player_input.gml`
- optional `ai_actor_input.gml`

## Data and Function Responsibilities

- Ensure `ActorInputFrame` includes movement axes, jump, slide, spray, charge, cancel, drop, aim, nozzle commands, source metadata, and raw input fields.
- Normalize `move_x/move_y` and `aim_x/aim_y` through `actor_input_frame_normalize()`.
- Implement button edge fields such as `jump_pressed`, `jump_held`, and `jump_released` in the input builder, not in movement code.
- Add `ai_actor_input_build_frame()` or a script input builder returning the same struct shape as player input.
- Implement `actor_controller_update_timers()`, `actor_controller_update_jump_buffer()`, `actor_controller_update_coyote_timers()`, `actor_controller_consume_jump_buffer()`, and `actor_controller_can_use_ground_coyote()`.
- Track ground, wall, ledge, drop-through, and wall-jump lockout timers as fields on `ActorController`, even if later guides are the first to use some of them.
- Update coyote timers from physical contact fields, not from high-level state names.

## Acceptance Criteria

- Controller code never calls raw keyboard, mouse, or gamepad APIs.
- Player and AI/script input builders produce compatible `ActorInputFrame` structs.
- `jump_pressed` sets `jump_buffer_timer` to `stats.jump_buffer_frames`.
- Timers decrement deterministically once per controller update.
- Physical grounded refreshes `ground_coyote_timer`; losing ground decrements it.
- Consuming jump buffer and coyote time clears the relevant timers.

## Testing Checklist

- Press and hold jump; verify pressed is true for one frame and held remains true.
- Release jump; verify released is true for one frame.
- Press jump before landing; verify jump buffer timer is set and decrements.
- Stand on ground; verify ground coyote timer refreshes.
- Leave ground; verify physical grounded becomes false while coyote timer remains available briefly.
- Build a dummy AI input frame and verify it can be passed to `actor_controller_update()`.

## Definition of Done

All controller input is data-driven, assist timers are centralized and tunable, and later movement guides can consume jump buffer and coyote state without reading raw input.
