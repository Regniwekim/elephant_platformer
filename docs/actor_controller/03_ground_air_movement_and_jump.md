# Ground, Air Movement, and Jump Implementation Guide

## Goal

Implement responsive basic platforming: ground acceleration, air control, gravity, fall behavior, jump execution, variable jump height, and landing detection.

## Dependencies

- [shared_agent_rules.md](shared_agent_rules.md)
- [01_input_frames_and_assist_timers.md](01_input_frames_and_assist_timers.md)
- [02_solid_collision_and_contacts.md](02_solid_collision_and_contacts.md)

## Implementation Scope

Implement flat-ground movement and standard jumps. Do not implement slopes, moving platforms, spray recoil, wall movement, ledges, slide, or charged launch in this guide.

Required scripts:

- `actor_controller_state.gml`
- `actor_controller_jump.gml`
- `actor_controller_core.gml`
- `actor_controller_collision.gml`

## Data and Function Responsibilities

- Add or finalize state helpers: `actor_controller_set_state()`, `actor_controller_is_state()`, `actor_controller_update_state()`, `actor_controller_can_enter_state()`, and `actor_controller_get_state_name()`.
- Apply ground movement with walk/run target speed, ground accel, decel, turn accel, and friction.
- Apply air movement with air max speed, air accel, air decel, and air turn accel.
- Apply gravity using separate rise and fall values plus `max_fall_speed`.
- Implement `actor_controller_can_jump()`, `actor_controller_try_jump()`, `actor_controller_execute_jump()`, `actor_controller_apply_jump_cut()`, and `actor_controller_handle_landing()`.
- Consume jump buffer and coyote time only when a jump actually executes.
- Emit jump and landing events if event infrastructure already exists; otherwise record placeholder one-frame flags for guide 11 to formalize.

## Acceptance Criteria

- Actor accelerates, decelerates, and reverses direction predictably on flat ground.
- Air control is weaker than ground control and tunable through stats.
- Gravity uses different rise/fall tuning and respects fall speed cap.
- Jump buffer and ground coyote time work with actual jump execution.
- Releasing jump early produces a shorter hop through jump cut behavior.
- Landing is detected from physical contact transition, not from state names alone.

## Testing Checklist

- Walk left and right from rest.
- Release input and verify deceleration/friction.
- Reverse direction and verify turn acceleration.
- Jump while standing and while running.
- Release jump early and confirm short hop.
- Press jump shortly before landing and confirm buffered jump.
- Walk off a ledge and press jump within coyote time.
- Fall for several seconds and confirm fall speed is capped.

## Definition of Done

The actor can run, jump, short-hop, fall, land, and collide reliably on flat solids without spray or advanced movement systems.
