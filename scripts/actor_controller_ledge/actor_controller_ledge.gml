/// @description Ledge grab, ledge hold, and deterministic mantle helpers.

/// @function actor_controller_create_empty_ledge_candidate
/// @description Creates inactive ledge probe data.
/// @returns {Struct} Empty ledge candidate data.
function actor_controller_create_empty_ledge_candidate() {
    return {
        active: false,
        object_id: noone,
        ledge_x: 0,
        ledge_y: 0,
        normal_x: 0,
        normal_y: 0,
        hang_x: 0,
        hang_y: 0,
        stand_x: 0,
        stand_y: 0,
        wall_edge_x: 0,
        surface: new ActorSurfaceInfo()
    };
}

/// @function actor_controller_get_ledge_stat
/// @description Reads a non-negative ledge tuning value from actor stats.
/// @param {Struct} _actor Actor controller containing stats.
/// @param {String} _field_name Stats field name to read.
/// @param {Real} _default_value Default value when stats omit the field.
/// @returns {Real} Non-negative stat value.
function actor_controller_get_ledge_stat(_actor, _field_name, _default_value) {
    if (!is_struct(_actor)) {
        return max(0, _default_value);
    }

    return max(0, actor_stats_get_optional(_actor.stats, _field_name, _default_value));
}

/// @function actor_controller_has_ledge_ability
/// @description Reports whether an actor's stats allow ledge grab.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when ledge grab ability is enabled.
function actor_controller_has_ledge_ability(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    var _abilities = actor_stats_get_optional(_actor.stats, "abilities", ACTOR_ABILITY_NONE);

    return (_abilities & ACTOR_ABILITY_LEDGE_GRAB) != 0;
}

/// @function actor_controller_is_ledge_input_into_wall
/// @description Reports whether current horizontal input is intentionally pushing into a ledge wall.
/// @param {Struct} _actor Actor controller containing input and stats.
/// @param {Real} _normal_x Horizontal wall normal pointing away from the ledge wall.
/// @returns {Bool} True when input is pressing into the ledge wall.
function actor_controller_is_ledge_input_into_wall(_actor, _normal_x) {
    if (!is_struct(_actor) || !is_struct(_actor.input) || (abs(_normal_x) <= ACTOR_EPSILON)) {
        return false;
    }

    var _threshold = actor_controller_get_ledge_stat(_actor, "ledge_input_threshold", ACTOR_LEDGE_INPUT_THRESHOLD_DEFAULT);

    return (_actor.input.move_x * _normal_x) <= -_threshold;
}

/// @function actor_controller_is_ledge_release_input
/// @description Reports whether current input should drop or cancel a ledge hold.
/// @param {Struct} _actor Actor controller containing input and ledge normal.
/// @returns {Bool} True when the ledge hold should release.
function actor_controller_is_ledge_release_input(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.input)) {
        return false;
    }

    var _threshold = actor_controller_get_ledge_stat(_actor, "ledge_input_threshold", ACTOR_LEDGE_INPUT_THRESHOLD_DEFAULT);
    var _input = _actor.input;

    if (_input.cancel_pressed || _input.cancel_held || _input.drop_pressed || _input.drop_held) {
        return true;
    }

    if (_input.move_y >= _threshold) {
        return true;
    }

    return (_input.move_x * _actor.ledge_normal_x) >= _threshold;
}

/// @function actor_controller_is_ledge_mantle_input
/// @description Reports whether current input should start a mantle from ledge hold.
/// @param {Struct} _actor Actor controller containing input.
/// @returns {Bool} True when the actor requested mantle.
function actor_controller_is_ledge_mantle_input(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.input)) {
        return false;
    }

    var _threshold = actor_controller_get_ledge_stat(_actor, "ledge_input_threshold", ACTOR_LEDGE_INPUT_THRESHOLD_DEFAULT);

    return _actor.input.jump_pressed || (_actor.input.move_y <= -_threshold);
}

