/// @description Core actor controller shell and instance synchronization.

/// @function actor_controller_create
/// @description Creates a controller at a position using cloned actor stats.
/// @param {Struct} _stats Actor stats used to configure the controller.
/// @param {Real} _x Starting x position.
/// @param {Real} _y Starting y position.
/// @returns {Struct} New actor controller.
function actor_controller_create(_stats, _x, _y) {
    var _stats_source = actor_stats_validate(_stats) ? _stats : actor_stats_create_default();
    var _actor = new ActorController();

    _actor.stats = actor_stats_clone(_stats_source);
    _actor.water_max = _actor.stats.water_max;
    _actor.water_current = _actor.stats.water_max;
    _actor.debug_enabled = actor_stats_get_optional(_actor.stats, "debug_enabled", ACTOR_DEBUG_DEFAULT);
    _actor.debug_draw_collision = actor_stats_get_optional(_actor.stats, "debug_draw_collision", ACTOR_DEBUG_DRAW_COLLISION_DEFAULT);
    _actor.debug_draw_probes = actor_stats_get_optional(_actor.stats, "debug_draw_probes", ACTOR_DEBUG_DRAW_PROBES_DEFAULT);
    _actor.debug_draw_vectors = actor_stats_get_optional(_actor.stats, "debug_draw_vectors", ACTOR_DEBUG_DRAW_VECTORS_DEFAULT);
    _actor.debug_print_events = actor_stats_get_optional(_actor.stats, "debug_print_events", ACTOR_DEBUG_PRINT_EVENTS_DEFAULT);

    actor_controller_set_position(_actor, _x, _y);
    _actor.x_previous = _actor.x;
    _actor.y_previous = _actor.y;
    _actor.spray_origin_x = _actor.x;
    _actor.spray_origin_y = _actor.y;

    return _actor;
}

/// @function actor_controller_update
/// @description Runs the guide 4 controller update for movement, jump, terrain, and platform collision.
/// @param {Struct} _actor Actor controller to update.
/// @param {Struct} _input Input frame for this update.
/// @returns {Struct} Updated actor controller.
function actor_controller_update(_actor, _input) {
    if (!is_struct(_actor)) {
        return _actor;
    }

    actor_controller_begin_step(_actor, _input);
    actor_controller_update_one_way_ignore(_actor);
    actor_controller_apply_platform_carry(_actor);
    actor_collision_try_unstuck(_actor);
    var _had_jump_buffer_on_step_start = _actor.jump_buffer_timer > 0;
    actor_controller_update_timers(_actor);
    actor_controller_try_start_drop_through(_actor);
    actor_controller_try_jump(_actor);
    actor_controller_apply_movement_intent(_actor);
    actor_controller_apply_jump_cut(_actor);
    actor_controller_apply_gravity(_actor);
    actor_controller_apply_velocity_limits(_actor);
    actor_collision_move_and_slide(_actor, _actor.hsp + _actor.external_hsp, _actor.vsp + _actor.external_vsp);
    actor_controller_handle_landing(_actor);
    actor_controller_try_landing_buffered_jump(_actor, _had_jump_buffer_on_step_start);
    actor_controller_update_state(_actor);
    actor_controller_end_step(_actor);

    return _actor;
}

/// @function actor_controller_begin_step
/// @description Caches previous frame state, clears one-frame data, and stores current input.
/// @param {Struct} _actor Actor controller to prepare.
/// @param {Struct} _input Input frame to store.
/// @returns {Undefined} No return value.
function actor_controller_begin_step(_actor, _input) {
    _actor.x_previous = _actor.x;
    _actor.y_previous = _actor.y;
    _actor.state_previous = _actor.state;
    _actor.was_grounded = _actor.is_physically_grounded;
    _actor.input_previous = _actor.input;

    _actor.events = [];
    _actor.event_count = 0;
    _actor.platform_carry_x = 0;
    _actor.platform_carry_y = 0;
    _actor.collision_ignore_object = noone;

    if (is_struct(_input)) {
        _actor.input = actor_input_frame_normalize(_input);
    } else {
        _actor.input = actor_input_frame_create_empty(ActorInputSource.NONE, noone, _actor.step_index);
    }

    _actor.spray_aim_x = _actor.input.aim_x;
    _actor.spray_aim_y = _actor.input.aim_y;
    _actor.spray_origin_x = _actor.x;
    _actor.spray_origin_y = _actor.y;
}

