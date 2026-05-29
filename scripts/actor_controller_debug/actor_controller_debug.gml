/// @description Debug text helpers for the foundation actor controller.

/// @function actor_controller_debug_bool_text
/// @description Converts a boolean-like value to debug text.
/// @param {Bool} _value Value to format.
/// @returns {String} Debug text for the boolean value.
function actor_controller_debug_bool_text(_value) {
    return _value ? "true" : "false";
}

/// @function actor_controller_debug_format_real
/// @description Formats a real value for compact debug text.
/// @param {Real} _value Number to format.
/// @returns {String} Formatted number.
function actor_controller_debug_format_real(_value) {
    return string_format(_value, 1, 2);
}

/// @function actor_controller_debug_instance_text
/// @description Converts an instance id to compact debug text.
/// @param {Id.Instance} _instance_id Instance id to format.
/// @returns {String} Instance id text or none.
function actor_controller_debug_instance_text(_instance_id) {
    return (_instance_id == noone) ? "none" : string(_instance_id);
}

/// @function actor_controller_debug_contact_text
/// @description Converts a contact struct to compact debug text.
/// @param {Struct} _contact Contact info to format.
/// @returns {String} Contact state text.
function actor_controller_debug_contact_text(_contact) {
    if (!is_struct(_contact) || !_contact.active) {
        return "clear";
    }

    return "hit " + actor_controller_debug_instance_text(_contact.object_id)
        + " d:" + actor_controller_debug_format_real(_contact.depth);
}

/// @function actor_controller_debug_ledge_candidate_text
/// @description Converts a ledge candidate struct to compact debug text.
/// @param {Struct} _candidate Ledge candidate data to format.
/// @returns {String} Ledge candidate state text.
function actor_controller_debug_ledge_candidate_text(_candidate) {
    if (!is_struct(_candidate) || !_candidate.active) {
        return "clear";
    }

    return "hit " + actor_controller_debug_instance_text(_candidate.object_id)
        + " ledge: (" + actor_controller_debug_format_real(_candidate.ledge_x)
        + ", " + actor_controller_debug_format_real(_candidate.ledge_y) + ")"
        + " stand: (" + actor_controller_debug_format_real(_candidate.stand_x)
        + ", " + actor_controller_debug_format_real(_candidate.stand_y) + ")";
}

/// @function actor_controller_debug_move_state_name
/// @description Converts an ActorMoveState enum value to readable debug text.
/// @param {Real} _state ActorMoveState enum value.
/// @returns {String} State name for debug output.
function actor_controller_debug_move_state_name(_state) {
    switch (_state) {
        case ActorMoveState.GROUNDED: return "GROUNDED";
        case ActorMoveState.AIRBORNE: return "AIRBORNE";
        case ActorMoveState.WALL_SLIDE: return "WALL_SLIDE";
        case ActorMoveState.WALL_GRAB: return "WALL_GRAB";
        case ActorMoveState.LEDGE_GRAB: return "LEDGE_GRAB";
        case ActorMoveState.MANTLE: return "MANTLE";
        case ActorMoveState.SLIDE: return "SLIDE";
        case ActorMoveState.STUNNED: return "STUNNED";
        case ActorMoveState.KNOCKBACK: return "KNOCKBACK";
        case ActorMoveState.LOCKED: return "LOCKED";
        case ActorMoveState.DEAD: return "DEAD";
    }

    return "UNKNOWN";
}

/// @function actor_controller_debug_spray_mode_name
/// @description Converts an ActorSprayMode enum value to readable debug text.
/// @param {Real} _mode ActorSprayMode enum value.
/// @returns {String} Spray mode name for debug output.
function actor_controller_debug_spray_mode_name(_mode) {
    switch (_mode) {
        case ActorSprayMode.NONE: return "NONE";
        case ActorSprayMode.WIDE: return "WIDE";
        case ActorSprayMode.FOCUSED: return "FOCUSED";
        case ActorSprayMode.CHARGED: return "CHARGED";
    }

    return "UNKNOWN";
}

