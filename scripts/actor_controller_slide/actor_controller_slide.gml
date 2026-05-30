/// @description Grounded slide and belly-slide helpers for the generic actor controller.

/// @function actor_controller_get_slide_stat
/// @description Reads a non-negative slide tuning value from actor stats.
/// @param {Struct} _actor Actor controller containing stats.
/// @param {String} _field_name Stats field name to read.
/// @param {Real} _default_value Default value when stats omit the field.
/// @returns {Real} Non-negative slide stat value.
function actor_controller_get_slide_stat(_actor, _field_name, _default_value) {
    if (!is_struct(_actor)) {
        return max(0, _default_value);
    }

    return max(0, actor_stats_get_optional(_actor.stats, _field_name, _default_value));
}

/// @function actor_controller_has_slide_ability
/// @description Reports whether an actor's stats allow grounded slide.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when slide ability is enabled.
function actor_controller_has_slide_ability(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    var _abilities = actor_stats_get_optional(_actor.stats, "abilities", ACTOR_ABILITY_NONE);

    return (_abilities & ACTOR_ABILITY_SLIDE) != 0;
}

/// @function actor_controller_get_slide_height
/// @description Gets the actor's reduced slide collision height from stats.
/// @param {Struct} _actor Actor controller containing stats.
/// @returns {Real} Positive slide collision height no taller than standing height.
function actor_controller_get_slide_height(_actor) {
    if (!is_struct(_actor)) {
        return ACTOR_EPSILON;
    }

    var _standing_height = actor_collision_get_actor_standing_height(_actor);
    var _slide_height = actor_stats_get_optional(_actor.stats, "bbox_slide_height", _standing_height);

    return clamp(_slide_height, ACTOR_EPSILON, _standing_height);
}

/// @function actor_controller_get_slide_horizontal_speed
/// @description Gets the current horizontal speed used for slide entry and exit checks.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Real} Combined controlled and external horizontal speed.
function actor_controller_get_slide_horizontal_speed(_actor) {
    if (!is_struct(_actor)) {
        return 0;
    }

    return _actor.hsp + _actor.external_hsp;
}

/// @function actor_controller_can_stand_from_slide
/// @description Checks whether standing height and ceiling clearance fit above the current feet position.
/// @param {Struct} _actor Actor controller to test.
/// @returns {Bool} True when the actor can safely restore standing height.
function actor_controller_can_stand_from_slide(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    var _standing_height = actor_collision_get_actor_standing_height(_actor);
    var _current_height = actor_collision_get_actor_height(_actor);
    if (_current_height >= _standing_height - ACTOR_EPSILON) {
        return true;
    }

    var _clearance = actor_controller_get_slide_stat(
        _actor,
        "slide_ceiling_clearance",
        ACTOR_SLIDE_CEILING_CLEARANCE_DEFAULT
    );
    var _test_height = _standing_height + _clearance;
    var _feet_y = actor_collision_get_actor_feet_y(_actor);
    var _test_y = actor_collision_get_center_y_for_height(_feet_y, _test_height);

    return !actor_collision_place_solid_with_height(_actor, _actor.x, _test_y, _test_height);
}

/// @function actor_controller_can_jump_from_slide
/// @description Reports whether slide state permits the current buffered jump to execute.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when slide jump is enabled and standing clearance is available.
function actor_controller_can_jump_from_slide(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    var _jump_allowed = actor_stats_get_optional(
        _actor.stats,
        "slide_jump_allowed",
        ACTOR_SLIDE_JUMP_ALLOWED_DEFAULT
    );

    return _jump_allowed && actor_controller_can_stand_from_slide(_actor);
}

/// @function actor_controller_can_slide
/// @description Reports whether the actor can enter grounded slide from the current frame.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when slide input, ability, state, ground, and momentum allow entry.
function actor_controller_can_slide(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.stats) || !is_struct(_actor.input)) {
        return false;
    }

    if (_actor.slide_active || actor_controller_is_state(_actor, ActorMoveState.SLIDE)) {
        return false;
    }

    if (!actor_controller_has_slide_ability(_actor) || !_actor.input.slide_pressed) {
        return false;
    }

    switch (_actor.state) {
        case ActorMoveState.DEAD:
        case ActorMoveState.LOCKED:
        case ActorMoveState.STUNNED:
        case ActorMoveState.KNOCKBACK:
        case ActorMoveState.MANTLE:
        case ActorMoveState.LEDGE_GRAB:
            return false;
    }

    if (!_actor.is_physically_grounded) {
        return false;
    }

    var _standing_height = actor_collision_get_actor_standing_height(_actor);
    var _slide_height = actor_controller_get_slide_height(_actor);
    if (_slide_height >= _standing_height - ACTOR_EPSILON) {
        return false;
    }

    var _min_entry_speed = actor_controller_get_slide_stat(
        _actor,
        "slide_min_entry_speed",
        ACTOR_SLIDE_MIN_ENTRY_SPEED_DEFAULT
    );
    var _speed = abs(actor_controller_get_slide_horizontal_speed(_actor));

    return _speed >= _min_entry_speed - ACTOR_EPSILON;
}