/// @function actor_controller_end_step
/// @description Finalizes guide 0 bookkeeping after the update shell.
/// @param {Struct} _actor Actor controller to finalize.
/// @returns {Undefined} No return value.
function actor_controller_end_step(_actor) {
    _actor.water_current = clamp(_actor.water_current, 0, _actor.water_max);
    _actor.charge_amount = clamp(_actor.charge_amount, 0, 1);
    actor_controller_update_one_way_ignore(_actor);
    _actor.step_index += 1;
}

/// @function actor_controller_record_event
/// @description Records a one-frame controller event for later presentation, audio, and gameplay systems.
/// @param {Struct} _actor Actor controller receiving the event.
/// @param {Real} _event_type ActorControllerEvent enum value to record.
/// @returns {Struct} Event struct that was recorded, or noone when the actor is invalid.
function actor_controller_record_event(_actor, _event_type) {
    if (!is_struct(_actor)) {
        return noone;
    }

    var _event = {
        type: _event_type,
        frame: _actor.step_index,
        state: _actor.state,
        x: _actor.x,
        y: _actor.y
    };

    array_push(_actor.events, _event);
    _actor.event_count = array_length(_actor.events);

    return _event;
}

/// @function actor_controller_update_one_way_ignore
/// @description Clears expired one-way platform ignore state after the actor is safely below or the timer ends.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_update_one_way_ignore(_actor) {
    if (!is_struct(_actor) || (_actor.one_way_ignore_object == noone)) {
        return;
    }

    if ((_actor.drop_through_timer <= 0) || !instance_exists(_actor.one_way_ignore_object)) {
        _actor.one_way_ignore_object = noone;
        return;
    }

    var _actor_rect = actor_collision_get_actor_rect(_actor, _actor.x, _actor.y);
    var _platform_rect = actor_collision_get_instance_rect(_actor.one_way_ignore_object);

    if (_actor_rect.top > _platform_rect.bottom + ACTOR_CONTACT_PROBE_DISTANCE) {
        _actor.one_way_ignore_object = noone;
    }
}

/// @function actor_controller_try_start_drop_through
/// @description Starts a one-way platform drop-through when input, ability, and current ground allow it.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when drop-through state started.
function actor_controller_try_start_drop_through(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.input)) {
        return false;
    }

    if (!_actor.input.drop_pressed || ((_actor.stats.abilities & ACTOR_ABILITY_DROP_THROUGH) == 0)) {
        return false;
    }

    if (!_actor.is_physically_grounded || !actor_collision_is_one_way_platform(_actor.ground_object)) {
        return false;
    }

    _actor.drop_through_timer = actor_controller_get_timer_stat(_actor, "drop_through_frames", ACTOR_DROP_THROUGH_FRAMES_DEFAULT);
    _actor.one_way_ignore_object = _actor.ground_object;
    _actor.is_physically_grounded = false;
    _actor.is_grounded = false;
    _actor.ground_object = noone;
    _actor.platform_object = noone;
    _actor.platform_velocity_x = 0;
    _actor.platform_velocity_y = 0;
    _actor.contact_bottom = actor_collision_reset_contact(_actor.contact_bottom);

    var _nudge = ACTOR_ONE_WAY_DROP_NUDGE_DEFAULT;
    if (!actor_collision_place_solid(_actor, _actor.x, _actor.y + _nudge)) {
        _actor.y += _nudge;
    }

    return true;
}

/// @function actor_controller_apply_platform_carry
/// @description Moves an actor by the previous grounded moving platform's velocity through collision-safe movement.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Struct} Movement result from the carry move.
function actor_controller_apply_platform_carry(_actor) {
    var _result = actor_collision_create_move_result();

    if (!is_struct(_actor) || !_actor.was_grounded || !instance_exists(_actor.platform_object)) {
        return _result;
    }

    var _platform = _actor.platform_object;
    var _velocity_x = actor_surface_read_optional(_platform, "platform_velocity_x", 0);
    var _velocity_y = actor_surface_read_optional(_platform, "platform_velocity_y", 0);

    _actor.platform_velocity_x = _velocity_x;
    _actor.platform_velocity_y = _velocity_y;

    if ((abs(_velocity_x) <= ACTOR_EPSILON) && (abs(_velocity_y) <= ACTOR_EPSILON)) {
        return _result;
    }

    _actor.collision_ignore_object = _platform;
    _result = actor_collision_move_and_slide(_actor, _velocity_x, _velocity_y);
    _actor.collision_ignore_object = noone;
    _actor.platform_carry_x = _result.moved_x;
    _actor.platform_carry_y = _result.moved_y;

    return _result;
}

