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

    if (is_struct(_actor.input) && _actor.input.drop_pressed) {
        _actor.drop_through_timer = actor_controller_get_timer_stat(_actor, "drop_through_frames", ACTOR_DROP_THROUGH_FRAMES_DEFAULT);
    }
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
