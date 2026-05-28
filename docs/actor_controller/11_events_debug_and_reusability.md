# Events, Debug, and Reusability Implementation Guide

## Goal

Finalize the controller as a reusable gameplay system by formalizing one-frame events, presentation outputs, debug tools, stat validation, multiple presets, and at least one non-player actor proof.

## Dependencies

- [shared_agent_rules.md](shared_agent_rules.md)
- Guides [00](00_foundation_actor_loop.md) through [10](10_slide_belly_slide.md)

## Implementation Scope

Implement polish and extensibility support. Do not add new core movement mechanics unless they are required to expose or test existing mechanics.

Required scripts/objects:

- `actor_controller_events.gml`
- `actor_controller_debug.gml`
- `actor_controller_stats.gml`
- `actor_controller_surfaces.gml`
- `player_stats.gml`
- `ai_actor_input.gml`
- `obj_actor_base`
- `obj_actor_test_dummy` or equivalent non-player actor

## Data and Function Responsibilities

- Implement `actor_controller_emit_event()`, `actor_controller_has_event()`, `actor_controller_clear_events()`, and `actor_controller_process_events_for_instance()`.
- Formalize events for jump, land, hard land, wall slide start, wall jump, ledge grab, mantle, slide start/end, spray start/stop, nozzle change, charge start/full/release, refill start/tick/full, hit, death, and respawn.
- Expose presentation state for animation, camera hints, audio, FX, and gameplay responses without embedding presentation behavior in physics code.
- Implement debug draw for collision mask, probes, velocity vectors, ground normals, slope tangents, spray aim/recoil, active forces, one-way ignores, and platform carry.
- Implement `actor_stats_create_test_dummy()`, `actor_stats_apply_preset()`, and robust `actor_stats_validate()`.
- Add a non-player test actor driven by AI/script input using the same controller update path as the player.
- Ensure supported surface types have centralized helper behavior: normal, ice, mud, conveyor, water refill, and hazard.

## Acceptance Criteria

- One-frame events are emitted once, queryable, and cleared each step.
- Object events respond to controller outputs rather than owning physics decisions.
- Debug text and draw can be toggled at runtime.
- Debug output exposes state, contacts, timers, velocity, external velocity, spray, water, charge, surface, platform, and active force data.
- Stat validation reports missing or invalid fields clearly.
- At least one AI/test actor uses the same generic controller as the player.
- Different stat presets produce visibly different behavior without code duplication.

## Testing Checklist

- Trigger each implemented movement event and confirm it appears for exactly one frame.
- Verify animation/audio/FX hooks can consume events without changing physics code.
- Toggle debug text, probes, vectors, collision, and event printing.
- Validate default, elephant player, and test dummy stats.
- Drive a non-player actor with AI/script input.
- Disable selected ability flags and verify unavailable mechanics stay disabled.
- Review object events for thin forwarding only.

## Definition of Done

The controller is ready for level prototyping: player and non-player actors can share the same generic controller, designers can tune stats from readable locations, and debug/event outputs make behavior inspectable.
