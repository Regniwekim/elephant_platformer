# Actor Controller Implementation Guides

Use these mechanic-sized guides to implement the generic actor controller one feature at a time. Before starting any guide, read [shared_agent_rules.md](shared_agent_rules.md).

## Recommended Order

| Order | Guide | Depends on | Result |
|---|---|---|---|
| 0 | [Foundation Actor Loop](00_foundation_actor_loop.md) | shared rules | Minimal generic controller loop and debug text. |
| 1 | [Input Frames and Assist Timers](01_input_frames_and_assist_timers.md) | 0 | Player/AI input data and buffering timers. |
| 2 | [Solid Collision and Contacts](02_solid_collision_and_contacts.md) | 0 | Stable flat solid collision and contact data. |
| 3 | [Ground, Air Movement, and Jump](03_ground_air_movement_and_jump.md) | 1, 2 | Responsive run, air control, gravity, jump, and landing. |
| 4 | [Slopes, One-Ways, and Moving Platforms](04_slopes_one_ways_moving_platforms.md) | 2, 3 | Platformer terrain support beyond flat solids. |
| 5 | [External Forces and Velocity Model](05_external_forces_and_velocity_model.md) | 3 | Recoil, knockback, platform carry, and force layering. |
| 6 | [Water Spray Resource and Recoil](06_water_spray_resource_and_recoil.md) | 5 | Spray modes, water cost, refill, and recoil. |
| 7 | [Grounded Spray Suppression and Charged Launch](07_grounded_spray_suppression_and_charged_launch.md) | 4, 6 | Correct grounded spray rule and charged launch exception. |
| 8 | [Wall Movement](08_wall_movement.md) | 3, 5 | Wall slide, wall coyote, and wall jump. |
| 9 | [Ledge Grab and Mantle](09_ledge_grab_and_mantle.md) | 3, 8 | Ledge detection and mantle without high-speed control theft. |
| 10 | [Slide / Belly Slide](10_slide_belly_slide.md) | 3, 5 | Slide movement, low ceilings, and momentum preservation. |
| 11 | [Events, Debug, and Reusability](11_events_debug_and_reusability.md) | 0-10 | Event outputs, debug tools, validation, and non-player proof. |

The original full guide is preserved at [archive/generic_actor_controller_implementation_guide.md](archive/generic_actor_controller_implementation_guide.md).

## Implementation Expectations

- Treat each guide as a complete feature slice with its own acceptance criteria.
- Keep object events thin and use scripts for shared logic.
- Add only the scripts, objects, rooms, and metadata needed by the active guide.
- For GameMaker asset changes, review `.yyp`, `.yy`, and `.gml` diffs before committing.
- Do not move to a later guide until the active guide's testing checklist passes.

## Traceability Checklist

| Original guide section | New location |
|---|---|
| Project context and core design philosophy | [shared_agent_rules.md](shared_agent_rules.md) |
| Required GameMaker practices | [shared_agent_rules.md](shared_agent_rules.md) |
| Asset/script layout and object architecture | [shared_agent_rules.md](shared_agent_rules.md), [00](00_foundation_actor_loop.md) |
| Core data model | [shared_agent_rules.md](shared_agent_rules.md), [00](00_foundation_actor_loop.md) |
| Required enums and macros | [shared_agent_rules.md](shared_agent_rules.md), [00](00_foundation_actor_loop.md) |
| Controller update pipeline | [00](00_foundation_actor_loop.md), [03](03_ground_air_movement_and_jump.md), [05](05_external_forces_and_velocity_model.md), [06](06_water_spray_resource_and_recoil.md) |
| Input implementation, buffering, coyote time | [01](01_input_frames_and_assist_timers.md) |
| State machine | [00](00_foundation_actor_loop.md), [03](03_ground_air_movement_and_jump.md), [08](08_wall_movement.md), [09](09_ledge_grab_and_mantle.md), [10](10_slide_belly_slide.md) |
| Ground and air movement | [03](03_ground_air_movement_and_jump.md) |
| Jump system | [01](01_input_frames_and_assist_timers.md), [03](03_ground_air_movement_and_jump.md) |
| Wall movement | [08](08_wall_movement.md) |
| Ledge grab and mantle | [09](09_ledge_grab_and_mantle.md) |
| Slide / belly slide | [10](10_slide_belly_slide.md) |
| Slopes | [04](04_slopes_one_ways_moving_platforms.md) |
| One-way platforms | [04](04_slopes_one_ways_moving_platforms.md) |
| Moving platforms | [04](04_slopes_one_ways_moving_platforms.md), [05](05_external_forces_and_velocity_model.md) |
| External force system | [05](05_external_forces_and_velocity_model.md) |
| Water spray system | [06](06_water_spray_resource_and_recoil.md) |
| Grounded spray lift suppression | [07](07_grounded_spray_suppression_and_charged_launch.md) |
| Collision system | [02](02_solid_collision_and_contacts.md), [04](04_slopes_one_ways_moving_platforms.md) |
| Surfaces and materials | [04](04_slopes_one_ways_moving_platforms.md), [07](07_grounded_spray_suppression_and_charged_launch.md), [11](11_events_debug_and_reusability.md) |
| Controller events | [11](11_events_debug_and_reusability.md) |
| Debug tools | [00](00_foundation_actor_loop.md), [06](06_water_spray_resource_and_recoil.md), [11](11_events_debug_and_reusability.md) |
| Required function inventory | Distributed across each feature guide and governed by [shared_agent_rules.md](shared_agent_rules.md) |
| Required JSDoc standard and agent implementation rules | [shared_agent_rules.md](shared_agent_rules.md) |
| Implementation phases | Replaced by the ordered guide list in this README |
| Testing checklist and definition of done | Distributed across each feature guide |
| Immediate first task | [00](00_foundation_actor_loop.md) |
| Core summary | [shared_agent_rules.md](shared_agent_rules.md) |
