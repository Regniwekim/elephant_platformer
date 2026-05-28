# Generic Actor Controller Implementation Guide

## Project Context

This guide describes how to implement a reusable **generic actor controller** for a 2D platformer in GameMaker.

The first playable character is an elephant that sprays water from its trunk. However, the controller must not be hardcoded as an elephant controller. It should be a reusable movement/controller framework that can drive any actor in the game:

- player character
- alternate playable characters
- enemies
- NPCs
- scripted actors
- test dummies
- bosses

Each actor owns its own stats, collision dimensions, movement tuning, input source, and runtime state. The controller receives input and stats, updates physics/state, resolves movement, and outputs clean state for animation, camera, audio, FX, and gameplay systems.

The highest priorities are:

1. **Designer readability**
2. **Ease of modification**
3. **GameMaker best practices**
4. **Reusable actor architecture**
5. **Stable, deterministic platformer feel**
6. **Full JSDoc comments for every function**
7. **Constants defined using macros and enums, not magic numbers**

---

# 1. Core Design Philosophy

The controller must be built around this principle:

> Actors provide stats and input. The controller applies movement rules.

Do not bake player-only assumptions into the movement core. The controller should not directly read keyboard, mouse, or gamepad input. Instead, each actor provides an `ActorInputFrame` struct to the controller each step.

This allows the same controller to be driven by:

- human input
- AI input
- replay/ghost input
- cutscene scripting
- network prediction later, if needed
- test harnesses

The elephant trunk spray system should be implemented as a controller module or optional actor capability, not as one-off code inside `obj_player`.

---

# 2. Required GameMaker Practices

## 2.1 Work should primarily happen in:
- script assets
- object event code
- room editor data where appropriate
- notes/documentation files

GameMaker should manage asset metadata whenever possible.

## 2.2 Use Scripts for Shared Code

Shared controller code must live in scripts, not duplicated object events.

Scripts should contain:

- macros
- enums
- constructor functions
- controller functions
- collision helper functions
- debug helper functions
- input helper functions
- stat/config factory functions

## 2.3 Use Macros for Tunable Constants

Use `#macro` for true global constants and default tuning values.

Examples:

```gml
#macro ACTOR_CONTROLLER_VERSION "0.1.0"
#macro ACTOR_GRAVITY_DEFAULT 0.45
#macro ACTOR_JUMP_BUFFER_FRAMES_DEFAULT 8
#macro ACTOR_GROUND_COYOTE_FRAMES_DEFAULT 8
#macro ACTOR_SPRAY_GROUND_LIFT_SUPPRESS true
```

Macros should be grouped in a dedicated constants script.

Do not scatter raw numeric values through controller logic.

Bad:

```gml
if (_jump_buffer > 8) { ... }
```

Good:

```gml
if (_jump_buffer > actor.stats.jump_buffer_frames) { ... }
```

or:

```gml
jump_buffer_frames: ACTOR_JUMP_BUFFER_FRAMES_DEFAULT
```

## 2.4 Use Enums for Named Categories

Use enums for finite named values:

- movement states
- spray modes
- input sources
- actor facing direction
- collision side
- force type
- surface type
- debug draw mode
- ability flags

Example:

```gml
enum ActorMoveState
{
    GROUNDED,
    AIRBORNE,
    WALL_SLIDE,
    LEDGE_GRAB,
    MANTLE,
    SLIDE,
    STUNNED,
    KNOCKBACK,
    LOCKED,
    DEAD
}
```

Never use string comparisons for core state logic.

Bad:

```gml
if (actor.state == "grounded") { ... }
```

Good:

```gml
if (actor.state == ActorMoveState.GROUNDED) { ... }
```

## 2.5 Full JSDoc Comments for Every Function

Every function must have a full JSDoc script comment immediately above it.

Required tags:

- `@function`
- `@description`
- `@param` for every parameter
- `@returns` when applicable

Recommended tags:

- `@example` for important/public functions
- `@note` where useful

Example format:

```gml
/// @function actor_controller_update(_actor, _input)
/// @description Updates an actor controller for one simulation step using the provided input frame.
/// @param {Struct.ActorController} _actor The actor controller runtime struct to update.
/// @param {Struct.ActorInputFrame} _input The input frame supplied by the owning actor, AI, replay, or script.
/// @returns {Struct.ActorController} The updated actor controller struct.
function actor_controller_update(_actor, _input)
{
    // implementation
}
```

Every helper function also needs JSDoc. Do not skip internal/private helper functions.

## 2.6 Prefer Clear Function Names Over Clever Names

Function names should be explicit and searchable.

Good:

```gml
actor_controller_apply_gravity()
actor_controller_update_jump_buffer()
actor_controller_can_ground_launch_from_charge()
actor_collision_move_and_slide_x()
```

Bad:

```gml
ac_grav()
try_go()
move2()
waterThing()
```

## 2.7 Keep Object Events Thin

Object events should call controller functions. They should not contain complex movement logic.

Example `obj_player` Step event should look conceptually like:

```gml
input_frame = player_input_build_frame(id);
controller = actor_controller_update(controller, input_frame);
actor_apply_controller_to_instance(id, controller);
```

Most movement logic belongs in scripts.

---

# 3. Asset and Script Layout

Use a folder structure similar to this inside GameMaker:

```text
Scripts/
  ActorController/
    actor_controller_constants.gml
    actor_controller_enums.gml
    actor_controller_structs.gml
    actor_controller_stats.gml
    actor_controller_input.gml
    actor_controller_core.gml
    actor_controller_state.gml
    actor_controller_jump.gml
    actor_controller_wall.gml
    actor_controller_ledge.gml
    actor_controller_slide.gml
    actor_controller_spray.gml
    actor_controller_forces.gml
    actor_controller_collision.gml
    actor_controller_surfaces.gml
    actor_controller_debug.gml
    actor_controller_events.gml
  Player/
    player_input.gml
    player_stats.gml
  AI/
    ai_actor_input.gml
```

