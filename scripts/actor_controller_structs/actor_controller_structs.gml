/// @description Runtime struct constructors for the generic actor controller.

/// @function ActorStats
/// @description Creates designer-owned tuning values for a generic actor.
/// @returns {Struct} Actor stats with default tuning and capability fields.
function ActorStats() constructor {
    name = "Default Actor";
    version = ACTOR_CONTROLLER_VERSION;

    bbox_width = 16;
    bbox_height = 28;
    bbox_slide_height = 14;

    walk_speed = 2.25;
    run_speed = 3.75;
    ground_accel = 0.35;
    ground_decel = 0.45;
    ground_turn_accel = 0.55;
    ground_friction = 0.25;

    air_max_speed = 3.5;
    air_accel = 0.18;
    air_decel = 0.08;
    air_turn_accel = 0.22;

    gravity_rise = 0.35;
    gravity_fall = 0.52;
    max_fall_speed = 8.0;
    jump_speed = -6.0;
    jump_cut_multiplier = 0.45;

    slope_max_angle = ACTOR_SLOPE_MAX_ANGLE_DEFAULT;
    slope_snap_distance = ACTOR_SLOPE_SNAP_DISTANCE_DEFAULT;
    slope_step_height = ACTOR_SLOPE_STEP_HEIGHT_DEFAULT;
    platform_inherit_x_multiplier = ACTOR_PLATFORM_INHERIT_X_MULTIPLIER_DEFAULT;
    platform_inherit_y_up_multiplier = ACTOR_PLATFORM_INHERIT_Y_UP_MULTIPLIER_DEFAULT;
    platform_inherit_y_down_multiplier = ACTOR_PLATFORM_INHERIT_Y_DOWN_MULTIPLIER_DEFAULT;

    jump_buffer_frames = ACTOR_JUMP_BUFFER_FRAMES_DEFAULT;
    ground_coyote_frames = ACTOR_GROUND_COYOTE_FRAMES_DEFAULT;
    wall_coyote_frames = ACTOR_WALL_COYOTE_FRAMES_DEFAULT;
    ledge_coyote_frames = ACTOR_LEDGE_COYOTE_FRAMES_DEFAULT;
    drop_through_frames = ACTOR_DROP_THROUGH_FRAMES_DEFAULT;
    wall_jump_lockout_frames = ACTOR_WALL_JUMP_LOCKOUT_FRAMES_DEFAULT;

    water_max = ACTOR_WATER_MAX_DEFAULT;
    empty_spray_grace_frames = ACTOR_EMPTY_SPRAY_GRACE_FRAMES_DEFAULT;
    spray_ground_lift_suppressed = ACTOR_SPRAY_GROUND_LIFT_SUPPRESS;
    ground_launch_charge_min = ACTOR_GROUND_LAUNCH_CHARGE_MIN_DEFAULT;

    abilities = ACTOR_ABILITY_JUMP;

    debug_enabled = ACTOR_DEBUG_DEFAULT;
    debug_draw_collision = ACTOR_DEBUG_DRAW_COLLISION_DEFAULT;
    debug_draw_probes = ACTOR_DEBUG_DRAW_PROBES_DEFAULT;
    debug_draw_vectors = ACTOR_DEBUG_DRAW_VECTORS_DEFAULT;
    debug_print_events = ACTOR_DEBUG_PRINT_EVENTS_DEFAULT;
}

/// @function ActorInputFrame
/// @description Creates a data-only per-frame input snapshot.
/// @returns {Struct} Empty actor input frame.
function ActorInputFrame() constructor {
    source_type = ActorInputSource.NONE;
    source_id = noone;
    frame_number = 0;

    move_x = 0;
    move_y = 0;
    raw_move_x = 0;
    raw_move_y = 0;

    jump_pressed = false;
    jump_held = false;
    jump_released = false;
    run_pressed = false;
    run_held = false;
    run_released = false;
    slide_pressed = false;
    slide_held = false;
    slide_released = false;
    spray_pressed = false;
    spray_held = false;
    spray_released = false;
    charge_pressed = false;
    charge_held = false;
    charge_released = false;
    cancel_pressed = false;
    cancel_held = false;
    cancel_released = false;
    drop_pressed = false;
    drop_held = false;
    drop_released = false;

    aim_x = 1;
    aim_y = 0;
    aim_angle = 0;
    raw_aim_x = 1;
    raw_aim_y = 0;

    nozzle_next_pressed = false;
    nozzle_prev_pressed = false;
    nozzle_value_delta = 0;

    debug_toggle_pressed = false;
}