/// @function actor_controller_try_slide
/// @description Enters grounded slide when the current frame is eligible.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when slide started.
function actor_controller_try_slide(_actor) {
    if (!actor_controller_can_slide(_actor)) {
        return false;
    }

    var _speed = actor_controller_get_slide_horizontal_speed(_actor);
    var _slide_height = actor_controller_get_slide_height(_actor);

    _actor.slide_active = true;
    _actor.slide_timer = 0;
    _actor.slide_previous_collision_height = actor_collision_get_actor_height(_actor);
    _actor.slide_stand_blocked = false;
    _actor.slide_entry_speed = abs(_speed);

    actor_collision_set_actor_height_keep_feet(_actor, _slide_height);
    actor_collision_refresh_contacts(_actor);

    if (!actor_controller_set_state(_actor, ActorMoveState.SLIDE)) {
        _actor.slide_active = false;
        actor_collision_set_actor_height_keep_feet(_actor, _actor.slide_previous_collision_height);
        actor_collision_refresh_contacts(_actor);
        return false;
    }

    if (abs(_speed) > ACTOR_EPSILON) {
        _actor.facing = (_speed < 0) ? ActorFacing.LEFT : ActorFacing.RIGHT;
    }

    var _event = actor_controller_record_event(_actor, ActorControllerEvent.SLIDE_START);
    if (is_struct(_event)) {
        _event.entry_speed = _actor.slide_entry_speed;
        _event.collision_height = _actor.collision_height;
        _event.standing_height = actor_collision_get_actor_standing_height(_actor);
    }

    return true;
}

/// @function actor_controller_update_slide
/// @description Applies slide friction and handles slide exit requests while respecting stand-up clearance.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when slide remains active after the update.
function actor_controller_update_slide(_actor) {
    if (!is_struct(_actor) || !_actor.slide_active) {
        return false;
    }

    _actor.slide_timer += 1;

    var _slide_held = is_struct(_actor.input) && _actor.input.slide_held;
    var _speed = abs(actor_controller_get_slide_horizontal_speed(_actor));
    var _exit_speed = actor_controller_get_slide_stat(
        _actor,
        "slide_exit_speed",
        ACTOR_SLIDE_EXIT_SPEED_DEFAULT
    );
    var _jump_attempt = (_actor.jump_buffer_timer > 0)
        && actor_stats_get_optional(_actor.stats, "slide_jump_allowed", ACTOR_SLIDE_JUMP_ALLOWED_DEFAULT);
    var _wants_exit = !_slide_held
        || (_speed <= _exit_speed + ACTOR_EPSILON)
        || !_actor.is_physically_grounded
        || _jump_attempt;

    if (_wants_exit) {
        if (actor_controller_end_slide(_actor)) {
            return false;
        }

        _actor.slide_stand_blocked = true;
    } else {
        _actor.slide_stand_blocked = false;
    }

    var _surface_friction = _actor.is_physically_grounded
        ? actor_controller_get_surface_multiplier(_actor, "friction_multiplier")
        : 1;
    var _slide_friction = actor_controller_get_slide_stat(
        _actor,
        "slide_friction",
        ACTOR_SLIDE_FRICTION_DEFAULT
    ) * _surface_friction;

    _actor.hsp = actor_controller_approach(_actor.hsp, 0, _slide_friction);
    if (abs(_actor.hsp) <= ACTOR_EPSILON) {
        _actor.hsp = 0;
    }

    actor_controller_update_total_velocity(_actor);

    return _actor.slide_active;
}

/// @function actor_controller_end_slide
/// @description Restores standing collision height when clear and exits slide state.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when slide is inactive after the call.
function actor_controller_end_slide(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    var _was_sliding = _actor.slide_active || actor_controller_is_state(_actor, ActorMoveState.SLIDE);
    if (!_was_sliding) {
        return true;
    }

    if (!actor_controller_can_stand_from_slide(_actor)) {
        _actor.slide_stand_blocked = true;
        return false;
    }

    var _duration = _actor.slide_timer;
    var _entry_speed = _actor.slide_entry_speed;
    var _exit_speed = abs(actor_controller_get_slide_horizontal_speed(_actor));
    var _was_stand_blocked = _actor.slide_stand_blocked;

    actor_collision_set_actor_height_keep_feet(_actor, actor_collision_get_actor_standing_height(_actor));

    _actor.slide_active = false;
    _actor.slide_timer = 0;
    _actor.slide_previous_collision_height = _actor.collision_height;
    _actor.slide_stand_blocked = false;
    _actor.slide_entry_speed = 0;

    actor_collision_refresh_contacts(_actor);

    if (_actor.is_physically_grounded) {
        actor_controller_set_state(_actor, ActorMoveState.GROUNDED);
    } else {
        actor_controller_set_state(_actor, ActorMoveState.AIRBORNE);
    }

    var _event = actor_controller_record_event(_actor, ActorControllerEvent.SLIDE_END);
    if (is_struct(_event)) {
        _event.duration = _duration;
        _event.entry_speed = _entry_speed;
        _event.exit_speed = _exit_speed;
        _event.was_stand_blocked = _was_stand_blocked;
        _event.collision_height = _actor.collision_height;
    }

    return true;
}