/// @function actor_controller_debug_force_type_name
/// @description Converts an ActorForceType enum value to readable debug text.
/// @param {Real} _type ActorForceType enum value.
/// @returns {String} Force type name for debug output.
function actor_controller_debug_force_type_name(_type) {
    switch (_type) {
        case ActorForceType.ADDITIVE: return "ADDITIVE";
        case ActorForceType.IMPULSE: return "IMPULSE";
        case ActorForceType.OVERRIDE: return "OVERRIDE";
        case ActorForceType.CONTINUOUS: return "CONTINUOUS";
        case ActorForceType.PLATFORM_CARRY: return "PLATFORM_CARRY";
        case ActorForceType.KNOCKBACK: return "KNOCKBACK";
    }

    return "UNKNOWN";
}

/// @function actor_controller_debug_force_text
/// @description Converts one active force to compact debug text.
/// @param {Struct} _force Force data to format.
/// @param {Real} _index Force index in the active force array.
/// @returns {String} Single-line force debug text.
function actor_controller_debug_force_text(_force, _index) {
    if (!is_struct(_force)) {
        return "force " + string(_index) + ": invalid";
    }

    var _text = "force " + string(_index) + ": " + actor_controller_debug_force_type_name(_force.type);
    _text += " vec: (" + actor_controller_debug_format_real(_force.x);
    _text += ", " + actor_controller_debug_format_real(_force.y) + ")";
    _text += " t: " + string(_force.elapsed_frames) + "/" + string(_force.duration_frames);
    _text += " damp: " + actor_controller_debug_format_real(_force.damping);
    _text += " ctrl: " + actor_controller_debug_format_real(_force.control_reduction);
    _text += " src: " + actor_controller_debug_instance_text(_force.source_id);

    return _text;
}

