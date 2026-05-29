/// @description Wall contact, wall slide, wall coyote, and wall jump helpers.

/// @function actor_controller_get_preferred_wall_contact
/// @description Chooses the current wall contact that should drive wall slide and wall jump behavior.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Struct} Preferred wall contact, inactive when no wall is touched.
function actor_controller_get_preferred_wall_contact(_actor) {
    if (!is_struct(_actor)) {
        return new ActorContactInfo();
    }

    var _left_active = is_struct(_actor.contact_left) && _actor.contact_left.active;
    var _right_active = is_struct(_actor.contact_right) && _actor.contact_right.active;

    if (_left_active && !_right_active) {
        return _actor.contact_left;
    }

    if (_right_active && !_left_active) {
        return _actor.contact_right;
    }

    if (!_left_active && !_right_active) {
        return new ActorContactInfo();
    }

    var _input_x = is_struct(_actor.input) ? _actor.input.move_x : 0;
    if (_input_x < -ACTOR_EPSILON) {
        return _actor.contact_left;
    }

    if (_input_x > ACTOR_EPSILON) {
        return _actor.contact_right;
    }

    return (_actor.facing == ActorFacing.LEFT) ? _actor.contact_left : _actor.contact_right;
}

/// @function actor_controller_update_wall_contact
/// @description Refreshes side wall contact fields and stores wall coyote contact memory.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_update_wall_contact(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    _actor.contact_left = actor_collision_get_wall_info(_actor, -1);
    _actor.contact_right = actor_collision_get_wall_info(_actor, 1);
    _actor.wall_left = _actor.contact_left.active;
    _actor.wall_right = _actor.contact_right.active;

    var _contact = actor_controller_get_preferred_wall_contact(_actor);
    if (_contact.active) {
        _actor.wall_normal_x = _contact.normal_x;
        _actor.wall_normal_y = _contact.normal_y;
        _actor.wall_object = _contact.object_id;

        if (!_actor.is_physically_grounded) {
            _actor.wall_coyote_normal_x = _contact.normal_x;
            _actor.wall_coyote_normal_y = _contact.normal_y;
            _actor.wall_coyote_object = _contact.object_id;
        }
        return;
    }

    _actor.wall_normal_x = 0;
    _actor.wall_normal_y = 0;
    _actor.wall_object = noone;
}

/// @function actor_controller_get_wall_slide_speed
/// @description Reads and caches the actor's wall slide fall speed cap.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Real} Non-negative wall slide speed.
function actor_controller_get_wall_slide_speed(_actor) {
    if (!is_struct(_actor)) {
        return max(0, ACTOR_WALL_SLIDE_SPEED_DEFAULT);
    }

    var _speed = actor_stats_get_optional(_actor.stats, "wall_slide_speed", ACTOR_WALL_SLIDE_SPEED_DEFAULT);
    _actor.wall_slide_speed = max(0, _speed);

    return _actor.wall_slide_speed;
}

/// @function actor_controller_is_pressing_into_wall
/// @description Reports whether current horizontal input is pushing into a wall normal.
/// @param {Struct} _actor Actor controller containing input and stats.
/// @param {Real} _wall_normal_x Horizontal wall normal direction.
/// @returns {Bool} True when input is pressing into the wall.
function actor_controller_is_pressing_into_wall(_actor, _wall_normal_x) {
    if (!is_struct(_actor) || !is_struct(_actor.input) || (abs(_wall_normal_x) <= ACTOR_EPSILON)) {
        return false;
    }

    var _threshold = max(0, actor_stats_get_optional(
        _actor.stats,
        "wall_slide_input_threshold",
        ACTOR_WALL_SLIDE_INPUT_THRESHOLD_DEFAULT
    ));

    return (_actor.input.move_x * _wall_normal_x) <= -_threshold;
}

/// @function actor_controller_can_wall_slide
/// @description Reports whether the actor is eligible to enter or remain in wall slide.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when wall slide is currently allowed.
function actor_controller_can_wall_slide(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.stats)) {
        return false;
    }

    if ((_actor.stats.abilities & ACTOR_ABILITY_WALL_SLIDE) == 0) {
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

    if (_actor.is_physically_grounded || (_actor.wall_jump_lockout_timer > 0)) {
        return false;
    }

    if ((_actor.vsp + _actor.external_vsp) < 0) {
        return false;
    }

    var _contact = actor_controller_get_preferred_wall_contact(_actor);
    if (!_contact.active || !actor_surface_is_walkable(_contact.surface)) {
        return false;
    }

    var _requires_input = actor_stats_get_optional(
        _actor.stats,
        "wall_slide_requires_input",
        ACTOR_WALL_SLIDE_REQUIRES_INPUT_DEFAULT
    );

    return !_requires_input || actor_controller_is_pressing_into_wall(_actor, _contact.normal_x);
}