Objects:

```text
Objects/
  Actors/
    obj_actor_base
    obj_player
    obj_enemy_base
    obj_actor_test_dummy
  Collision/
    obj_solid
    obj_one_way_platform
    obj_moving_platform
    obj_surface_zone
    obj_water_refill
```

The exact asset names can vary, but the responsibilities should remain separated.

---

# 4. Object Architecture

## 4.1 `obj_actor_base`

Base object for actor instances. It should own common actor fields and simple event forwarding.

Responsibilities:

- create controller struct
- store actor stats
- store input provider type
- call controller update
- apply controller position to instance
- expose animation/camera/FX state
- handle debug draw if enabled

It should not contain detailed movement implementation.

## 4.2 `obj_player`

Child or specialized actor object for the player.

Responsibilities:

- build human input frame
- own player-specific stats
- own player-specific animation state
- own camera target hints
- call generic controller update

No player-only movement logic should be inside the Step event unless it is only about player presentation.

## 4.3 `obj_enemy_base`

Child or specialized actor object for enemies.

Responsibilities:

- build AI input frame
- own enemy-specific stats
- use same controller functions
- optionally disable certain movement capabilities through ability flags

## 4.4 Collision Objects

Collision objects should expose simple, readable properties where possible.

Examples:

```gml
surface_type = ActorSurfaceType.NORMAL;
one_way = false;
conveyor_x = 0;
conveyor_y = 0;
is_moving_platform = false;
```

The controller should query collision/surface data in helper functions rather than hardcoding object-specific behavior everywhere.

---

# 5. Core Data Model

## 5.1 `ActorStats` Struct

Each actor gets a stats/config struct. This is where designers tune movement.

The controller should never assume all actors move like the player. Stats define behavior.

Required stat groups:

```text
identity
collision
movement_ground
movement_air
jump
wall
ledge
slide
slope
spray
charge
water
force
assist
debug
capabilities
```

Example conceptual fields:

```gml
function ActorStats()
constructor
{
    name = "Default Actor";

    // Collision
    bbox_width = 16;
    bbox_height = 28;
    bbox_slide_height = 14;

    // Ground movement
    walk_speed = 2.25;
    run_speed = 3.75;
    ground_accel = 0.35;
    ground_decel = 0.45;
    ground_turn_accel = 0.55;
    ground_friction = 0.25;

    // Air movement
    air_max_speed = 3.5;
    air_accel = 0.18;
    air_decel = 0.08;
    air_turn_accel = 0.22;

    // Gravity/jump
    gravity_rise = 0.35;
    gravity_fall = 0.52;
    max_fall_speed = 8.0;
    jump_speed = -6.0;
    jump_cut_multiplier = 0.45;
    jump_buffer_frames = ACTOR_JUMP_BUFFER_FRAMES_DEFAULT;
    ground_coyote_frames = ACTOR_GROUND_COYOTE_FRAMES_DEFAULT;

    // Spray
    has_spray = true;
    water_max = 100;
    spray_ground_lift_suppressed = true;
    ground_launch_charge_min = 0.65;
}
```

The actual implementation may use nested structs if preferred, but designer readability is the priority.

## 5.2 `ActorInputFrame` Struct

Input must be passed in as data.

Required fields:

```text
move_x
move_y
jump_pressed
jump_held
jump_released
slide_pressed
slide_held
slide_released
spray_pressed
spray_held
spray_released
charge_pressed
charge_held
charge_released
cancel_pressed
cancel_held
drop_pressed
aim_x
aim_y
aim_angle
nozzle_next_pressed
nozzle_prev_pressed
nozzle_value_delta
```

Also useful:

```text
source_type
source_id
frame_number
raw_move_x
raw_move_y
raw_aim_x
raw_aim_y
```

Important rule:

> The controller consumes `ActorInputFrame`. It does not know whether the input came from keyboard, gamepad, AI, or replay.

## 5.3 `ActorController` Runtime Struct

The controller struct stores current movement state and runtime values.

Required groups:

```text
identity
position
velocity
state
contacts
timers
input_memory
surface
platform
forces
spray
water
events
debug
```

Important fields:

```text
x
 y
x_previous
y_previous
hsp
vsp
external_hsp
external_vsp
state
state_previous
facing
is_grounded
is_physically_grounded
was_grounded
ground_normal_x
ground_normal_y
ground_angle
ground_object
wall_left
wall_right
wall_normal_x
wall_normal_y
jump_buffer_timer
ground_coyote_timer
wall_coyote_timer
ledge_coyote_timer
drop_through_timer
wall_jump_lockout_timer
spray_active
spray_mode
spray_aim_x
spray_aim_y
water_current
charge_amount
charge_timer
```

## 5.4 Physical Grounded vs Jump Eligibility

This distinction is mandatory.

### Physical grounded

`is_physically_grounded` means the actor is actually touching valid ground this frame.

Used for:

- suppressing grounded spray lift
- ground friction
- landing detection
- slope behavior
- platform carry

### Jump eligibility

Jump eligibility includes:

- physical grounded
- ground coyote time
- jump buffer
- platform coyote

Used for:

- deciding whether jump can occur

Important rule:

> Spray lift suppression uses physical grounded state, not coyote time.

If the actor walked off a ledge and still has coyote time, they may still jump, but they are not physically grounded. Downward spray should be allowed to lift them.

---

# 6. Required Enums

Create an enum script dedicated to controller enums.

## 6.1 Movement State

```gml
enum ActorMoveState
{
    GROUNDED,
    AIRBORNE,
    WALL_SLIDE,
    WALL_GRAB,
    LEDGE_GRAB,
    MANTLE,
    SLIDE,
    STUNNED,
    KNOCKBACK,
    LOCKED,
    DEAD
}
```