/// @function actor_controller_debug_print_state
/// @description Draws foundation controller state and current input values.
/// @param {Struct} _actor Actor controller to draw.
/// @param {Real} _draw_x GUI x position.
/// @param {Real} _draw_y GUI y position.
/// @returns {Undefined} No return value.
function actor_controller_debug_print_state(_actor, _draw_x, _draw_y) {
    if (!is_struct(_actor)) {
        return;
    }

    if (!_actor.debug_enabled) {
        return;
    }

    var _input = _actor.input;
    var _has_input = is_struct(_input);
    var _capacity_percent = (_actor.water_max > ACTOR_EPSILON) ? ((_actor.water_current / _actor.water_max) * 100) : 0;
    var _spray_lift_fade_duration = max(
        actor_controller_get_continuous_spray_lift_fade_duration(_actor),
        _actor.spray_vertical_lift_fade_duration
    );
    var _spray_lift_fade_timer = actor_controller_is_continuous_spray_lift_fading(_actor)
        ? min(_spray_lift_fade_duration, _actor.spray_vertical_lift_fade_timer)
        : _actor.spray_vertical_lift_fade_timer;
    var _charge_build_frames = max(1, floor(actor_stats_get_optional(_actor.stats, "charge_build_frames", ACTOR_CHARGE_BUILD_FRAMES_DEFAULT)));
    var _release_duration_stat = max(1, floor(actor_stats_get_optional(_actor.stats, "charged_shot_duration_frames", ACTOR_CHARGED_SHOT_DURATION_FRAMES_DEFAULT)));
    var _release_duration = max(_release_duration_stat, _actor.charged_shot_release_duration);
    var _release_timer = actor_controller_is_charged_shot_releasing(_actor)
        ? min(_release_duration, _actor.charged_shot_release_timer + 1)
        : _actor.charged_shot_release_timer;
    var _text = "";

    _text += "Actor Controller " + string(_actor.version) + "\n";
    _text += "state: " + actor_controller_debug_move_state_name(_actor.state);
    _text += "  prev: " + actor_controller_debug_move_state_name(_actor.state_previous) + "\n";
    _text += "pos: (" + actor_controller_debug_format_real(_actor.x) + ", " + actor_controller_debug_format_real(_actor.y) + ")";
    _text += "  prev: (" + actor_controller_debug_format_real(_actor.x_previous) + ", " + actor_controller_debug_format_real(_actor.y_previous) + ")\n";
    _text += "vel: (" + actor_controller_debug_format_real(_actor.hsp) + ", " + actor_controller_debug_format_real(_actor.vsp) + ")";
    _text += "  external: (" + actor_controller_debug_format_real(_actor.external_hsp) + ", " + actor_controller_debug_format_real(_actor.external_vsp) + ")\n";
    _text += "total vel: (" + actor_controller_debug_format_real(_actor.total_hsp) + ", " + actor_controller_debug_format_real(_actor.total_vsp) + ")";
    _text += "  control reduction: " + actor_controller_debug_format_real(_actor.external_control_reduction) + "\n";
    _text += "grounded: " + actor_controller_debug_bool_text(_actor.is_grounded);
    _text += "  physical: " + actor_controller_debug_bool_text(_actor.is_physically_grounded);
    _text += "  was: " + actor_controller_debug_bool_text(_actor.was_grounded) + "\n";
    _text += "walls L/R: " + actor_controller_debug_bool_text(_actor.wall_left);
    _text += "/" + actor_controller_debug_bool_text(_actor.wall_right);
    _text += "  ceiling: " + actor_controller_debug_bool_text(_actor.ceiling_contact);
    _text += "  ground obj: " + actor_controller_debug_instance_text(_actor.ground_object);
    _text += "  wall obj: " + actor_controller_debug_instance_text(_actor.wall_object) + "\n";
    _text += "ledge obj: " + actor_controller_debug_instance_text(_actor.ledge_object);
    _text += " candidate: " + actor_controller_debug_ledge_candidate_text(_actor.ledge_candidate);
    _text += " coyote: " + actor_controller_debug_ledge_candidate_text(_actor.ledge_coyote_candidate) + "\n";
    _text += "ledge hang: (" + actor_controller_debug_format_real(_actor.ledge_hang_x);
    _text += ", " + actor_controller_debug_format_real(_actor.ledge_hang_y) + ")";
    _text += " stand: (" + actor_controller_debug_format_real(_actor.ledge_stand_x);
    _text += ", " + actor_controller_debug_format_real(_actor.ledge_stand_y) + ")";
    _text += " mantle: " + string(_actor.mantle_timer) + "/" + string(_actor.mantle_duration);
    _text += " state time: " + string(_actor.time_in_state) + "\n";
    _text += "ground angle: " + actor_controller_debug_format_real(_actor.ground_angle);
    _text += " tangent: (" + actor_controller_debug_format_real(_actor.ground_tangent_x);
    _text += ", " + actor_controller_debug_format_real(_actor.ground_tangent_y) + ")";
    _text += " walkable: " + actor_controller_debug_bool_text(_actor.ground_slope_walkable) + "\n";
    _text += "platform obj: " + actor_controller_debug_instance_text(_actor.platform_object);
    _text += " vel: (" + actor_controller_debug_format_real(_actor.platform_velocity_x);
    _text += ", " + actor_controller_debug_format_real(_actor.platform_velocity_y) + ")";
    _text += " carry: (" + actor_controller_debug_format_real(_actor.platform_carry_x);
    _text += ", " + actor_controller_debug_format_real(_actor.platform_carry_y) + ")";
    _text += " one-way ignore: " + actor_controller_debug_instance_text(_actor.one_way_ignore_object) + "\n";
    _text += "contacts L/R/T/B: ";
    _text += actor_controller_debug_contact_text(_actor.contact_left) + " | ";
    _text += actor_controller_debug_contact_text(_actor.contact_right) + " | ";
    _text += actor_controller_debug_contact_text(_actor.contact_top) + " | ";
    _text += actor_controller_debug_contact_text(_actor.contact_bottom) + "\n";
    _text += "collision move: (" + actor_controller_debug_format_real(_actor.collision_last_move_x);
    _text += ", " + actor_controller_debug_format_real(_actor.collision_last_move_y) + ")";
    _text += " blocked: " + actor_controller_debug_bool_text(_actor.collision_blocked_x);
    _text += "/" + actor_controller_debug_bool_text(_actor.collision_blocked_y);
    _text += " iter: " + string(_actor.collision_iterations);
    _text += " unstuck: " + actor_controller_debug_bool_text(_actor.collision_unstuck_succeeded);
    _text += " (" + actor_controller_debug_format_real(_actor.collision_unstuck_offset_x);
    _text += ", " + actor_controller_debug_format_real(_actor.collision_unstuck_offset_y) + ")\n";
    _text += "timers jump/coyote/wall/ledge/drop/wlock/llock: ";
    _text += string(_actor.jump_buffer_timer) + "/";
    _text += string(_actor.ground_coyote_timer) + "/";
    _text += string(_actor.wall_coyote_timer) + "/";
    _text += string(_actor.ledge_coyote_timer) + "/";
    _text += string(_actor.drop_through_timer) + "/";
    _text += string(_actor.wall_jump_lockout_timer) + "/";
    _text += string(_actor.ledge_grab_lockout_timer) + "\n";
    _text += "spray: " + actor_controller_debug_spray_mode_name(_actor.spray_mode);
    _text += " active: " + actor_controller_debug_bool_text(_actor.spray_active);
    _text += " aim: (" + actor_controller_debug_format_real(_actor.spray_aim_x) + ", " + actor_controller_debug_format_real(_actor.spray_aim_y) + ")";
    _text += " recoil: (" + actor_controller_debug_format_real(_actor.spray_recoil_x) + ", " + actor_controller_debug_format_real(_actor.spray_recoil_y) + ")\n";
    _text += "spray lift: current " + actor_controller_debug_format_real(_actor.spray_vertical_lift_current);
    _text += " target " + actor_controller_debug_format_real(_actor.spray_vertical_lift_target);
    _text += " fade: " + actor_controller_debug_bool_text(actor_controller_is_continuous_spray_lift_fading(_actor));
    _text += " t: " + string(_spray_lift_fade_timer) + "/" + string(_spray_lift_fade_duration) + "\n";
    _text += "capacity: " + actor_controller_debug_format_real(_actor.water_current) + "/" + actor_controller_debug_format_real(_actor.water_max);
    _text += " (" + string_format(_capacity_percent, 1, 0) + "%)";
    _text += " unlimited: " + actor_controller_debug_bool_text(actor_controller_has_unlimited_capacity(_actor));
    _text += " grace: " + string(_actor.spray_empty_grace_timer);
    _text += " refill: " + actor_controller_debug_bool_text(_actor.water_refill_active) + "\n";
    _text += "charge build: " + string(_actor.charge_timer) + "/" + string(_charge_build_frames);
    _text += " amount: " + actor_controller_debug_format_real(_actor.charge_amount);
    _text += " ready: " + actor_controller_debug_bool_text(_actor.charge_ready);
    _text += " full: " + actor_controller_debug_bool_text(_actor.charge_overready) + "\n";
    _text += "blast release: active " + actor_controller_debug_bool_text(actor_controller_is_charged_shot_releasing(_actor));
    _text += " t: " + string(_release_timer) + "/" + string(_release_duration);
    _text += " strength: " + actor_controller_debug_format_real(_actor.charged_shot_release_strength);
    _text += "/" + actor_controller_debug_format_real(_actor.charged_shot_release_initial_strength) + "\n";
    _text += "forces active: " + string(_actor.active_force_count) + "\n";

    if (is_array(_actor.active_forces)) {
        for (var _force_index = 0; _force_index < array_length(_actor.active_forces); _force_index++) {
            _text += actor_controller_debug_force_text(_actor.active_forces[_force_index], _force_index) + "\n";
        }
    }

    if (_has_input) {
        _text += "input frame: " + string(_input.frame_number);
        _text += " move: (" + actor_controller_debug_format_real(_input.move_x) + ", " + actor_controller_debug_format_real(_input.move_y) + ")";
        _text += " aim: (" + actor_controller_debug_format_real(_input.aim_x) + ", " + actor_controller_debug_format_real(_input.aim_y) + ")\n";
        _text += "jump p/h/r: ";
        _text += actor_controller_debug_bool_text(_input.jump_pressed) + "/";
        _text += actor_controller_debug_bool_text(_input.jump_held) + "/";
        _text += actor_controller_debug_bool_text(_input.jump_released) + "  ";
        _text += "run p/h/r: ";
        _text += actor_controller_debug_bool_text(_input.run_pressed) + "/";
        _text += actor_controller_debug_bool_text(_input.run_held) + "/";
        _text += actor_controller_debug_bool_text(_input.run_released) + "  ";
        _text += "slide p/h/r: ";
        _text += actor_controller_debug_bool_text(_input.slide_pressed) + "/";
        _text += actor_controller_debug_bool_text(_input.slide_held) + "/";
        _text += actor_controller_debug_bool_text(_input.slide_released) + "\n";
        _text += "spray p/h/r: ";
        _text += actor_controller_debug_bool_text(_input.spray_pressed) + "/";
        _text += actor_controller_debug_bool_text(_input.spray_held) + "/";
        _text += actor_controller_debug_bool_text(_input.spray_released) + "  ";
        _text += "charge p/h/r: ";
        _text += actor_controller_debug_bool_text(_input.charge_pressed) + "/";
        _text += actor_controller_debug_bool_text(_input.charge_held) + "/";
        _text += actor_controller_debug_bool_text(_input.charge_released) + "\n";
        _text += "drop p/h/r: ";
        _text += actor_controller_debug_bool_text(_input.drop_pressed) + "/";
        _text += actor_controller_debug_bool_text(_input.drop_held) + "/";
        _text += actor_controller_debug_bool_text(_input.drop_released) + "  ";
        _text += "cancel p/h/r: ";
        _text += actor_controller_debug_bool_text(_input.cancel_pressed) + "/";
        _text += actor_controller_debug_bool_text(_input.cancel_held) + "/";
        _text += actor_controller_debug_bool_text(_input.cancel_released) + "\n";
        _text += "nozzle prev/next/delta: ";
        _text += actor_controller_debug_bool_text(_input.nozzle_prev_pressed) + "/";
        _text += actor_controller_debug_bool_text(_input.nozzle_next_pressed) + "/";
        _text += string(_input.nozzle_value_delta);
    } else {
        _text += "input: none";
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text(_draw_x, _draw_y, _text);
}

/// @function actor_controller_debug_draw_rect
/// @description Draws a rectangle using a translucent fill and solid outline.
/// @param {Struct} _rect Rectangle with left, top, right, and bottom fields.
/// @param {Real} _color Draw color.
/// @returns {Undefined} No return value.
function actor_controller_debug_draw_rect(_rect, _color) {
    draw_set_alpha(0.18);
    draw_set_color(_color);
    draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, false);
    draw_set_alpha(1);
    draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, true);
}

