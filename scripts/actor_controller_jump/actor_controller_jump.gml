/// @description Jump assist timer helpers for the generic actor controller.

/// @function actor_controller_update_timers
/// @description Decrements assist timers once, then refreshes timers from current input and contact state.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_update_timers(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    _actor.jump_buffer_timer = max(0, _actor.jump_buffer_timer - 1);
    _actor.ground_coyote_timer = max(0, _actor.ground_coyote_timer - 1);
    _actor.wall_coyote_timer = max(0, _actor.wall_coyote_timer - 1);
    _actor.ledge_coyote_timer = max(0, _actor.ledge_coyote_timer - 1);
    _actor.drop_through_timer = max(0, _actor.drop_through_timer - 1);
    _actor.wall_jump_lockout_timer = max(0, _actor.wall_jump_lockout_timer - 1);

    actor_controller_update_jump_buffer(_actor);
    actor_controller_update_coyote_timers(_actor);
}

/// @function actor_controller_update_jump_buffer
/// @description Refreshes the jump buffer timer when the current input frame pressed jump.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_update_jump_buffer(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.input)) {
        return;
    }

    if (_actor.input.jump_pressed) {
        _actor.jump_buffer_timer = actor_controller_get_timer_stat(_actor, "jump_buffer_frames", ACTOR_JUMP_BUFFER_FRAMES_DEFAULT);
    }
}

/// @function actor_controller_update_coyote_timers
/// @description Refreshes coyote timers from physical contact fields.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_update_coyote_timers(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    if (_actor.is_physically_grounded) {
        _actor.ground_coyote_timer = actor_controller_get_timer_stat(_actor, "ground_coyote_frames", ACTOR_GROUND_COYOTE_FRAMES_DEFAULT);
    }

    if (_actor.wall_left || _actor.wall_right) {
        _actor.wall_coyote_timer = actor_controller_get_timer_stat(_actor, "wall_coyote_frames", ACTOR_WALL_COYOTE_FRAMES_DEFAULT);
    }
}

/// @function actor_controller_consume_jump_buffer
/// @description Clears the jump buffer timer when buffered jump input is available.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when a buffered jump was consumed.
function actor_controller_consume_jump_buffer(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    if (_actor.jump_buffer_timer <= 0) {
        return false;
    }

    _actor.jump_buffer_timer = 0;

    return true;
}

/// @function actor_controller_can_use_ground_coyote
/// @description Reports whether ground coyote time is currently available for jump eligibility.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when ground coyote time is available.
function actor_controller_can_use_ground_coyote(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    return _actor.ground_coyote_timer > 0;
}

/// @function actor_controller_consume_ground_coyote
/// @description Clears ground coyote time when it is available.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when ground coyote time was consumed.
function actor_controller_consume_ground_coyote(_actor) {
    if (!actor_controller_can_use_ground_coyote(_actor)) {
        return false;
    }

    _actor.ground_coyote_timer = 0;

    return true;
}

/// @function actor_controller_can_jump
/// @description Reports whether the actor can execute a standard ground or coyote jump this update.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when jump input, ability, state, and grounded eligibility all allow a jump.
function actor_controller_can_jump(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    if ((_actor.stats.abilities & ACTOR_ABILITY_JUMP) == 0) {
        return false;
    }

    if (_actor.jump_buffer_timer <= 0) {
        return false;
    }

    switch (_actor.state) {
        case ActorMoveState.DEAD:
        case ActorMoveState.LOCKED:
        case ActorMoveState.STUNNED:
        case ActorMoveState.MANTLE:
        case ActorMoveState.LEDGE_GRAB:
            return false;
    }

    return _actor.is_physically_grounded || actor_controller_can_use_ground_coyote(_actor);
}

/// @function actor_controller_try_jump
/// @description Executes a standard jump when buffered input and eligibility are available.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when a jump executed.
function actor_controller_try_jump(_actor) {
    if (!actor_controller_can_jump(_actor)) {
        return false;
    }

    return actor_controller_execute_jump(_actor);
}

/// @function actor_controller_try_landing_buffered_jump
/// @description Retries buffered jump execution after landing contacts refresh, including the last pre-decrement buffer frame.
/// @param {Struct} _actor Actor controller to update.
/// @param {Bool} _had_jump_buffer_on_step_start True when jump buffer was active before this update decremented timers.
/// @returns {Bool} True when a landing buffered jump executed.
function actor_controller_try_landing_buffered_jump(_actor, _had_jump_buffer_on_step_start) {
    if (!is_struct(_actor)) {
        return false;
    }

    if (_actor.was_grounded || !_actor.is_physically_grounded) {
        return false;
    }

    var _restored_last_buffer_frame = false;
    if (_actor.jump_buffer_timer <= 0) {
        if (!_had_jump_buffer_on_step_start) {
            return false;
        }

        _actor.jump_buffer_timer = 1;
        _restored_last_buffer_frame = true;
    }

    var _jumped = actor_controller_try_jump(_actor);
    if (!_jumped && _restored_last_buffer_frame) {
        _actor.jump_buffer_timer = 0;
    }

    return _jumped;
}