## 6.2 Facing Direction

```gml
enum ActorFacing
{
    LEFT = -1,
    RIGHT = 1
}
```

## 6.3 Spray Mode

```gml
enum ActorSprayMode
{
    NONE,
    WIDE,
    FOCUSED,
    CHARGED
}
```

## 6.4 Force Type

```gml
enum ActorForceType
{
    ADDITIVE,
    IMPULSE,
    OVERRIDE,
    CONTINUOUS,
    PLATFORM_CARRY,
    KNOCKBACK
}
```

## 6.5 Surface Type

```gml
enum ActorSurfaceType
{
    NORMAL,
    ICE,
    MUD,
    WET,
    CONVEYOR,
    BOUNCE,
    STICKY,
    HAZARD,
    WATER_REFILL,
    CRUMBLING
}
```

## 6.6 Collision Side

```gml
enum ActorCollisionSide
{
    NONE,
    LEFT,
    RIGHT,
    TOP,
    BOTTOM
}
```

## 6.7 Input Source

```gml
enum ActorInputSource
{
    NONE,
    PLAYER,
    AI,
    SCRIPT,
    REPLAY,
    GHOST
}
```

## 6.8 Actor Event Type

```gml
enum ActorControllerEvent
{
    JUMP,
    LAND,
    HARD_LAND,
    WALL_SLIDE_START,
    WALL_JUMP,
    LEDGE_GRAB,
    MANTLE,
    SLIDE_START,
    SLIDE_END,
    SPRAY_START,
    SPRAY_STOP,
    NOZZLE_CHANGE,
    CHARGE_START,
    CHARGE_FULL,
    CHARGE_RELEASE,
    REFILL_START,
    REFILL_TICK,
    REFILL_FULL,
    HIT,
    DEATH,
    RESPAWN
}
```

## 6.9 Ability Flags

Use either enum values or bitmask macros for capabilities.

Recommended bitmask macros:

```gml
#macro ACTOR_ABILITY_JUMP            (1 << 0)
#macro ACTOR_ABILITY_WALL_SLIDE      (1 << 1)
#macro ACTOR_ABILITY_WALL_JUMP       (1 << 2)
#macro ACTOR_ABILITY_LEDGE_GRAB      (1 << 3)
#macro ACTOR_ABILITY_SLIDE           (1 << 4)
#macro ACTOR_ABILITY_SPRAY           (1 << 5)
#macro ACTOR_ABILITY_CHARGE_SPRAY    (1 << 6)
#macro ACTOR_ABILITY_DROP_THROUGH    (1 << 7)
```

This lets different actors share the same controller while enabling/disabling abilities.

---

# 7. Required Macros

Create `actor_controller_constants.gml`.

Include at minimum:

## 7.1 Version and Debug

```gml
#macro ACTOR_CONTROLLER_VERSION "0.1.0"
#macro ACTOR_DEBUG_DEFAULT false
#macro ACTOR_DEBUG_DRAW_PROBES_DEFAULT false
#macro ACTOR_DEBUG_DRAW_VECTORS_DEFAULT false
```

## 7.2 Simulation

```gml
#macro ACTOR_STEP_FPS 60
#macro ACTOR_EPSILON 0.0001
#macro ACTOR_MAX_COLLISION_ITERATIONS 16
#macro ACTOR_MAX_MOVE_STEP_PIXELS 2
#macro ACTOR_HARD_SPEED_CAP 24
```

## 7.3 Default Assist Timing

```gml
#macro ACTOR_JUMP_BUFFER_FRAMES_DEFAULT 8
#macro ACTOR_GROUND_COYOTE_FRAMES_DEFAULT 8
#macro ACTOR_WALL_COYOTE_FRAMES_DEFAULT 6
#macro ACTOR_LEDGE_COYOTE_FRAMES_DEFAULT 5
#macro ACTOR_DROP_THROUGH_FRAMES_DEFAULT 12
#macro ACTOR_WALL_JUMP_LOCKOUT_FRAMES_DEFAULT 6
```

## 7.4 Spray Defaults

```gml
#macro ACTOR_SPRAY_GROUND_LIFT_SUPPRESS true
#macro ACTOR_GROUND_LAUNCH_CHARGE_MIN_DEFAULT 0.65
#macro ACTOR_WATER_MAX_DEFAULT 100
#macro ACTOR_EMPTY_SPRAY_GRACE_FRAMES_DEFAULT 3
```

---

# 8. Controller Update Pipeline

The main update function must follow a consistent order every frame.

Recommended order:

1. Cache previous frame data.
2. Clear one-frame events.
3. Store current input frame.
4. Update input-derived timers.
5. Query pre-move contacts.
6. Update ground/platform/surface data.
7. Resolve state transitions.
8. Process jump/wall jump/ledge/mantle requests.
9. Process slide requests.
10. Update spray mode, charge, and water state.
11. Apply ground/air intent acceleration.
12. Apply gravity.
13. Apply spray recoil.
14. Apply external forces.
15. Apply friction/drag/speed clamps.
16. Move and resolve collision.
17. Apply slope snap where valid.
18. Resolve one-way platforms/drop-through.
19. Query post-move contacts.
20. Emit events.
21. Output debug and presentation state.

The main controller update function should be small and readable. It should delegate to named helper functions.

Conceptual example:

```gml
function actor_controller_update(_actor, _input)
{
    actor_controller_begin_step(_actor, _input);
    actor_controller_update_timers(_actor);
    actor_controller_query_contacts_pre(_actor);
    actor_controller_update_state(_actor);
    actor_controller_process_actions(_actor);
    actor_controller_apply_movement_intent(_actor);
    actor_controller_apply_gravity(_actor);
    actor_controller_apply_spray_recoil(_actor);
    actor_controller_apply_external_forces(_actor);
    actor_controller_apply_velocity_limits(_actor);
    actor_controller_move_and_collide(_actor);
    actor_controller_query_contacts_post(_actor);
    actor_controller_end_step(_actor);
    return _actor;
}
```