/// @function actor_controller_apply_movement_intent
/// @description Applies horizontal ground or air control from the actor's current input frame.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_apply_movement_intent(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    if (_actor.is_physically_grounded) {
        actor_controller_apply_ground_movement(_actor);
    } else {
        actor_controller_apply_air_movement(_actor);
    }
}

/// @function actor_controller_apply_ground_movement
/// @description Applies walk/run acceleration, turn acceleration, deceleration, and friction on flat ground.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_apply_ground_movement(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.input)) {
        return;
    }

    var _input_x = _actor.input.move_x;
    var _surface_accel = actor_controller_get_surface_multiplier(_actor, "accel_multiplier");
    var _surface_friction = actor_controller_get_surface_multiplier(_actor, "friction_multiplier");
    var _surface_top_speed = actor_controller_get_surface_multiplier(_actor, "top_speed_multiplier");

    if (abs(_input_x) > ACTOR_EPSILON) {
        var _target_speed = actor_controller_get_selected_horizontal_speed(_actor) * _surface_top_speed;
        var _target_hsp = _input_x * _target_speed;
        var _turning = actor_controller_is_reversing_horizontal(_actor.hsp, _input_x);
        var _accel = _turning ? _actor.stats.ground_turn_accel : _actor.stats.ground_accel;

        _actor.hsp = actor_controller_approach(_actor.hsp, _target_hsp, _accel * _surface_accel);
        _actor.facing = (_input_x < 0) ? ActorFacing.LEFT : ActorFacing.RIGHT;
        return;
    }

    var _slowdown = (_actor.stats.ground_decel + _actor.stats.ground_friction) * _surface_friction;
    _actor.hsp = actor_controller_approach(_actor.hsp, 0, _slowdown);
}

/// @function actor_controller_apply_air_movement
/// @description Applies weaker horizontal air control, turn acceleration, and air deceleration.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_apply_air_movement(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.input)) {
        return;
    }

    var _input_x = _actor.input.move_x;

    if (abs(_input_x) > ACTOR_EPSILON) {
        var _selected_speed = actor_controller_get_selected_horizontal_speed(_actor);
        var _target_speed = min(_selected_speed, _actor.stats.air_max_speed);
        var _target_hsp = _input_x * _target_speed;
        var _turning = actor_controller_is_reversing_horizontal(_actor.hsp, _input_x);
        var _accel = _turning ? _actor.stats.air_turn_accel : _actor.stats.air_accel;

        _actor.hsp = actor_controller_approach(_actor.hsp, _target_hsp, _accel);
        _actor.facing = (_input_x < 0) ? ActorFacing.LEFT : ActorFacing.RIGHT;
        return;
    }

    _actor.hsp = actor_controller_approach(_actor.hsp, 0, _actor.stats.air_decel);
}

/// @function actor_controller_project_velocity_on_slope
/// @description Projects grounded horizontal movement along the current walkable slope tangent.
/// @param {Struct} _actor Actor controller containing ground tangent data.
/// @param {Real} _move_x Requested horizontal movement.
/// @param {Real} _move_y Requested vertical movement.
/// @returns {Struct} Projected movement with x and y fields.
function actor_controller_project_velocity_on_slope(_actor, _move_x, _move_y) {
    var _move = {
        x: _move_x,
        y: _move_y
    };

    if (!is_struct(_actor) || !_actor.is_physically_grounded || !_actor.ground_slope_walkable) {
        return _move;
    }

    if ((_actor.ground_angle <= ACTOR_EPSILON) || (_actor.vsp < 0) || (abs(_actor.ground_tangent_x) <= ACTOR_EPSILON)) {
        return _move;
    }

    _move.y += _move_x * (_actor.ground_tangent_y / _actor.ground_tangent_x);

    return _move;
}

/// @function actor_controller_apply_gravity
/// @description Applies rise or fall gravity to controlled vertical velocity and respects max fall speed.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_apply_gravity(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    if (_actor.is_physically_grounded && _actor.vsp >= 0) {
        _actor.vsp = 0;
        return;
    }

    var _gravity = (_actor.vsp < 0) ? _actor.stats.gravity_rise : _actor.stats.gravity_fall;
    _actor.vsp = min(_actor.vsp + _gravity, _actor.stats.max_fall_speed);
}