/// @function actor_controller_debug_draw_collision
/// @description Draws the actor collision mask when collision debug drawing is enabled.
/// @param {Struct} _actor Actor controller to draw.
/// @returns {Undefined} No return value.
function actor_controller_debug_draw_collision(_actor) {
    if (!is_struct(_actor) || !_actor.debug_enabled || !_actor.debug_draw_collision) {
        return;
    }

    var _rect = actor_collision_get_actor_rect(_actor, _actor.x, _actor.y);
    actor_controller_debug_draw_rect(_rect, c_aqua);
}

/// @function actor_controller_debug_draw_probes
/// @description Draws side probe rectangles when probe debug drawing is enabled.
/// @param {Struct} _actor Actor controller to draw.
/// @returns {Undefined} No return value.
function actor_controller_debug_draw_probes(_actor) {
    if (!is_struct(_actor) || !_actor.debug_enabled || !_actor.debug_draw_probes) {
        return;
    }

    var _bottom = actor_collision_get_actor_rect(_actor, _actor.x, _actor.y + ACTOR_CONTACT_PROBE_DISTANCE);
    var _top = actor_collision_get_actor_rect(_actor, _actor.x, _actor.y - ACTOR_CONTACT_PROBE_DISTANCE);
    var _left = actor_collision_get_actor_rect(_actor, _actor.x - ACTOR_CONTACT_PROBE_DISTANCE, _actor.y);
    var _right = actor_collision_get_actor_rect(_actor, _actor.x + ACTOR_CONTACT_PROBE_DISTANCE, _actor.y);

    actor_controller_debug_draw_rect(_bottom, _actor.contact_bottom.active ? c_lime : c_green);
    actor_controller_debug_draw_rect(_top, _actor.contact_top.active ? c_yellow : c_olive);
    actor_controller_debug_draw_rect(_left, _actor.contact_left.active ? c_red : c_maroon);
    actor_controller_debug_draw_rect(_right, _actor.contact_right.active ? c_red : c_maroon);

    if (is_struct(_actor.ledge_candidate) && _actor.ledge_candidate.active) {
        var _ledge_hang = actor_collision_get_actor_rect(_actor, _actor.ledge_candidate.hang_x, _actor.ledge_candidate.hang_y);
        var _ledge_stand = actor_collision_get_actor_rect(_actor, _actor.ledge_candidate.stand_x, _actor.ledge_candidate.stand_y);

        actor_controller_debug_draw_rect(_ledge_hang, c_fuchsia);
        actor_controller_debug_draw_rect(_ledge_stand, c_yellow);
        draw_set_alpha(1);
        draw_set_color(c_fuchsia);
        draw_line(
            _actor.ledge_candidate.ledge_x,
            _actor.ledge_candidate.ledge_y,
            _actor.ledge_candidate.stand_x,
            _actor.ledge_candidate.stand_y
        );
    }

    if (_actor.debug_draw_vectors && _actor.contact_bottom.active) {
        draw_set_alpha(1);
        draw_set_color(c_lime);
        draw_line(_actor.x, _actor.y, _actor.x + _actor.ground_normal_x * 24, _actor.y + _actor.ground_normal_y * 24);
        draw_set_color(c_yellow);
        draw_line(_actor.x, _actor.y, _actor.x + _actor.ground_tangent_x * 24, _actor.y + _actor.ground_tangent_y * 24);
        draw_set_color(c_orange);
        draw_line(_actor.x, _actor.y, _actor.x + _actor.platform_carry_x * 8, _actor.y + _actor.platform_carry_y * 8);
    }
}