Each function must have full JSDoc.

---

# 9. Input Implementation

## 9.1 Player Input Builder

`player_input_build_frame()` should read raw human input and produce an `ActorInputFrame`.

The controller must not call `keyboard_check()`, `mouse_check_button()`, or gamepad functions directly.

## 9.2 AI Input Builder

AI functions should produce the same `ActorInputFrame` struct.

Example:

```gml
ai_actor_input_build_frame(_actor, _target)
```

The controller should not know or care whether input is AI or player.

## 9.3 Input Buffering

The controller tracks buffers internally using input frame button edges.

Required buffers:

- jump buffer
- wall jump buffer, if separate
- ledge/mantle buffer, if separate
- slide buffer
- spray start buffer, optional

Jump buffer behavior:

- If `jump_pressed`, set `jump_buffer_timer` to `stats.jump_buffer_frames`.
- Each frame, decrement while above zero.
- When jump is consumed, clear timer.

## 9.4 Coyote Time

Required coyote timers:

- ground coyote
- wall coyote
- ledge coyote
- platform coyote, optional but recommended

Ground coyote behavior:

- If physically grounded, set timer to `stats.ground_coyote_frames`.
- Else decrement.
- If coyote jump is consumed, clear timer.

Important:

> Physical grounded and coyote grounded are separate concepts.

---

# 10. State Machine Requirements

## 10.1 State Ownership

The state machine decides high-level movement modes. It should not handle every physics detail.

State should answer:

> What kind of movement rules are currently active?

Examples:

- grounded rules
- airborne rules
- wall slide rules
- ledge grab rules
- slide rules
- knockback rules

Spraying should usually be an overlay, not its own movement state.

## 10.2 State Transitions

State transitions should be centralized in `actor_controller_update_state()` or explicit transition helper functions.

Do not spread state changes randomly through unrelated functions.

Use helper functions:

```gml
actor_controller_set_state(_actor, _new_state)
actor_controller_is_state(_actor, _state)
actor_controller_can_enter_state(_actor, _state)
```

## 10.3 State Change Events

When state changes, the controller should record:

- previous state
- new state
- frame entered
- time in state reset to zero
- optional event emitted

---

# 11. Ground Movement

## 11.1 Requirements

Ground movement must support:

- walk/run acceleration
- deceleration with no input
- stronger turn acceleration
- friction
- surface modifiers
- slope tangent movement
- external velocity preservation

## 11.2 Speed Model

Separate player-controlled velocity from external/recoil velocity if practical.

Recommended runtime fields:

```text
hsp
vsp
external_hsp
external_vsp
```

Normal movement caps apply to `hsp`, not necessarily `external_hsp`.

This allows spray, moving platforms, bounce pads, and knockback to exceed normal run speed without breaking normal control.

## 11.3 Ground Acceleration

When grounded:

- if move input exists, accelerate toward target speed
- if reversing direction, use turn acceleration
- if no input, apply ground deceleration/friction
- apply surface speed modifiers
- project movement along slope tangent when on slopes

---

# 12. Air Movement

## 12.1 Requirements

Air movement must support:

- horizontal air control
- weaker acceleration than ground
- air turn acceleration
- optional air drag
- fall speed cap
- gravity differences between rising/falling
- jump cut
- spray overlay movement

## 12.2 Air Control

Air control should be weaker than ground control, but not helpless.

The trunk spray will provide a lot of aerial expression, so do not overdo base air control.

## 12.3 Fall Behavior

Use different gravity while rising and falling.

Recommended fields:

```text
gravity_rise
gravity_fall
max_fall_speed
jump_cut_multiplier
fast_fall_multiplier
```

---

# 13. Jump System

## 13.1 Required Jump Features

- jump buffer
- coyote time
- variable jump height
- jump cut
- jump event
- landing event
- jump from moving platforms
- optional slide jump modifier
- optional slope jump normal preservation

## 13.2 Jump Eligibility

An actor can jump if:

- ability flag allows jump
- jump buffer is active
- actor is physically grounded, or ground coyote timer is active
- actor is not locked, dead, stunned, mantling, or otherwise blocked

## 13.3 Jump Execution

When jump executes:

1. Clear jump buffer.
2. Clear ground coyote timer.
3. Clear physical grounded flag.
4. Apply jump velocity.
5. Inherit platform velocity where appropriate.
6. Set state to airborne.
7. Emit jump event.

## 13.4 Jump + Spray Ordering

This is important for the trunk-spray mechanic.

If the player presses jump and sprays downward while grounded, process jump before applying spray recoil.

This allows:

> jump + downward spray = boosted jump

But still prevents:

> standing on ground + normal downward spray = free takeoff

---

# 14. Wall Movement

## 14.1 Wall Detection

Track:

- wall contact left
- wall contact right
- wall normal
- wall object
- wall surface type
- wall coyote timer

## 14.2 Wall Slide

Actor may enter wall slide if:

- wall slide ability is enabled
- actor is airborne
- actor is touching valid wall
- actor is falling
- actor is pressing toward wall, or wall slide is configured as automatic
- wall jump lockout is not active

Wall slide should limit fall speed and allow buffered wall jump.

## 14.3 Wall Jump

Wall jump should:

- set vertical velocity
- push actor away from wall
- clear wall coyote timer
- clear jump buffer
- set brief wall jump lockout
- emit wall jump event
- allow spray shortly after

Keep lockout short. It should prevent accidental regrab, not remove player expression.

---

# 15. Ledge Grab and Mantle

## 15.1 Design Goal

