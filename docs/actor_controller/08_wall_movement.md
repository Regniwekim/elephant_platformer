# Wall Movement Implementation Guide

## Goal

Add wall contact behavior: wall detection, wall slide, wall coyote, and wall jump. Wall movement should feel responsive without overriding the generic movement foundation.

## Dependencies

- [shared_agent_rules.md](shared_agent_rules.md)
- [03_ground_air_movement_and_jump.md](03_ground_air_movement_and_jump.md)
- [05_external_forces_and_velocity_model.md](05_external_forces_and_velocity_model.md)

## Implementation Scope

Implement wall slide and wall jump only. Do not implement ledge grab, mantle, slide, or wall-specific spray interactions in this guide.

Required scripts:

- `actor_controller_wall.gml`
- `actor_controller_state.gml`
- `actor_controller_jump.gml`
- `actor_controller_collision.gml`

## Data and Function Responsibilities

- Track wall left/right, wall normal, wall object, wall coyote timer, wall slide speed, and wall jump lockout timer.
- Implement `actor_controller_update_wall_contact()`, `actor_controller_can_wall_slide()`, `actor_controller_try_enter_wall_slide()`, `actor_controller_can_wall_jump()`, `actor_controller_try_wall_jump()`, and `actor_controller_execute_wall_jump()`.
- Enter wall slide only when airborne, touching a valid wall, moving downward or pressing into the wall as configured, and the ability flag allows it.
- Apply wall slide fall speed cap through stats.
- Execute wall jump as an explicit velocity or force change away from the wall.
- Use wall jump lockout to prevent immediate regrab or input reversal from cancelling the jump.
- Emit or record wall slide start and wall jump events.

## Acceptance Criteria

- Actor detects walls on left and right independently.
- Wall slide slows falling when conditions are met.
- Actor exits wall slide when losing contact, landing, jumping, or failing ability checks.
- Wall coyote allows a short grace window for wall jump.
- Wall jump launches away from the contacted wall and respects lockout timing.
- Actors without wall ability flags cannot wall slide or wall jump.

## Testing Checklist

- Fall next to a wall and verify wall contact side.
- Press into wall while falling and verify wall slide starts.
- Release wall or move away and verify wall slide ends.
- Jump during wall slide and verify launch away from wall.
- Leave wall and jump within wall coyote time.
- Try wall jump after coyote expires and verify it fails.
- Disable wall ability flags and verify behavior is unavailable.

## Definition of Done

Wall slide and wall jump are generic, stat-driven, event-visible, and integrated with the existing jump, state, collision, and force systems.
