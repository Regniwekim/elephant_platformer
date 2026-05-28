# Solid Collision and Contacts Implementation Guide

## Goal

Add stable flat solid collision and reliable contact data while preserving real-valued controller position. This guide creates the collision foundation used by movement, slopes, one-way platforms, moving platforms, and spray.

## Dependencies

- [shared_agent_rules.md](shared_agent_rules.md)
- [00_foundation_actor_loop.md](00_foundation_actor_loop.md)

## Implementation Scope

Implement solid collision only. Do not implement slopes, one-way platforms, moving platform carry, water refill surfaces, or advanced terrain materials in this guide.

Required scripts/objects:

- `actor_controller_collision.gml`
- contact structs in `actor_controller_structs.gml`
- collision object conventions for `obj_solid`
- debug helpers for collision mask and probe state

## Data and Function Responsibilities

- Store controller `x/y` as real numbers and sync instance `x/y` after simulation.
- Track previous position, `is_physically_grounded`, `was_grounded`, wall left/right, ceiling contact, ground object, wall object, and collision side information.
- Implement `actor_collision_place_solid()`, `actor_collision_move_x()`, `actor_collision_move_y()`, `actor_collision_move_and_slide()`, `actor_collision_get_ground_info()`, `actor_collision_get_wall_info()`, `actor_collision_can_stand()`, and `actor_collision_try_unstuck()`.
- Split movement into safe chunks no larger than `ACTOR_MAX_MOVE_STEP_PIXELS`, capped by `ACTOR_MAX_COLLISION_ITERATIONS`.
- Resolve horizontal and vertical movement separately for predictable platformer behavior.
- Set contact state after movement from collision checks, not from requested velocity alone.

## Acceptance Criteria

- Actor cannot pass through flat `obj_solid` walls, floors, or ceilings at normal speeds.
- High horizontal or vertical speed is chunked enough to avoid obvious tunneling.
- Collision resolution stops the blocked velocity component and preserves the unblocked component.
- Contact fields update correctly after movement.
- The controller can recover from small overlaps through an explicit unstuck helper.
- Every collision helper has full JSDoc.

## Testing Checklist

- Run into a wall from both directions.
- Jump or move upward into a ceiling.
- Fall onto flat ground and verify physical grounded becomes true.
- Walk off ground and verify physical grounded becomes false.
- Move diagonally into a corner and verify no jitter or tunneling.
- Apply a high test velocity into a wall and confirm movement is bounded by collision.
- Start slightly embedded in a solid and confirm the unstuck helper resolves or reports failure.

## Definition of Done

The controller has deterministic flat solid collision, real-valued position, stable contact fields, and helper functions ready for movement and terrain extensions.