Ledge grab should help casual players without stealing speedrunner control.

## 15.2 Recommended Hybrid Rule

Auto ledge grab only when:

- ledge grab ability is enabled
- actor is airborne
- actor is falling or moving sideways into ledge
- valid ledge is detected
- actor speed is below a maximum ledge grab speed
- actor is not holding down/drop/cancel
- actor is not actively spraying
- actor is not in knockback

This prevents ledge grab from interrupting high-speed routes.

## 15.3 Mantle

Mantle should be short and controllable.

Avoid long uninterruptible animations.

Mantle should:

- move actor to valid stand position
- optionally lock input briefly
- emit mantle event
- return to grounded state

---

# 16. Slide / Belly Slide

## 16.1 Requirements

Slide must support:

- manual entry
- momentum preservation
- slope acceleration
- reduced collision height
- stand-up ceiling check
- jump cancel
- spray interaction

## 16.2 Collision Mask Handling

If slide changes collision height, never stand up without checking overhead space.

If overhead space is blocked:

- remain sliding/crouched
- do not force actor upward
- do not clip into ceiling

## 16.3 Slide and Spray

Grounded spray during slide should push along the ground/slope but should not lift the actor unless the charged-shot ground launch threshold is met.

---

# 17. Slope System

## 17.1 Requirements

Slopes must support:

- walking up/down
- standing still
- sliding on steep slopes
- smooth transition between flat and slope
- slope snapping
- jumping from slopes
- spray along slope
- charged slope launches
- no jitter at seams

## 17.2 Slope Normals

The collision/surface system should expose:

- ground normal X/Y
- slope angle
- slope tangent X/Y
- walkable flag
- slide-required flag

## 17.3 Slope Snap

Use ground snap to keep actor attached to gentle downward slopes.

Do not snap if:

- actor just jumped
- actor is moving upward
- actor is in a charged launch
- actor is intentionally airborne
- actor has strong upward external velocity
- actor is leaving a slope at high speed for a natural launch

## 17.4 Slope Launch Preservation

When leaving a slope at high speed, preserve momentum.

Do not flatten velocity just because the actor leaves ground.

Speedrunning depends on this.

---

# 18. One-Way Platforms

## 18.1 Landing Rules

Actor should collide with one-way platforms when:

- actor is moving downward
- actor's feet were above the platform last frame
- actor is not in drop-through timer
- actor is not moving upward through the platform

## 18.2 Drop-Through Rules

When drop-through input is triggered:

1. Start `drop_through_timer`.
2. Ignore current one-way platform.
3. Move actor slightly downward if needed.
4. Re-enable collision after actor is below platform or timer expires.

## 18.3 Edge Cases

Handle:

- spraying downward while landing on one-way platform
- dropping through moving one-way platform
- high-speed vertical movement through one-way platform
- coyote time after walking off one-way platform

---

# 19. Moving Platforms

## 19.1 Requirements

The controller must support:

- horizontal platforms
- vertical platforms
- one-way moving platforms
- jumping from moving platforms
- platform velocity inheritance
- safe separation when platform moves away
- optional crush detection

## 19.2 Platform Carry

When physically grounded on moving platform:

- apply platform delta to actor position
- store platform velocity
- keep actor grounded if platform moves down within snap range

## 19.3 Jump Inheritance

On jump:

- inherit full horizontal platform velocity
- inherit upward platform velocity
- be cautious with downward platform velocity

Designer setting:

```text
platform_inherit_x_multiplier
platform_inherit_y_up_multiplier
platform_inherit_y_down_multiplier
```

---

# 20. External Force System

## 20.1 Purpose

All non-input movement should go through a unified force system where possible.

Examples:

- spray recoil
- wind
- conveyor belts
- water currents
- enemy knockback
- bounce pads
- moving platform carry
- scripted launches

## 20.2 Force Struct

Each force should define:

```text
force_type
x
y
duration_frames
timer
falloff_curve
source_id
source_type
ignore_normal_speed_cap
control_multiplier
can_stack
can_cancel
```

## 20.3 Force Types

- additive
- impulse
- continuous
- override
- platform carry
- knockback

## 20.4 Control Reduction

Some forces may reduce player control temporarily. This should be explicit and data-driven.

Do not randomly disable input in force code.

---

# 21. Water Spray System

## 21.1 Design Role

Spray is both:

- movement tool
- interaction tool
- resource sink

It should be implemented generically enough that non-elephant actors could also use it or a similar propulsion system later.

## 21.2 Spray State Fields

Required runtime fields:

```text
spray_active
spray_mode
spray_aim_x
spray_aim_y
spray_origin_x
spray_origin_y
spray_recoil_x
spray_recoil_y
water_current
water_max
charge_timer
charge_amount
charge_ready
charge_overready
```

## 21.3 Spray Modes

### Wide

- low recoil
- low cost
- broad hit area
- good for control
- good for interacting with wide targets

### Focused

- stronger recoil
- higher cost
- narrow hit area
- longer range
- main speedrun movement tool

### Charged

- builds while held
- releases burst
- high water cost
- can ground-launch if sufficiently charged
- can break objects or trigger special interactions

## 21.4 Water Cost

Water should drain based on spray mode.

If water reaches zero:

- stop spray
- emit dry/no-water feedback event
- optionally allow a tiny grace window for feel

## 21.5 Refills

Refill sources should call generic controller functions:

```gml
actor_controller_add_water(_actor, _amount)
actor_controller_refill_water_rate(_actor, _amount_per_step)
actor_controller_set_water(_actor, _amount)
```

This keeps refill zones simple.

---

# 22. Grounded Spray Lift Suppression

This rule is mandatory.

> If the actor is physically grounded, normal continuous spray recoil cannot lift them off the ground.

Downward spray should only lift the actor if:

- actor is already airborne, or
- actor releases a sufficiently charged shot