/// @function actor_controller_try_enter_wall_slide
/// @description Enters wall slide when eligible and records the one-frame start event.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when the actor is in wall slide after this call.
function actor_controller_try_enter_wall_slide(_actor) {
    if (!actor_controller_can_wall_slide(_actor)) {
        return false;
    }

    var _was_wall_slide = actor_controller_is_state(_actor, ActorMoveState.WALL_SLIDE);
    var _entered = actor_controller_set_state(_actor, ActorMoveState.WALL_SLIDE);

    if (_entered && !_was_wall_slide) {
        actor_controller_record_event(_actor, ActorControllerEvent.WALL_SLIDE_START);
    }

    return _entered;
}

/// @function actor_controller_apply_wall_slide_cap
/// @description Caps controlled downward speed while an actor is actively wall sliding.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_apply_wall_slide_cap(_actor) {
    if (!actor_controller_is_state(_actor, ActorMoveState.WALL_SLIDE)) {
        return;
    }

    if (!actor_controller_can_wall_slide(_actor)) {
        return;
    }

    _actor.vsp = min(_actor.vsp, actor_controller_get_wall_slide_speed(_actor));
}

/// @function actor_controller_get_wall_jump_normal_x
/// @description Gets the horizontal launch normal from current wall contact or wall coyote memory.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Real} Horizontal wall normal, or 0 when unavailable.
function actor_controller_get_wall_jump_normal_x(_actor) {
    if (!is_struct(_actor)) {
        return 0;
    }

    var _contact = actor_controller_get_preferred_wall_contact(_actor);
    if (_contact.active && (abs(_contact.normal_x) > ACTOR_EPSILON)) {
        return _contact.normal_x;
    }

    if ((_actor.wall_coyote_timer > 0) && (abs(_actor.wall_coyote_normal_x) > ACTOR_EPSILON)) {
        return _actor.wall_coyote_normal_x;
    }

    return 0;
}

/// @function actor_controller_can_wall_jump
/// @description Reports whether buffered jump input may execute a wall jump this update.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when wall jump is currently allowed.
function actor_controller_can_wall_jump(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.stats)) {
        return false;
    }

    if ((_actor.stats.abilities & ACTOR_ABILITY_WALL_JUMP) == 0) {
        return false;
    }

    if ((_actor.jump_buffer_timer <= 0) || (_actor.wall_coyote_timer <= 0) || (_actor.wall_jump_lockout_timer > 0)) {
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

    if (_actor.is_physically_grounded) {
        return false;
    }

    return abs(actor_controller_get_wall_jump_normal_x(_actor)) > ACTOR_EPSILON;
}

/// @function actor_controller_try_wall_jump
/// @description Executes a wall jump when buffered input and wall eligibility are available.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when a wall jump executed.
function actor_controller_try_wall_jump(_actor) {
    if (!actor_controller_can_wall_jump(_actor)) {
        return false;
    }

    return actor_controller_execute_wall_jump(_actor);
}

/// @function actor_controller_execute_wall_jump
/// @description Applies wall jump velocity away from the stored wall normal and starts lockout.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when wall jump velocity was applied.
function actor_controller_execute_wall_jump(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    var _normal_x = actor_controller_get_wall_jump_normal_x(_actor);
    if (abs(_normal_x) <= ACTOR_EPSILON) {
        return false;
    }

    actor_controller_consume_jump_buffer(_actor);
    _actor.ground_coyote_timer = 0;
    _actor.wall_coyote_timer = 0;

    var _jump_x = max(0, actor_stats_get_optional(
        _actor.stats,
        "wall_jump_horizontal_speed",
        ACTOR_WALL_JUMP_HORIZONTAL_SPEED_DEFAULT
    ));
    var _jump_y = actor_stats_get_optional(
        _actor.stats,
        "wall_jump_vertical_speed",
        ACTOR_WALL_JUMP_VERTICAL_SPEED_DEFAULT
    );

    _actor.hsp = sign(_normal_x) * _jump_x;
    _actor.vsp = _jump_y;
    _actor.facing = (_normal_x < 0) ? ActorFacing.LEFT : ActorFacing.RIGHT;
    _actor.is_grounded = false;
    _actor.is_physically_grounded = false;
    _actor.ground_object = noone;
    _actor.platform_object = noone;
    _actor.platform_inherit_object = noone;
    _actor.platform_inherit_velocity_x = 0;
    _actor.platform_inherit_velocity_y = 0;
    _actor.contact_bottom = actor_collision_reset_contact(_actor.contact_bottom);
    _actor.wall_jump_lockout_timer = actor_controller_get_timer_stat(
        _actor,
        "wall_jump_lockout_frames",
        ACTOR_WALL_JUMP_LOCKOUT_FRAMES_DEFAULT
    );

    actor_controller_set_state(_actor, ActorMoveState.AIRBORNE);
    actor_controller_update_total_velocity(_actor);
    actor_controller_record_event(_actor, ActorControllerEvent.WALL_JUMP);

    return true;
}