/// @function actor_controller_make_ledge_candidate_from_object
/// @description Builds and validates a ledge candidate from a contacted wall object and normal.
/// @param {Struct} _actor Actor controller to test.
/// @param {Id.Instance} _object Terrain object providing the ledge.
/// @param {Real} _normal_x Horizontal wall normal pointing away from the ledge wall.
/// @returns {Struct} Valid ledge candidate, inactive when geometry is not reachable.
function actor_controller_make_ledge_candidate_from_object(_actor, _object, _normal_x) {
    var _candidate = actor_controller_create_empty_ledge_candidate();

    if (!is_struct(_actor) || !instance_exists(_object) || (abs(_normal_x) <= ACTOR_EPSILON)) {
        return _candidate;
    }

    if ((_object.object_index != obj_solid) && (_object.object_index != obj_moving_platform)) {
        return _candidate;
    }

    if (actor_collision_is_rotated_slope(_object)) {
        return _candidate;
    }

    var _surface = actor_surface_get_info(_object);
    if (!actor_surface_is_walkable(_surface)) {
        return _candidate;
    }

    var _solid_rect = actor_collision_get_instance_rect(_object);
    var _actor_rect = actor_collision_get_actor_rect(_actor, _actor.x, _actor.y);
    var _half_width = _actor.stats.bbox_width * 0.5;
    var _half_height = _actor.stats.bbox_height * 0.5;
    var _reach_up = actor_controller_get_ledge_stat(_actor, "ledge_reach_up", ACTOR_LEDGE_REACH_UP_DEFAULT);
    var _reach_down = actor_controller_get_ledge_stat(_actor, "ledge_reach_down", ACTOR_LEDGE_REACH_DOWN_DEFAULT);
    var _ledge_y = _solid_rect.top;

    if ((_ledge_y < _actor_rect.top - _reach_up) || (_ledge_y > _actor_rect.top + _reach_down)) {
        return _candidate;
    }

    var _wall_direction = -sign(_normal_x);
    var _wall_edge_x = (_wall_direction > 0) ? _solid_rect.left : _solid_rect.right;
    var _stand_inset = actor_controller_get_ledge_stat(_actor, "ledge_stand_inset", ACTOR_LEDGE_STAND_INSET_DEFAULT);
    var _hang_top_offset = actor_controller_get_ledge_stat(_actor, "ledge_hang_top_offset", ACTOR_LEDGE_HANG_TOP_OFFSET_DEFAULT);
    var _hang_x = _wall_edge_x - (_wall_direction * _half_width);
    var _hang_y = _ledge_y + _hang_top_offset + _half_height;
    var _stand_x = _wall_edge_x + (_wall_direction * (_half_width + _stand_inset));
    var _stand_y = _ledge_y - _half_height;

    if ((_stand_x < _solid_rect.left + ACTOR_EPSILON) || (_stand_x > _solid_rect.right - ACTOR_EPSILON)) {
        return _candidate;
    }

    if (actor_collision_place_solid(_actor, _hang_x, _hang_y)) {
        return _candidate;
    }

    if (!actor_collision_place_solid(_actor, _hang_x + (_wall_direction * ACTOR_CONTACT_PROBE_DISTANCE), _hang_y)) {
        return _candidate;
    }

    if (!actor_collision_can_stand_at(_actor, _stand_x, _stand_y)) {
        return _candidate;
    }

    _candidate.active = true;
    _candidate.object_id = _object;
    _candidate.ledge_x = _wall_edge_x;
    _candidate.ledge_y = _ledge_y;
    _candidate.normal_x = sign(_normal_x);
    _candidate.normal_y = 0;
    _candidate.hang_x = _hang_x;
    _candidate.hang_y = _hang_y;
    _candidate.stand_x = _stand_x;
    _candidate.stand_y = _stand_y;
    _candidate.wall_edge_x = _wall_edge_x;
    _candidate.surface = _surface;

    return _candidate;
}

/// @function actor_controller_find_ledge
/// @description Finds a reachable ledge from the actor's preferred current wall contact.
/// @param {Struct} _actor Actor controller to probe.
/// @returns {Struct} Valid ledge candidate, inactive when none is available.
function actor_controller_find_ledge(_actor) {
    if (!is_struct(_actor)) {
        return actor_controller_create_empty_ledge_candidate();
    }

    var _contact = actor_controller_get_preferred_wall_contact(_actor);
    if (!_contact.active) {
        return actor_controller_create_empty_ledge_candidate();
    }

    return actor_controller_make_ledge_candidate_from_object(_actor, _contact.object_id, _contact.normal_x);
}