## 22.1 Required Behavior Table

| Situation | Result |
|---|---|
| Grounded + wide downward spray | No lift |
| Grounded + focused downward spray | No lift |
| Grounded + diagonal downward spray | Horizontal/along-ground push only |
| Grounded + sufficiently charged downward blast | Launch allowed |
| Airborne + downward spray | Lift allowed |
| Airborne + focused downward spray | Strong lift allowed |
| Coyote time but not physically grounded + downward spray | Lift allowed |

## 22.2 Flat Ground Implementation Rule

When physically grounded and applying continuous spray recoil:

- compute raw recoil opposite aim direction
- if recoil has upward vertical component, remove that component
- preserve horizontal component

## 22.3 Slope-Aware Implementation Rule

Preferred version:

- compute raw recoil vector
- get ground normal
- split recoil into:
  - normal component away from ground
  - tangent component along ground
- remove or reduce the away-from-ground component
- preserve tangent component

This allows grounded spray to push the actor along a slope without popping them off the surface.

## 22.4 Charged Shot Exception

Ground launch is allowed only if:

```text
charge_amount >= stats.ground_launch_charge_min
```

Start value:

```text
ground_launch_charge_min = 0.65
```

Charged shot release should be an impulse, not continuous spray recoil.

---

# 23. Collision System

## 23.1 Required Features

- subpixel movement
- stable solid collision
- separate horizontal/vertical movement resolution
- slope support
- one-way platform support
- moving platform support
- high-speed movement safety
- corner handling
- ceiling handling
- unstuck fallback

## 23.2 Subpixel Movement

Store position and velocity using real numbers.

Do not rely purely on integer instance coordinates for simulation.

Use either:

- controller struct `x/y` as real position
- instance `x/y` synced after movement

## 23.3 High-Speed Safety

Spray recoil and charged shots can produce high speed. Movement must not tunnel through walls.

Use one of:

- stepwise movement increments
- swept collision
- capped per-iteration movement

A practical GameMaker-friendly approach:

- split movement into small chunks no larger than `ACTOR_MAX_MOVE_STEP_PIXELS`
- resolve collision each chunk
- cap iterations using `ACTOR_MAX_COLLISION_ITERATIONS`

## 23.4 Collision Helper Functions

Required helpers:

```text
actor_collision_place_solid()
actor_collision_place_one_way()
actor_collision_move_x()
actor_collision_move_y()
actor_collision_move_and_slide()
actor_collision_get_ground_info()
actor_collision_get_wall_info()
actor_collision_get_slope_info()
actor_collision_can_stand()
actor_collision_try_unstuck()
```

Every helper requires full JSDoc.

---

# 24. Surfaces and Materials

## 24.1 Surface Data

The controller should detect surface modifiers through helper functions.

Surface data should include:

```text
surface_type
friction_multiplier
accel_multiplier
top_speed_multiplier
jump_multiplier
recoil_multiplier
conveyor_x
conveyor_y
is_hazard
refill_rate
```

## 24.2 Supported Initial Surface Types

Implement at least:

- normal
- ice
- mud
- conveyor
- water refill
- hazard

Other surfaces can be added later.

## 24.3 Surface Modifiers

Surface behavior should modify stats rather than branching controller logic everywhere.

Example:

```text
actual_ground_accel = stats.ground_accel * surface.accel_multiplier
actual_ground_friction = stats.ground_friction * surface.friction_multiplier
```

---

# 25. Controller Events

The controller should emit one-frame events into an event queue or event flags.

This keeps audio, animation, particles, and gameplay responses separate from movement code.

Required events:

- jump
- land
- hard land
- wall slide start
- wall jump
- ledge grab
- mantle
- slide start
- slide end
- spray start
- spray stop
- nozzle change
- charge start
- charge full
- charge release
- refill start
- refill tick
- refill full
- hit
- death
- respawn

Recommended functions:

```gml
actor_controller_emit_event(_actor, _event_type)
actor_controller_has_event(_actor, _event_type)
actor_controller_clear_events(_actor)
```

---

# 26. Debug Tools

Debug tooling is required, not optional.

## 26.1 On-Screen Debug Values

Display:

- state
- previous state
- x/y position
- hsp/vsp
- external hsp/vsp
- grounded
- physically grounded
- wall left/right
- ground coyote timer
- jump buffer timer
- wall coyote timer
- drop-through timer
- ground normal
- slope angle
- ground object
- platform velocity
- spray mode
- spray active
- spray aim vector
- spray recoil vector
- water current/max
- charge amount
- active forces

## 26.2 Debug Draw

Draw:

- collision mask
- ground probes
- wall probes
- ledge probes
- velocity vector
- external velocity vector
- ground normal
- slope tangent
- spray aim vector
- spray recoil vector
- spray hit area
- one-way platform ignore info
- moving platform carry vector

## 26.3 Debug Toggles

Use macros for defaults, but allow runtime toggles.

Example fields:

```text
debug_enabled
debug_draw_collision
debug_draw_probes
debug_draw_vectors
debug_print_events
```

---

# 27. Required Function Inventory

The implementation must include functions matching these responsibilities. Names may vary slightly, but clarity is required.

## 27.1 Struct Constructors

```text
ActorStats()
ActorInputFrame()
ActorController()
ActorForce()
ActorSurfaceInfo()
ActorContactInfo()
```

Each constructor needs JSDoc.

## 27.2 Stats Functions

```text
actor_stats_create_default()
actor_stats_create_player_elephant()
actor_stats_create_test_dummy()
actor_stats_clone()
actor_stats_apply_preset()
actor_stats_validate()
```

## 27.3 Input Functions

```text
actor_input_frame_create_empty()
actor_input_frame_normalize()
player_input_build_frame()
ai_actor_input_build_frame()
```