/// @function ActorForce
/// @description Creates an external force entry for layered actor velocity.
/// @returns {Struct} Empty actor force data.
function ActorForce() constructor {
    type = ActorForceType.ADDITIVE;
    x = 0;
    y = 0;
    duration_frames = 0;
    elapsed_frames = 0;
    damping = 1;
    control_reduction = 0;
    source_id = noone;
    metadata = noone;
    active = false;
}

/// @function ActorSurfaceInfo
/// @description Creates contact surface metadata used by collision and movement features.
/// @returns {Struct} Default surface metadata.
function ActorSurfaceInfo() constructor {
    surface_type = ActorSurfaceType.NORMAL;
    friction_multiplier = 1;
    accel_multiplier = 1;
    top_speed_multiplier = 1;
    jump_multiplier = 1;
    recoil_multiplier = 1;
    conveyor_x = 0;
    conveyor_y = 0;
    hazard = false;
    water_refill_rate = 0;
}

/// @function ActorContactInfo
/// @description Creates one collision/contact slot for controller runtime state.
/// @returns {Struct} Empty contact data.
function ActorContactInfo() constructor {
    active = false;
    side = ActorCollisionSide.NONE;
    object_id = noone;
    normal_x = 0;
    normal_y = 0;
    depth = 0;
    surface = new ActorSurfaceInfo();
}

/// @function ActorController
/// @description Creates runtime simulation state owned by the generic actor controller.
/// @returns {Struct} Actor controller runtime data.
function ActorController() constructor {
    version = ACTOR_CONTROLLER_VERSION;
    stats = noone;

    x = 0;
    y = 0;
    x_previous = 0;
    y_previous = 0;
    hsp = 0;
    vsp = 0;
    external_hsp = 0;
    external_vsp = 0;
    total_hsp = 0;
    total_vsp = 0;
    external_control_reduction = 0;

    state = ActorMoveState.AIRBORNE;
    state_previous = ActorMoveState.AIRBORNE;
    facing = ActorFacing.RIGHT;

    is_grounded = false;
    is_physically_grounded = false;
    was_grounded = false;
    ceiling_contact = false;
    ground_normal_x = 0;
    ground_normal_y = -1;
    ground_angle = 0;
    ground_tangent_x = 1;
    ground_tangent_y = 0;
    ground_slope_walkable = true;
    ground_object = noone;

    wall_left = false;
    wall_right = false;
    wall_normal_x = 0;
    wall_normal_y = 0;
    wall_object = noone;

    jump_buffer_timer = 0;
    ground_coyote_timer = 0;
    wall_coyote_timer = 0;
    ledge_coyote_timer = 0;
    drop_through_timer = 0;
    wall_jump_lockout_timer = 0;

    platform_object = noone;
    platform_velocity_x = 0;
    platform_velocity_y = 0;
    platform_carry_x = 0;
    platform_carry_y = 0;
    platform_previous_object = noone;
    platform_inherit_object = noone;
    platform_inherit_velocity_x = 0;
    platform_inherit_velocity_y = 0;

    one_way_ignore_object = noone;

    active_forces = [];
    active_force_count = 0;
    contact_left = new ActorContactInfo();
    contact_right = new ActorContactInfo();
    contact_top = new ActorContactInfo();
    contact_bottom = new ActorContactInfo();
    surface_info = new ActorSurfaceInfo();

    collision_blocked_x = false;
    collision_blocked_y = false;
    collision_last_move_x = 0;
    collision_last_move_y = 0;
    collision_iterations = 0;
    collision_unstuck_succeeded = true;
    collision_unstuck_offset_x = 0;
    collision_unstuck_offset_y = 0;
    collision_ignore_object = noone;

    spray_active = false;
    spray_mode = ActorSprayMode.NONE;
    spray_aim_x = 1;
    spray_aim_y = 0;
    spray_origin_x = 0;
    spray_origin_y = 0;
    spray_recoil_x = 0;
    spray_recoil_y = 0;

    water_current = ACTOR_WATER_MAX_DEFAULT;
    water_max = ACTOR_WATER_MAX_DEFAULT;
    charge_amount = 0;
    charge_timer = 0;
    charge_ready = false;
    charge_overready = false;

    input = noone;
    input_previous = noone;
    events = [];
    event_count = 0;
    step_index = 0;

    debug_enabled = ACTOR_DEBUG_DEFAULT;
    debug_draw_collision = ACTOR_DEBUG_DRAW_COLLISION_DEFAULT;
    debug_draw_probes = ACTOR_DEBUG_DRAW_PROBES_DEFAULT;
    debug_draw_vectors = ACTOR_DEBUG_DRAW_VECTORS_DEFAULT;
    debug_print_events = ACTOR_DEBUG_PRINT_EVENTS_DEFAULT;
}