/// @function actor_controller_store_ledge_candidate
/// @description Stores current ledge probe data and refreshes ledge coyote memory for debug and grace windows.
/// @param {Struct} _actor Actor controller receiving candidate data.
/// @param {Struct} _candidate Ledge candidate returned by a probe.
/// @returns {Struct} Stored candidate data.
function actor_controller_store_ledge_candidate(_actor, _candidate) {
    if (!is_struct(_actor)) {
        return actor_controller_create_empty_ledge_candidate();
    }

    if (!is_struct(_candidate)) {
        _candidate = actor_controller_create_empty_ledge_candidate();
    }

    _actor.ledge_candidate = _candidate;

    if (_candidate.active) {
        _actor.ledge_coyote_candidate = _candidate;
        _actor.ledge_coyote_timer = actor_controller_get_timer_stat(_actor, "ledge_coyote_frames", ACTOR_LEDGE_COYOTE_FRAMES_DEFAULT);
    }

    return _candidate;
}

/// @function actor_controller_can_ledge_grab
/// @description Reports whether the actor may enter ledge grab using the stored candidate.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when ledge grab is currently allowed.
function actor_controller_can_ledge_grab(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.stats)) {
        return false;
    }

    if (!actor_controller_has_ledge_ability(_actor)) {
        return false;
    }

    if (variable_struct_exists(_actor, "slide_active") && _actor.slide_active) {
        return false;
    }

    if (_actor.is_physically_grounded || (_actor.ledge_grab_lockout_timer > 0)) {
        return false;
    }

    switch (_actor.state) {
        case ActorMoveState.DEAD:
        case ActorMoveState.LOCKED:
        case ActorMoveState.STUNNED:
        case ActorMoveState.KNOCKBACK:
        case ActorMoveState.MANTLE:
        case ActorMoveState.LEDGE_GRAB:
        case ActorMoveState.SLIDE:
            return false;
    }

    if (!is_struct(_actor.input) || _actor.input.cancel_held || _actor.input.cancel_pressed || _actor.input.drop_held || _actor.input.drop_pressed) {
        return false;
    }

    if (_actor.input.move_y > actor_controller_get_ledge_stat(_actor, "ledge_input_threshold", ACTOR_LEDGE_INPUT_THRESHOLD_DEFAULT)) {
        return false;
    }

    if (_actor.spray_active || actor_controller_is_charged_shot_releasing(_actor)) {
        return false;
    }

    if (!is_struct(_actor.ledge_candidate) || !_actor.ledge_candidate.active) {
        return false;
    }

    if (!actor_controller_is_ledge_input_into_wall(_actor, _actor.ledge_candidate.normal_x)) {
        return false;
    }

    var _vertical_speed = _actor.vsp + _actor.external_vsp;
    if (variable_struct_exists(_actor, "ledge_grab_check_vsp")) {
        _vertical_speed = _actor.ledge_grab_check_vsp;
    }

    if (_vertical_speed < -ACTOR_CONTACT_PROBE_DISTANCE) {
        return false;
    }

    var _max_grab_speed = actor_controller_get_ledge_stat(_actor, "ledge_grab_max_speed", ACTOR_LEDGE_GRAB_MAX_SPEED_DEFAULT);
    var _speed = point_distance(0, 0, _actor.total_hsp, _actor.total_vsp);
    if (variable_struct_exists(_actor, "ledge_grab_check_speed")) {
        _speed = _actor.ledge_grab_check_speed;
    }

    return _speed <= _max_grab_speed + ACTOR_EPSILON;
}