## 27.4 Core Controller Functions

```text
actor_controller_create()
actor_controller_update()
actor_controller_begin_step()
actor_controller_end_step()
actor_controller_reset()
actor_controller_set_position()
actor_controller_set_velocity()
actor_controller_apply_to_instance()
```

## 27.5 Timer/Assist Functions

```text
actor_controller_update_timers()
actor_controller_update_jump_buffer()
actor_controller_update_coyote_timers()
actor_controller_consume_jump_buffer()
actor_controller_can_use_ground_coyote()
```

## 27.6 State Functions

```text
actor_controller_set_state()
actor_controller_is_state()
actor_controller_update_state()
actor_controller_can_enter_state()
actor_controller_get_state_name()
```

## 27.7 Movement Functions

```text
actor_controller_apply_ground_movement()
actor_controller_apply_air_movement()
actor_controller_apply_gravity()
actor_controller_apply_friction()
actor_controller_apply_velocity_limits()
actor_controller_project_velocity_on_slope()
```

## 27.8 Jump Functions

```text
actor_controller_can_jump()
actor_controller_try_jump()
actor_controller_execute_jump()
actor_controller_apply_jump_cut()
actor_controller_handle_landing()
```

## 27.9 Wall Functions

```text
actor_controller_update_wall_contact()
actor_controller_can_wall_slide()
actor_controller_try_enter_wall_slide()
actor_controller_can_wall_jump()
actor_controller_try_wall_jump()
actor_controller_execute_wall_jump()
```

## 27.10 Ledge Functions

```text
actor_controller_find_ledge()
actor_controller_can_ledge_grab()
actor_controller_try_ledge_grab()
actor_controller_start_mantle()
actor_controller_update_mantle()
actor_controller_finish_mantle()
```

## 27.11 Slide Functions

```text
actor_controller_can_slide()
actor_controller_try_slide()
actor_controller_update_slide()
actor_controller_can_stand_from_slide()
actor_controller_end_slide()
```

## 27.12 Spray Functions

```text
actor_controller_update_spray()
actor_controller_set_spray_mode()
actor_controller_get_spray_stats()
actor_controller_can_spray()
actor_controller_start_spray()
actor_controller_stop_spray()
actor_controller_apply_spray_cost()
actor_controller_apply_spray_recoil()
actor_controller_filter_grounded_spray_lift()
actor_controller_update_charge()
actor_controller_can_release_charged_shot()
actor_controller_release_charged_shot()
actor_controller_can_ground_launch_from_charge()
actor_controller_add_water()
actor_controller_set_water()
actor_controller_refill_water_rate()
```

## 27.13 Force Functions

```text
actor_force_create()
actor_controller_add_force()
actor_controller_clear_forces()
actor_controller_update_forces()
actor_controller_apply_external_forces()
```

## 27.14 Collision Functions

```text
actor_collision_place_solid()
actor_collision_place_one_way()
actor_collision_move_x()
actor_collision_move_y()
actor_collision_move_and_slide()
actor_collision_resolve_slope()
actor_collision_snap_to_ground()
actor_collision_get_ground_info()
actor_collision_get_wall_info()
actor_collision_can_stand()
actor_collision_try_unstuck()
```

## 27.15 Surface Functions

```text
actor_surface_get_info()
actor_surface_apply_modifiers()
actor_surface_is_walkable()
actor_surface_is_hazard()
actor_surface_get_refill_rate()
```

## 27.16 Event Functions

```text
actor_controller_emit_event()
actor_controller_has_event()
actor_controller_clear_events()
actor_controller_process_events_for_instance()
```

## 27.17 Debug Functions

```text
actor_controller_debug_draw()
actor_controller_debug_draw_vectors()
actor_controller_debug_draw_probes()
actor_controller_debug_print_state()
actor_controller_debug_get_state_text()
```

---

# 28. Required JSDoc Standard

Every function must use this style:

```gml
/// @function function_name(_arg1, _arg2)
/// @description Clear sentence explaining what the function does and why it exists.
/// @param {Type} _arg1 Description of first argument.
/// @param {Type} _arg2 Description of second argument.
/// @returns {Type} Description of return value.
function function_name(_arg1, _arg2)
{
    // code
}
```

For functions with no return value:

```gml
/// @returns {Undefined} This function does not return a value.
```

For constructors:

```gml
/// @function ActorController(_x, _y, _stats)
/// @description Creates a runtime actor controller struct at the given position using the provided stats.
/// @param {Real} _x Initial X position.
/// @param {Real} _y Initial Y position.
/// @param {Struct.ActorStats} _stats Actor movement, collision, and ability stats.
/// @returns {Struct.ActorController} A new actor controller runtime struct.
function ActorController(_x, _y, _stats)
constructor
{
    // fields
}
```

All public-facing functions should include examples where helpful.

---

# 29. Agent Implementation Rules

The implementation agent must follow these rules:

1. Do not hardcode elephant-specific behavior into the generic controller.
2. Do not read raw player input inside controller functions.
3. Do not use raw numbers in controller logic where macros or stats are appropriate.
4. Do not use strings for movement states or spray modes.
5. Do not duplicate controller logic across objects.
6. Do not skip JSDoc comments on helper functions.
7. Do not add long animation locks unless explicitly required.
8. Do not allow normal grounded spray to lift the actor.
9. Do not remove speedrunner expression with excessive speed caps.
10. Do not make ledge grab steal control at high speed.
11. Do not rely on animation timing for core physics.
12. Do not bury tuning values in object events.
13. Do not let moving platforms bypass collision safety.
14. Do not implement new surface behavior with one-off object checks everywhere.
15. Do not edit `.yy` files directly unless unavoidable.

---

# 30. Implementation Phases

## Phase 1: Foundation

Implement:

- constants script
- enums script
- stats constructor
- input frame constructor
- controller constructor
- basic create/update/apply flow
- debug text output

Acceptance criteria:

- `obj_player` can create a controller.
- Player input is converted into `ActorInputFrame`.
- Controller can be updated each step.
- Instance position follows controller position.
- Debug state displays correctly.

## Phase 2: Basic Platforming

Implement:

- horizontal movement
- ground acceleration/deceleration
- gravity
- jump
- variable jump height
- jump buffer
- ground coyote time
- basic solid collision
- subpixel movement

Acceptance criteria:

- Movement feels responsive without spray.
- Jump buffer works.
- Coyote time works.
- Collision is stable at normal speeds.

## Phase 3: Slopes, One-Ways, Moving Platforms

Implement:

- slope walking
- slope snapping
- slope jumping
- one-way platforms
- drop-through
- moving platform carry
- platform velocity inheritance

Acceptance criteria:

- Actor can walk up/down slopes without jitter.
- Actor can drop through one-way platforms.
- Actor rides moving platforms correctly.
- Jumping from moving platforms inherits velocity correctly.

## Phase 4: Spray Movement

Implement:

- aim vector
- spray modes
- water meter
- spray cost
- spray recoil
- grounded spray lift suppression
- basic refill zones
- spray debug vectors

Acceptance criteria:

- Spraying opposite aim direction pushes actor.
- Grounded downward spray does not lift actor.
- Airborne downward spray lifts actor.
- Coyote-time airborne spray lifts actor because physical grounded is false.
- Water drains and refills correctly.

## Phase 5: Advanced Movement

Implement:

- wall slide
- wall jump
- ledge grab
- mantle
- slide/belly slide
- charged shot
- charged ground launch threshold

Acceptance criteria:

- Wall movement feels responsive.
- Ledge grab does not interrupt high-speed spraying.
- Slide preserves momentum and respects ceilings.
- Charged shot can launch from ground only above threshold.

## Phase 6: Polish and Extensibility

Implement:

- event hooks
- animation state outputs
- camera hint outputs
- audio/FX event integration
- improved debug draw
- stat validation
- multiple actor presets
- AI input test actor

Acceptance criteria:

- Same controller can drive player and AI actor.
- Designers can tune actor stats from one readable location.
- Debug tools clearly expose controller behavior.

---

# 31. Testing Checklist

The implementation is not complete until these cases are tested.

## Basic Movement

- walk left/right
- accelerate to run speed
- release input and decelerate
- reverse direction
- jump while standing
- jump while running
- short hop by releasing jump early
- buffered jump before landing
- coyote jump after leaving ledge

## Collision

- run into wall
- jump into ceiling
- land on flat ground
- land on slope
- move across slope seam
- high-speed movement into wall
- corner collision

## Platforms

- land on one-way from above
- jump through one-way from below
- drop through one-way
- ride moving platform horizontally
- ride moving platform vertically
- jump from moving platform

## Spray

- spray left/right on ground
- spray diagonally on ground
- spray down on ground: no lift
- spray down-left on ground: horizontal/tangent push only
- jump then spray down: lift allowed
- walk off ledge then spray down during coyote: lift allowed
- airborne focused spray down: strong lift
- run out of water mid-spray
- refill water

## Charged Shot

- charge below threshold on ground: no launch
- charge above threshold on ground: launch
- charged shot in air: redirect
- cancel charge
- charge with insufficient water

## Advanced Movement

- wall slide
- wall jump
- wall coyote jump
- ledge grab at low speed
- bypass ledge grab at high speed
- slide under low ceiling
- fail to stand when ceiling blocked
- slide jump
- spray while sliding

## Reusability

- player actor uses same controller
- enemy/test actor uses same controller
- AI input frame drives actor
- different stats produce visibly different movement
- ability flags disable movement features correctly

---

# 32. Definition of Done

The controller is ready for level prototyping when:

1. The player can run, jump, and collide reliably.
2. Jump buffer and coyote time are implemented and tunable.
3. Slopes, one-way platforms, and moving platforms work.
4. Spray recoil works in air and on ground.
5. Grounded spray lift suppression works correctly.
6. Charged shots can ground-launch only past threshold.
7. All tuning values are in stats/macros, not buried in logic.
8. All movement states use enums.
9. Every function has full JSDoc comments.
10. The same controller can be used by at least one non-player test actor.
11. Debug draw/text exposes state, contacts, timers, velocity, spray, and water.
12. Object events remain thin and readable.

---

# 33. Immediate First Task for the Agent

Begin by creating these scripts:

1. `actor_controller_constants.gml`
2. `actor_controller_enums.gml`
3. `actor_controller_structs.gml`
4. `actor_controller_stats.gml`
5. `actor_controller_input.gml`
6. `actor_controller_core.gml`
7. `actor_controller_debug.gml`

Then create a minimal `obj_player` implementation that:

1. Creates elephant player stats.
2. Creates an actor controller at the instance position.
3. Builds a player input frame each Step.
4. Calls `actor_controller_update()`.
5. Applies controller position back to the instance.
6. Draws debug information.

Do not implement spray, slopes, ledges, walls, or advanced movement until the basic generic actor loop works.

---

# 34. Core Summary

The controller should be implemented as a reusable, data-driven actor controller.

The player object should not own the movement logic. It should own input and presentation.

The actor controller should own:

- physics
- state
- timers
- collision
- movement rules
- spray recoil
- water resource
- force handling
- debug output

The actor stats should own:

- speed
- jump height
- gravity
- friction
- water capacity
- spray strength
- charge thresholds
- movement capability flags

The input frame should own:

- current movement intent
- jump/spray/slide button states
- aim vector
- nozzle/charge/cancel commands

Final guiding rule:

> Build one readable, generic actor controller that can make the elephant feel great, then let every other character reuse that same foundation with different stats and capabilities.
