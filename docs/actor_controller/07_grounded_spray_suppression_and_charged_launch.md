# Grounded Spray Suppression and Charged Launch Implementation Guide

## Goal

Implement the mandatory rule that normal grounded spray cannot lift the actor, while allowing airborne spray lift and sufficiently charged ground launches.

## Dependencies

- [shared_agent_rules.md](shared_agent_rules.md)
- [04_slopes_one_ways_moving_platforms.md](04_slopes_one_ways_moving_platforms.md)
- [06_water_spray_resource_and_recoil.md](06_water_spray_resource_and_recoil.md)

## Implementation Scope

Implement grounded spray lift filtering, charge buildup, charged release, and ground launch threshold behavior. Do not add unrelated spray interactions or object-breaking systems unless a simple event hook is needed.

Required scripts:

- `actor_controller_spray.gml`
- `actor_controller_forces.gml`
- `actor_controller_surfaces.gml`
- `actor_controller_debug.gml`

## Data and Function Responsibilities

- Implement `actor_controller_filter_grounded_spray_lift()` using `is_physically_grounded`, not coyote timers.
- On flat ground, remove the upward component from continuous spray recoil while preserving horizontal push.
- On slopes, split recoil into normal and tangent components, remove or reduce the away-from-ground component, and preserve tangent movement.
- Preserve airborne downward spray lift, including when the actor has coyote time but is no longer physically grounded.
- Implement `actor_controller_update_charge()`, `actor_controller_can_release_charged_shot()`, `actor_controller_release_charged_shot()`, and `actor_controller_can_ground_launch_from_charge()`.
- Allow grounded charged launch only when `charge_amount >= stats.ground_launch_charge_min`.
- Treat charged release as an impulse, not continuous recoil.
- Emit or record charge start, charge full, charge release, and dry/no-water feedback events.

## Acceptance Criteria

- Grounded wide downward spray does not lift the actor.
- Grounded focused downward spray does not lift the actor.
- Grounded diagonal downward spray preserves horizontal or slope-tangent push.
- Airborne downward spray lifts the actor.
- Walking off a ledge and spraying downward during coyote time lifts the actor because physical grounded is false.
- Charged ground launch works only at or above the configured threshold.
- Charged shot release uses water cost and impulse tuning from stats.

## Testing Checklist

- Spray down on flat ground with wide mode and verify no lift.
- Spray down on flat ground with focused mode and verify no lift.
- Spray diagonally down on flat ground and verify horizontal push remains.
- Spray down while airborne and verify lift.
- Walk off a ledge during coyote time, spray down, and verify lift.
- Charge below threshold on ground and release; verify no ground launch.
- Charge at or above threshold on ground and release; verify launch.
- Release a charged shot in air and verify impulse applies.

## Definition of Done

Spray propulsion obeys the physical grounded rule, slopes preserve tangent recoil, and charged shots provide the only grounded upward spray launch path.