/// @function actor_controller_execute_jump
/// @description Applies jump velocity, consumes jump assists, clears physical grounded state, and records a jump event.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when jump velocity was applied.
function actor_controller_execute_jump(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    actor_controller_consume_jump_buffer(_actor);
    actor_controller_consume_ground_coyote(_actor);

    var _jump_multiplier = actor_controller_get_surface_multiplier(_actor, "jump_multiplier");
    _actor.vsp = _actor.stats.jump_speed * _jump_multiplier;
    actor_controller_apply_platform_jump_inheritance(_actor);
    _actor.is_grounded = false;
    _actor.is_physically_grounded = false;
    _actor.ground_object = noone;
    _actor.platform_object = noone;
    _actor.platform_inherit_object = noone;
    _actor.platform_inherit_velocity_x = 0;
    _actor.platform_inherit_velocity_y = 0;
    _actor.contact_bottom = actor_collision_reset_contact(_actor.contact_bottom);

    actor_controller_set_state(_actor, ActorMoveState.AIRBORNE);
    actor_controller_record_event(_actor, ActorControllerEvent.JUMP);

    return true;
}

/// @function actor_controller_apply_platform_jump_inheritance
/// @description Adds grounded moving platform velocity to a jump through the external force layer.
/// @param {Struct} _actor Actor controller executing a jump.
/// @returns {Undefined} No return value.
function actor_controller_apply_platform_jump_inheritance(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    var _platform_velocity_x = 0;
    var _platform_velocity_y = 0;
    var _has_platform_velocity = false;

    if (instance_exists(_actor.platform_object)) {
        _platform_velocity_x = _actor.platform_velocity_x;
        _platform_velocity_y = _actor.platform_velocity_y;
        _has_platform_velocity = true;
    } else if (instance_exists(_actor.platform_inherit_object)) {
        _platform_velocity_x = _actor.platform_inherit_velocity_x;
        _platform_velocity_y = _actor.platform_inherit_velocity_y;
        _has_platform_velocity = true;
    }

    if (!_has_platform_velocity) {
        return;
    }

    var _inherit_x = actor_stats_get_optional(_actor.stats, "platform_inherit_x_multiplier", ACTOR_PLATFORM_INHERIT_X_MULTIPLIER_DEFAULT);
    var _inherit_y_up = actor_stats_get_optional(_actor.stats, "platform_inherit_y_up_multiplier", ACTOR_PLATFORM_INHERIT_Y_UP_MULTIPLIER_DEFAULT);
    var _inherit_y_down = actor_stats_get_optional(_actor.stats, "platform_inherit_y_down_multiplier", ACTOR_PLATFORM_INHERIT_Y_DOWN_MULTIPLIER_DEFAULT);
    var _platform_y_multiplier = (_platform_velocity_y < 0) ? _inherit_y_up : _inherit_y_down;
    var _force_x = _platform_velocity_x * _inherit_x;
    var _force_y = _platform_velocity_y * _platform_y_multiplier;

    if ((abs(_force_x) <= ACTOR_EPSILON) && (abs(_force_y) <= ACTOR_EPSILON)) {
        return;
    }

    actor_controller_add_force(_actor, actor_force_create(
        ActorForceType.PLATFORM_CARRY,
        _force_x,
        _force_y,
        1,
        1,
        0,
        instance_exists(_actor.platform_object) ? _actor.platform_object : _actor.platform_inherit_object,
        noone
    ));
}

/// @function actor_controller_apply_jump_cut
/// @description Shortens an active upward jump when jump is released early.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_apply_jump_cut(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.input)) {
        return;
    }

    if (!_actor.input.jump_released || _actor.vsp >= 0) {
        return;
    }

    var _cut_multiplier = clamp(_actor.stats.jump_cut_multiplier, 0, 1);
    _actor.vsp *= _cut_multiplier;
}

/// @function actor_controller_handle_landing
/// @description Detects physical ground contact transitions and records landing events.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_handle_landing(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    if (!_actor.was_grounded && _actor.is_physically_grounded) {
        _actor.vsp = 0;
        actor_controller_record_event(_actor, ActorControllerEvent.LAND);
    }
}

/// @function actor_controller_get_timer_stat
/// @description Reads a non-negative frame timer value from actor stats.
/// @param {Struct} _actor Actor controller with stats.
/// @param {String} _field_name Stats field name to read.
/// @param {Real} _default_value Default frame count when stats omit the field.
/// @returns {Real} Non-negative timer frame count.
function actor_controller_get_timer_stat(_actor, _field_name, _default_value) {
    if (!is_struct(_actor)) {
        return max(0, floor(_default_value));
    }

    var _value = actor_stats_get_optional(_actor.stats, _field_name, _default_value);

    return max(0, floor(_value));
}
