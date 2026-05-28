# Slide / Belly Slide Implementation Guide

## Goal

Add slide movement with reduced collision height, low-ceiling handling, momentum preservation, and compatibility with spray and normal controller state.

## Dependencies

- [shared_agent_rules.md](shared_agent_rules.md)
- [03_ground_air_movement_and_jump.md](03_ground_air_movement_and_jump.md)
- [05_external_forces_and_velocity_model.md](05_external_forces_and_velocity_model.md)

## Implementation Scope

Implement grounded slide behavior. Do not implement ledge, wall, or new spray modes here.

Required scripts:

- `actor_controller_slide.gml`
- `actor_controller_state.gml`
- `actor_controller_collision.gml`
- `actor_controller_debug.gml`

## Data and Function Responsibilities

- Add slide stats for reduced height, minimum entry speed, friction, duration if used, exit speed, jump behavior, and ceiling clearance.
- Track slide active state, slide timer, previous collision height, and stand-up blocked state.
- Implement `actor_controller_can_slide()`, `actor_controller_try_slide()`, `actor_controller_update_slide()`, `actor_controller_can_stand_from_slide()`, and `actor_controller_end_slide()`.
- Change collision dimensions through controller stats/state, not through arbitrary sprite dimensions.
- Preserve momentum on slide entry and apply tunable slide friction.
- Prevent standing when ceiling clearance is blocked.
- Allow spray while sliding if the actor has spray ability; do not add special-case elephant logic.
- Emit or record slide start and slide end events.

## Acceptance Criteria

- Actor enters slide only when grounded, allowed by ability flags, and meeting input/stat requirements.
- Collision height reduces while sliding and restores only when stand-up clearance is available.
- Slide preserves meaningful momentum and does not instantly stop unless stats say so.
- Actor can pass under low ceilings while sliding.
- Actor remains sliding if stand-up is blocked.
- Spray can operate during slide using generic spray rules.

## Testing Checklist

- Start slide from rest if allowed by stats, or verify it fails if minimum speed is required.
- Start slide while running and verify momentum is preserved.
- Slide under a low ceiling.
- Attempt to stand under a low ceiling and verify stand-up is blocked.
- Exit slide after clearance is available.
- Jump from slide if stats allow it.
- Spray while sliding and verify no special object-event logic is needed.

## Definition of Done

Slide is a reusable actor capability with safe collision resizing, ceiling handling, momentum-preserving movement, and clean integration with spray and events.
