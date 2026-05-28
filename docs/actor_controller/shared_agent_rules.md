# Shared Actor Controller Agent Rules

These rules apply to every generic actor controller feature guide.

## Controller Philosophy

Actors provide stats and input. The controller applies movement rules.

The controller must be reusable for players, alternate playable characters, enemies, NPCs, scripted actors, test dummies, bosses, replay actors, and future AI-controlled actors. Do not put player-only or elephant-only assumptions in the generic controller.

The controller consumes `ActorInputFrame` data. It must not call raw keyboard, mouse, or gamepad functions directly.

## GameMaker Organization

- Put shared controller behavior in scripts, not duplicated object events.
- Keep object events thin. Events should build input, call controller functions, apply outputs, and handle presentation.
- Prefer GameMaker-managed asset metadata. Avoid direct `.yy` edits unless unavoidable.
- Group controller scripts under an `ActorController` script folder when creating assets.
- Keep player-specific input and stat presets separate from generic controller logic.

Recommended script responsibilities:

- `actor_controller_constants.gml`: macros and default tuning constants.
- `actor_controller_enums.gml`: movement, facing, force, surface, collision, input, spray, event, and ability categories.
- `actor_controller_structs.gml`: constructors for runtime structs.
- `actor_controller_stats.gml`: default stats, presets, cloning, validation.
- `actor_controller_input.gml`: generic input frame helpers.
- `actor_controller_core.gml`: main update shell and instance sync.
- Feature scripts for movement, jump, collision, platforms, forces, spray, state, events, surfaces, and debug.

## Macros, Enums, and Tuning

- Use `#macro` for global constants and default tuning values.
- Use stats fields for actor-specific tuning.
- Use enums or bitmask macros for finite categories and ability flags.
- Do not use strings for core movement states, spray modes, surface types, force types, input source types, or controller events.
- Do not scatter raw numbers through controller logic when a macro or stat field should own the value.

Minimum enum categories:

- `ActorMoveState`
- `ActorFacing`
- `ActorSprayMode`
- `ActorForceType`
- `ActorSurfaceType`
- `ActorCollisionSide`
- `ActorInputSource`
- `ActorControllerEvent`

Minimum ability flags:

- jump
- wall slide
- wall jump
- ledge grab
- slide
- spray
- charge spray
- drop-through

## Data Model Responsibilities

`ActorStats` owns designer tuning:

- identity
- collision dimensions
- ground movement
- air movement
- jump and assist timing
- wall, ledge, slide, slope, platform, force, spray, water, charge, debug, and capability settings

`ActorInputFrame` owns per-frame intent:

- movement axes
- jump, slide, spray, charge, cancel, and drop button states
- aim vector and aim angle
- nozzle commands
- source type, source id, frame number, and raw input fields when useful

`ActorController` owns runtime simulation state:

- real-valued position
- controlled and external velocity
- movement state and previous state
- contacts and surface data
- timers and input memory
- platform carry state
- active forces
- spray, water, and charge state
- one-frame events
- debug state

## Physical Grounded vs Jump Eligibility

Keep physical grounded state separate from jump eligibility.

`is_physically_grounded` means the actor is touching valid ground this frame. Use it for grounded spray lift suppression, friction, landing detection, slopes, and moving platform carry.

Jump eligibility may include physical grounded state, ground coyote time, jump buffer, and platform coyote time. Use it only for deciding whether a jump may occur.

Mandatory rule: spray lift suppression uses physical grounded state, not coyote time. If the actor walked off a ledge and still has coyote time, they may still jump, but downward spray should be allowed to lift them.

## JSDoc Standard

Every function, including helpers, must have a full JSDoc script comment immediately above it.

Required tags:

- `@function`
- `@description`
- `@param` for every parameter
- `@returns`, including `{Undefined}` for functions with no return value

Use clear, searchable names such as `actor_controller_apply_gravity()` and `actor_collision_move_and_slide()`. Avoid shortened or clever names.

## Global Do Not Rules

- Do not read raw player input inside controller functions.
- Do not hardcode elephant-specific behavior into the generic controller.
- Do not duplicate controller logic across objects.
- Do not skip JSDoc comments on helper functions.
- Do not use raw numbers where macros or stats are appropriate.
- Do not use strings for state or mode checks.
- Do not bury tuning values in object events.
- Do not rely on animation timing for core physics.
- Do not allow normal grounded spray to lift the actor.
- Do not remove speedrunner expression with excessive speed caps.
- Do not make ledge grab steal control at high speed.
- Do not let moving platforms bypass collision safety.
- Do not implement surface behavior with scattered one-off object checks.