/// @function actor_controller_try_ledge_grab
/// @description Attempts to enter ledge grab from the current wall/ledge geometry.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when ledge grab started.
function actor_controller_try_ledge_grab(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    actor_controller_update_total_velocity(_actor);
    actor_controller_store_ledge_candidate(_actor, actor_controller_find_ledge(_actor));

    if (!actor_controller_can_ledge_grab(_actor)) {
        return false;
    }

    var _candidate = _actor.ledge_candidate;
    _actor.ledge_x = _candidate.ledge_x;
    _actor.ledge_y = _candidate.ledge_y;
    _actor.ledge_normal_x = _candidate.normal_x;
    _actor.ledge_normal_y = _candidate.normal_y;
    _actor.ledge_object = _candidate.object_id;
    _actor.ledge_hang_x = _candidate.hang_x;
    _actor.ledge_hang_y = _candidate.hang_y;
    _actor.ledge_stand_x = _candidate.stand_x;
    _actor.ledge_stand_y = _candidate.stand_y;

    _actor.x = _candidate.hang_x;
    _actor.y = _candidate.hang_y;
    _actor.hsp = 0;
    _actor.vsp = 0;
    _actor.is_grounded = false;
    _actor.is_physically_grounded = false;
    _actor.ground_object = noone;
    _actor.platform_object = noone;
    _actor.platform_inherit_object = noone;
    _actor.platform_inherit_velocity_x = 0;
    _actor.platform_inherit_velocity_y = 0;
    _actor.contact_bottom = actor_collision_reset_contact(_actor.contact_bottom);
    actor_controller_stop_spray(_actor);
    actor_controller_clear_continuous_spray_lift(_actor);
    actor_controller_clear_forces(_actor);
    actor_collision_refresh_contacts(_actor);

    if (!actor_controller_set_state(_actor, ActorMoveState.LEDGE_GRAB)) {
        return false;
    }

    var _event = actor_controller_record_event(_actor, ActorControllerEvent.LEDGE_GRAB);
    if (is_struct(_event)) {
        _event.ledge_object = _candidate.object_id;
        _event.ledge_x = _candidate.ledge_x;
        _event.ledge_y = _candidate.ledge_y;
        _event.normal_x = _candidate.normal_x;
        _event.normal_y = _candidate.normal_y;
        _event.hang_x = _candidate.hang_x;
        _event.hang_y = _candidate.hang_y;
        _event.stand_x = _candidate.stand_x;
        _event.stand_y = _candidate.stand_y;
    }

    return true;
}

/// @function actor_controller_clear_ledge_hold
/// @description Clears active ledge and mantle placement fields while leaving coyote memory intact.
/// @param {Struct} _actor Actor controller to clear.
/// @returns {Undefined} No return value.
function actor_controller_clear_ledge_hold(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    _actor.ledge_candidate = actor_controller_create_empty_ledge_candidate();
    _actor.ledge_x = 0;
    _actor.ledge_y = 0;
    _actor.ledge_normal_x = 0;
    _actor.ledge_normal_y = 0;
    _actor.ledge_object = noone;
    _actor.ledge_hang_x = 0;
    _actor.ledge_hang_y = 0;
    _actor.ledge_stand_x = 0;
    _actor.ledge_stand_y = 0;
    _actor.mantle_start_x = 0;
    _actor.mantle_start_y = 0;
    _actor.mantle_end_x = 0;
    _actor.mantle_end_y = 0;
    _actor.mantle_timer = 0;
}

/// @function actor_controller_release_ledge
/// @description Releases ledge or mantle state into airborne movement and starts ledge regrab lockout.
/// @param {Struct} _actor Actor controller to release.
/// @returns {Bool} True when the actor was released.
function actor_controller_release_ledge(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    _actor.hsp = 0;
    _actor.vsp = 0;
    _actor.is_grounded = false;
    _actor.is_physically_grounded = false;
    _actor.ground_object = noone;
    _actor.platform_object = noone;
    _actor.platform_inherit_object = noone;
    _actor.platform_inherit_velocity_x = 0;
    _actor.platform_inherit_velocity_y = 0;
    _actor.contact_bottom = actor_collision_reset_contact(_actor.contact_bottom);
    _actor.ledge_grab_lockout_timer = actor_controller_get_timer_stat(
        _actor,
        "ledge_regrab_lockout_frames",
        ACTOR_LEDGE_REGRAB_LOCKOUT_FRAMES_DEFAULT
    );
    actor_controller_clear_forces(_actor);
    actor_controller_clear_ledge_hold(_actor);
    actor_controller_set_state(_actor, ActorMoveState.AIRBORNE);
    actor_collision_refresh_contacts(_actor);

    return true;
}

