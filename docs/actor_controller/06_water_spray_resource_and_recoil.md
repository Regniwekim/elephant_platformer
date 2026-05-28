# Water Spray Resource and Recoil Implementation Guide

## Goal

Implement generic spray as a movement and interaction overlay: aim, spray modes, water drain, refill helpers, and recoil that uses the external force model.

## Dependencies

- [shared_agent_rules.md](shared_agent_rules.md)
- [05_external_forces_and_velocity_model.md](05_external_forces_and_velocity_model.md)

## Implementation Scope

Implement continuous spray, water resource, refill helpers, and debug vectors. Do not implement grounded lift suppression or charged ground launch here; guide 7 owns those rules.

Required scripts/objects:

- `actor_controller_spray.gml`
- `actor_controller_forces.gml`
- `actor_controller_debug.gml`
- optional `obj_water_refill`

## Data and Function Responsibilities

- Add runtime fields for spray active, mode, aim vector, origin, recoil vector, water current/max, charge timer, charge amount, charge ready, and charge overready.
- Add stats for spray capability, mode cost, recoil strength, water max, empty spray grace, and refill rates.
- Implement `actor_controller_update_spray()`, `actor_controller_set_spray_mode()`, `actor_controller_get_spray_stats()`, `actor_controller_can_spray()`, `actor_controller_start_spray()`, `actor_controller_stop_spray()`, `actor_controller_apply_spray_cost()`, and `actor_controller_apply_spray_recoil()`.
- Implement water helpers: `actor_controller_add_water()`, `actor_controller_set_water()`, and `actor_controller_refill_water_rate()`.
- Support wide and focused continuous spray modes.
- Drain water per mode and stop spray when empty after any configured grace period.
- Emit or record spray start, spray stop, nozzle change, refill start, refill tick, and refill full events for guide 11 to formalize.

## Acceptance Criteria

- Spray is gated by ability flags and water availability.
- Spray aim comes from `ActorInputFrame`, not raw device APIs.
- Wide and focused modes have distinct tunable cost and recoil values.
- Recoil is applied through external velocity or force helpers.
- Water drains while spraying and clamps between 0 and max.
- Refill helpers can be called by simple refill objects or surface zones.
- Debug draw shows spray aim and recoil vectors.

## Testing Checklist

- Start and stop spray with input.
- Switch between wide and focused modes.
- Spray left, right, up, down, and diagonally and verify recoil direction is opposite aim.
- Drain water to empty and verify spray stops.
- Refill water by calling helper functions or entering a test refill source.
- Verify an actor without spray ability cannot spray.
- Verify debug output shows spray active, mode, aim, recoil, and water.

## Definition of Done

Spray exists as a generic controller overlay with resource drain, refill, mode tuning, recoil, and debug visibility, but it does not yet enforce grounded lift suppression.