/// @function actor_controller_debug_draw_spray
/// @description Draws spray aim and recoil vectors when vector debug drawing is enabled.
/// @param {Struct} _actor Actor controller to draw.
/// @returns {Undefined} No return value.
function actor_controller_debug_draw_spray(_actor) {
    if (!is_struct(_actor) || !_actor.debug_enabled || !_actor.debug_draw_vectors) {
        return;
    }

    var _origin_x = _actor.spray_origin_x;
    var _origin_y = _actor.spray_origin_y;
    var _aim_x = _origin_x + _actor.spray_aim_x * ACTOR_DEBUG_SPRAY_AIM_VECTOR_LENGTH_DEFAULT;
    var _aim_y = _origin_y + _actor.spray_aim_y * ACTOR_DEBUG_SPRAY_AIM_VECTOR_LENGTH_DEFAULT;
    var _recoil_x = _origin_x + _actor.spray_recoil_x * ACTOR_DEBUG_SPRAY_RECOIL_VECTOR_SCALE_DEFAULT;
    var _recoil_y = _origin_y + _actor.spray_recoil_y * ACTOR_DEBUG_SPRAY_RECOIL_VECTOR_SCALE_DEFAULT;

    draw_set_alpha(1);
    draw_set_color(c_aqua);
    draw_line(_origin_x, _origin_y, _aim_x, _aim_y);
    draw_circle(_origin_x, _origin_y, ACTOR_DEBUG_SPRAY_ORIGIN_RADIUS_DEFAULT, false);

    if (_actor.spray_active
        || actor_controller_is_charged_shot_releasing(_actor)
        || actor_controller_is_continuous_spray_lift_fading(_actor)
        || (point_distance(0, 0, _actor.spray_recoil_x, _actor.spray_recoil_y) > ACTOR_EPSILON)) {
        draw_set_color(c_orange);
        draw_line(_origin_x, _origin_y, _recoil_x, _recoil_y);
    }
}