/// @function actor_controller_refresh_held_ledge_candidate
/// @description Revalidates the held ledge against its current terrain object.
/// @param {Struct} _actor Actor controller holding a ledge.
/// @returns {Struct} Refreshed ledge candidate, inactive when the held ledge is gone or blocked.
function actor_controller_refresh_held_ledge_candidate(_actor) {
    if (!is_struct(_actor) || !instance_exists(_actor.ledge_object)) {
        return actor_controller_create_empty_ledge_candidate();
    }

    var _candidate = actor_controller_make_ledge_candidate_from_object(_actor, _actor.ledge_object, _actor.ledge_normal_x);
    actor_controller_store_ledge_candidate(_actor, _candidate);

    return _candidate;
}

/// @function actor_controller_update_ledge_grab
/// @description Updates ledge hold input, validates the held ledge, and starts mantle or release.
/// @param {Struct} _actor Actor controller in ledge grab state.
/// @returns {Bool} True when ledge grab state was handled.
function actor_controller_update_ledge_grab(_actor) {
    if (!actor_controller_is_state(_actor, ActorMoveState.LEDGE_GRAB)) {
        return false;
    }

    var _candidate = actor_controller_refresh_held_ledge_candidate(_actor);
    if (!_candidate.active) {
        actor_controller_release_ledge(_actor);
        return true;
    }

    _actor.ledge_x = _candidate.ledge_x;
    _actor.ledge_y = _candidate.ledge_y;
    _actor.ledge_normal_x = _candidate.normal_x;
    _actor.ledge_normal_y = _candidate.normal_y;
    _actor.ledge_object = _candidate.object_id;
    _actor.ledge_hang_x = _candidate.hang_x;
    _actor.ledge_hang_y = _candidate.hang_y;
    _actor.ledge_stand_x = _candidate.stand_x;
    _actor.ledge_stand_y = _candidate.stand_y;
    _actor.x = _candidate.hang_x;
    _actor.y = _candidate.hang_y;
    _actor.hsp = 0;
    _actor.vsp = 0;
    actor_controller_clear_forces(_actor);
    actor_collision_refresh_contacts(_actor);

    if (actor_controller_is_ledge_release_input(_actor)) {
        actor_controller_release_ledge(_actor);
        return true;
    }

    if (actor_controller_is_ledge_mantle_input(_actor)) {
        actor_controller_start_mantle(_actor);
        return true;
    }

    return true;
}

/// @function actor_controller_start_mantle
/// @description Starts a short deterministic mantle from the held ledge to the validated stand position.
/// @param {Struct} _actor Actor controller in ledge grab state.
/// @returns {Bool} True when mantle started.
function actor_controller_start_mantle(_actor) {
    if (!actor_controller_is_state(_actor, ActorMoveState.LEDGE_GRAB)) {
        return false;
    }

    var _candidate = actor_controller_refresh_held_ledge_candidate(_actor);
    if (!_candidate.active || !actor_collision_can_stand_at(_actor, _candidate.stand_x, _candidate.stand_y)) {
        return false;
    }

    _actor.mantle_start_x = _candidate.hang_x;
    _actor.mantle_start_y = _candidate.hang_y;
    _actor.mantle_end_x = _candidate.stand_x;
    _actor.mantle_end_y = _candidate.stand_y;
    _actor.mantle_timer = 0;
    _actor.mantle_duration = max(1, floor(actor_stats_get_optional(
        _actor.stats,
        "ledge_mantle_frames",
        ACTOR_LEDGE_MANTLE_FRAMES_DEFAULT
    )));
    _actor.x = _actor.mantle_start_x;
    _actor.y = _actor.mantle_start_y;
    _actor.hsp = 0;
    _actor.vsp = 0;
    _actor.jump_buffer_timer = 0;
    actor_controller_clear_forces(_actor);

    if (!actor_controller_set_state(_actor, ActorMoveState.MANTLE)) {
        return false;
    }

    var _event = actor_controller_record_event(_actor, ActorControllerEvent.MANTLE);
    if (is_struct(_event)) {
        _event.ledge_object = _candidate.object_id;
        _event.start_x = _actor.mantle_start_x;
        _event.start_y = _actor.mantle_start_y;
        _event.end_x = _actor.mantle_end_x;
        _event.end_y = _actor.mantle_end_y;
        _event.duration = _actor.mantle_duration;
    }

    return true;
}

