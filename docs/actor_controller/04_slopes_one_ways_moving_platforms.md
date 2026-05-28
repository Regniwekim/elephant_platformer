# Slopes, One-Ways, and Moving Platforms Implementation Guide

## Goal

Extend basic platforming to common terrain: slopes, one-way platforms, drop-through, and moving platforms. Movement must remain stable and collision-safe.

## Dependencies

- [shared_agent_rules.md](shared_agent_rules.md)
- [02_solid_collision_and_contacts.md](02_solid_collision_and_contacts.md)
- [03_ground_air_movement_and_jump.md](03_ground_air_movement_and_jump.md)

## Implementation Scope

Implement terrain and platform behavior. Do not implement water spray, charged launch, wall movement, ledge grab, or slide here.

Required scripts/objects:

- `actor_controller_collision.gml`
- `actor_controller_surfaces.gml`
- `actor_controller_core.gml`
- `obj_one_way_platform`
- `obj_moving_platform`
- optional `obj_surface_zone`

## Data and Function Responsibilities

- Add `ActorSurfaceInfo` fields for surface type, friction, accel, top speed, jump, recoil, conveyor, hazard, and refill modifiers.
- Implement `actor_collision_resolve_slope()`, `actor_collision_snap_to_ground()`, `actor_collision_get_slope_info()`, `actor_collision_place_one_way()`, and one-way ignore/drop-through handling.
- Track ground normal, ground angle, slope tangent, ground object, platform object, platform velocity, and drop-through timer.
- Project grounded movement along slope tangent when valid.
- Snap to ground only when moving across walkable slopes and not launching upward.
- Allow jumping through one-way platforms from below and landing from above.
- Implement moving platform carry without bypassing collision safety.
- Add platform jump inheritance through explicit velocity or force fields.

## Acceptance Criteria

- Actor walks up and down supported slopes without jitter.
- Slope snap does not cancel intentional jump launch.
- Actor lands on one-way platforms from above and passes through from below.
- Drop-through ignores the selected one-way platform for a tunable timer.
- Actor rides horizontal and vertical moving platforms.
- Jumping from a moving platform inherits platform velocity in a controlled way.

## Testing Checklist

- Walk up and down shallow slopes.
- Move across slope seams and flat-to-slope transitions.
- Jump while standing on a slope and verify launch is preserved.
- Land on a one-way platform from above.
- Jump through a one-way platform from below.
- Drop through a one-way platform and verify temporary ignore state.
- Ride horizontal and vertical moving platforms.
- Jump off a moving platform and verify inherited velocity.

## Definition of Done

The controller handles slopes, one-way platforms, and moving platforms as generic terrain features while keeping physical grounded state and collision safety accurate.