/// @function actor_controller_apply_velocity_limits
/// @description Caps controlled velocity without clamping external velocity layers.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_apply_velocity_limits(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    var _max_fall_speed = max(0, _actor.stats.max_fall_speed);

    _actor.hsp = clamp(_actor.hsp, -ACTOR_HARD_SPEED_CAP, ACTOR_HARD_SPEED_CAP);
    _actor.vsp = clamp(_actor.vsp, -ACTOR_HARD_SPEED_CAP, _max_fall_speed);
}

/// @function actor_controller_get_selected_horizontal_speed
/// @description Gets the current walk or run target speed from input and stats.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Real} Non-negative horizontal target speed.
function actor_controller_get_selected_horizontal_speed(_actor) {
    if (!is_struct(_actor)) {
        return 0;
    }

    var _run_held = is_struct(_actor.input)
        && variable_struct_exists(_actor.input, "run_held")
        && _actor.input.run_held;
    var _speed = _run_held ? _actor.stats.run_speed : _actor.stats.walk_speed;

    return max(0, _speed);
}

/// @function actor_controller_get_surface_multiplier
/// @description Reads a non-negative multiplier from the current surface info.
/// @param {Struct} _actor Actor controller with surface info.
/// @param {String} _field_name Surface multiplier field name.
/// @returns {Real} Surface multiplier, or 1 when unavailable.
function actor_controller_get_surface_multiplier(_actor, _field_name) {
    if (!is_struct(_actor) || !is_struct(_actor.surface_info)) {
        return 1;
    }

    if (!variable_struct_exists(_actor.surface_info, _field_name)) {
        return 1;
    }

    return max(0, variable_struct_get(_actor.surface_info, _field_name));
}

/// @function actor_controller_is_reversing_horizontal
/// @description Checks whether input is trying to reverse the current controlled horizontal velocity.
/// @param {Real} _hsp Current controlled horizontal speed.
/// @param {Real} _input_x Current horizontal input direction.
/// @returns {Bool} True when input opposes meaningful current horizontal speed.
function actor_controller_is_reversing_horizontal(_hsp, _input_x) {
    return (abs(_hsp) > ACTOR_EPSILON)
        && (abs(_input_x) > ACTOR_EPSILON)
        && (sign(_hsp) != sign(_input_x));
}

/// @function actor_controller_approach
/// @description Moves a value toward a target by no more than a positive step amount.
/// @param {Real} _value Current value.
/// @param {Real} _target Target value.
/// @param {Real} _step Maximum amount to move this update.
/// @returns {Real} Updated value.
function actor_controller_approach(_value, _target, _step) {
    var _amount = max(0, _step);

    if (_value < _target) {
        return min(_value + _amount, _target);
    }

    if (_value > _target) {
        return max(_value - _amount, _target);
    }

    return _value;
}

/// @function actor_controller_set_position
/// @description Sets the controller's real-valued position.
/// @param {Struct} _actor Actor controller to move.
/// @param {Real} _x New x position.
/// @param {Real} _y New y position.
/// @returns {Struct} The actor controller passed in.
function actor_controller_set_position(_actor, _x, _y) {
    _actor.x = _x;
    _actor.y = _y;

    return _actor;
}

/// @function actor_controller_set_velocity
/// @description Sets the controller's controlled velocity.
/// @param {Struct} _actor Actor controller to update.
/// @param {Real} _hsp New horizontal speed.
/// @param {Real} _vsp New vertical speed.
/// @returns {Struct} The actor controller passed in.
function actor_controller_set_velocity(_actor, _hsp, _vsp) {
    _actor.hsp = _hsp;
    _actor.vsp = _vsp;

    return _actor;
}

/// @function actor_controller_apply_to_instance
/// @description Applies controller position back to a GameMaker instance.
/// @param {Struct} _actor Actor controller containing output position.
/// @param {Id.Instance} _instance Instance to synchronize.
/// @returns {Undefined} No return value.
function actor_controller_apply_to_instance(_actor, _instance) {
    var _x = _actor.x;
    var _y = _actor.y;

    with (_instance) {
        x = _x;
        y = _y;
    }
}