/// @function actor_controller_update_mantle
/// @description Moves the actor through the two-phase mantle path and finishes at the stand position.
/// @param {Struct} _actor Actor controller in mantle state.
/// @returns {Bool} True when mantle state was handled.
function actor_controller_update_mantle(_actor) {
    if (!actor_controller_is_state(_actor, ActorMoveState.MANTLE)) {
        return false;
    }

    _actor.jump_buffer_timer = 0;

    if (actor_controller_is_ledge_release_input(_actor)) {
        actor_controller_release_ledge(_actor);
        return true;
    }

    if (!actor_collision_can_stand_at(_actor, _actor.mantle_end_x, _actor.mantle_end_y)) {
        actor_controller_release_ledge(_actor);
        return true;
    }

    _actor.hsp = 0;
    _actor.vsp = 0;
    actor_controller_clear_forces(_actor);

    _actor.collision_blocked_x = false;
    _actor.collision_blocked_y = false;
    _actor.collision_last_move_x = 0;
    _actor.collision_last_move_y = 0;
    _actor.collision_iterations = 0;

    var _duration = max(1, floor(_actor.mantle_duration));
    var _vertical_frames = max(1, floor(_duration * 0.5));
    var _horizontal_frames = max(1, _duration - _vertical_frames);
    var _next_timer = min(_duration, _actor.mantle_timer + 1);
    var _blocked = false;

    if (_actor.mantle_timer < _vertical_frames) {
        var _vertical_t = clamp(_next_timer / _vertical_frames, 0, 1);
        var _target_y = lerp(_actor.mantle_start_y, _actor.mantle_end_y, _vertical_t);
        var _y_result = actor_collision_move_y(_actor, _target_y - _actor.y);
        _blocked = _y_result.blocked_y;
    } else {
        var _settle_y_result = actor_collision_move_y(_actor, _actor.mantle_end_y - _actor.y);
        var _horizontal_t = clamp((_next_timer - _vertical_frames) / _horizontal_frames, 0, 1);
        var _target_x = lerp(_actor.mantle_start_x, _actor.mantle_end_x, _horizontal_t);
        var _x_result = actor_collision_move_x(_actor, _target_x - _actor.x);
        _blocked = _settle_y_result.blocked_y || _x_result.blocked_x;
    }

    actor_collision_refresh_contacts(_actor);

    if (_blocked) {
        actor_controller_release_ledge(_actor);
        return true;
    }

    _actor.mantle_timer = _next_timer;

    if (_actor.mantle_timer >= _duration) {
        actor_controller_finish_mantle(_actor);
    }

    return true;
}

/// @function actor_controller_finish_mantle
/// @description Places the actor at the final stand position and returns to grounded or airborne state.
/// @param {Struct} _actor Actor controller finishing mantle.
/// @returns {Bool} True when mantle finished.
function actor_controller_finish_mantle(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    if (!actor_collision_can_stand_at(_actor, _actor.mantle_end_x, _actor.mantle_end_y)) {
        actor_controller_release_ledge(_actor);
        return false;
    }

    _actor.x = _actor.mantle_end_x;
    _actor.y = _actor.mantle_end_y;
    _actor.hsp = 0;
    _actor.vsp = 0;
    actor_controller_clear_forces(_actor);
    actor_collision_refresh_contacts(_actor);
    actor_controller_clear_ledge_hold(_actor);

    if (_actor.is_physically_grounded) {
        actor_controller_set_state(_actor, ActorMoveState.GROUNDED);
    } else {
        actor_controller_set_state(_actor, ActorMoveState.AIRBORNE);
    }

    return true;
}

/// @function actor_controller_update_ledge_state
/// @description Handles active ledge grab or mantle states before normal movement simulation.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when a ledge-owned state consumed the frame.
function actor_controller_update_ledge_state(_actor) {
    if (actor_controller_is_state(_actor, ActorMoveState.MANTLE)) {
        return actor_controller_update_mantle(_actor);
    }

    if (actor_controller_is_state(_actor, ActorMoveState.LEDGE_GRAB)) {
        return actor_controller_update_ledge_grab(_actor);
    }

    return false;
}
