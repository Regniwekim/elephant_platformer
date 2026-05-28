# External Forces and Velocity Model Implementation Guide

## Goal

Separate actor-controlled velocity from external velocity so recoil, knockback, moving platforms, bounce, and scripted impulses can coexist with normal movement caps.

## Dependencies

- [shared_agent_rules.md](shared_agent_rules.md)
- [03_ground_air_movement_and_jump.md](03_ground_air_movement_and_jump.md)

## Implementation Scope

Implement the generic force system and velocity layering. Do not implement spray-specific water cost or recoil rules here; guide 6 will use this foundation.

Required scripts:

- `actor_controller_forces.gml`
- `actor_controller_core.gml`
- `actor_controller_structs.gml`
- `actor_controller_debug.gml`

## Data and Function Responsibilities

- Preserve `hsp/vsp` for actor-controlled movement and `external_hsp/external_vsp` for recoil, platform carry, bounce, knockback, and scripted forces.
- Add or finalize `ActorForce` with type, vector, duration, damping, control reduction, source id, and optional metadata.
- Implement `actor_force_create()`, `actor_controller_add_force()`, `actor_controller_clear_forces()`, `actor_controller_update_forces()`, and `actor_controller_apply_external_forces()`.
- Support additive, impulse, override, continuous, platform carry, and knockback force types.
- Apply normal movement caps to controlled velocity, not to external velocity unless a hard safety cap is needed.
- Apply `ACTOR_HARD_SPEED_CAP` as a final safety clamp to total velocity.
- Make control reduction explicit and data-driven, never a hidden side effect.

## Acceptance Criteria

- External impulses can push the actor beyond normal run speed without changing run-speed tuning.
- Continuous forces update for their configured duration and then expire.
- Damping reduces external velocity predictably.
- Platform carry can be represented without overwriting actor input velocity.
- Knockback can reduce control through explicit force data.
- Debug output lists active forces and controlled vs external velocity.

## Testing Checklist

- Add a horizontal impulse and verify external velocity changes.
- Add a vertical impulse and verify collision still resolves.
- Apply a continuous force for a fixed duration and confirm it expires.
- Apply damping and verify external velocity trends toward zero.
- Confirm ground/air movement still caps `hsp`, not total velocity.
- Confirm total velocity cannot exceed the hard safety cap.

## Definition of Done

The controller has a reusable velocity and force model that later systems can use without corrupting normal movement tuning.
