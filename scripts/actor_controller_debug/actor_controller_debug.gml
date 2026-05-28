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
    var _text = "";

    _text += "Actor Controller " + string(_actor.version) + "\n";
    _text += "state: " + actor_controller_debug_move_state_name(_actor.state);
    _text += "  prev: " + actor_controller_debug_move_state_name(_actor.state_previous) + "\n";
    _text += "pos: (" + actor_controller_debug_format_real(_actor.x) + ", " + actor_controller_debug_format_real(_actor.y) + ")";
    _text += "  prev: (" + actor_controller_debug_format_real(_actor.x_previous) + ", " + actor_controller_debug_format_real(_actor.y_previous) + ")\n";
    _text += "vel: (" + actor_controller_debug_format_real(_actor.hsp) + ", " + actor_controller_debug_format_real(_actor.vsp) + ")";
    _text += "  external: (" + actor_controller_debug_format_real(_actor.external_hsp) + ", " + actor_controller_debug_format_real(_actor.external_vsp) + ")\n";
    _text += "grounded: " + actor_controller_debug_bool_text(_actor.is_grounded);
    _text += "  physical: " + actor_controller_debug_bool_text(_actor.is_physically_grounded);
    _text += "  was: " + actor_controller_debug_bool_text(_actor.was_grounded) + "\n";
    _text += "timers jump/coyote/wall/ledge/drop/lock: ";
    _text += string(_actor.jump_buffer_timer) + "/";
    _text += string(_actor.ground_coyote_timer) + "/";
    _text += string(_actor.wall_coyote_timer) + "/";
    _text += string(_actor.ledge_coyote_timer) + "/";
    _text += string(_actor.drop_through_timer) + "/";
    _text += string(_actor.wall_jump_lockout_timer) + "\n";
    _text += "spray: " + actor_controller_debug_spray_mode_name(_actor.spray_mode);
    _text += " active: " + actor_controller_debug_bool_text(_actor.spray_active);
    _text += " aim: (" + actor_controller_debug_format_real(_actor.spray_aim_x) + ", " + actor_controller_debug_format_real(_actor.spray_aim_y) + ")\n";
    _text += "water: " + actor_controller_debug_format_real(_actor.water_current) + "/" + actor_controller_debug_format_real(_actor.water_max);
    _text += "  charge: " + actor_controller_debug_format_real(_actor.charge_amount);
    _text += " timer: " + string(_actor.charge_timer);
    _text += " ready: " + actor_controller_debug_bool_text(_actor.charge_ready) + "\n";

    if (_has_input) {
        _text += "input frame: " + string(_input.frame_number);
        _text += " move: (" + actor_controller_debug_format_real(_input.move_x) + ", " + actor_controller_debug_format_real(_input.move_y) + ")";
        _text += " aim: (" + actor_controller_debug_format_real(_input.aim_x) + ", " + actor_controller_debug_format_real(_input.aim_y) + ")\n";
        _text += "buttons jump/spray/charge/slide/drop/cancel: ";
        _text += actor_controller_debug_bool_text(_input.jump_held) + "/";
        _text += actor_controller_debug_bool_text(_input.spray_held) + "/";
        _text += actor_controller_debug_bool_text(_input.charge_held) + "/";
        _text += actor_controller_debug_bool_text(_input.slide_held) + "/";
        _text += actor_controller_debug_bool_text(_input.drop_pressed) + "/";
        _text += actor_controller_debug_bool_text(_input.cancel_held) + "\n";
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
