/// @description Generic input frame helpers for actor controller consumers.

/// @function actor_input_frame_create_empty
/// @description Creates an empty input frame tagged with source metadata.
/// @param {Real} _source_type ActorInputSource enum value.
/// @param {Any} _source_id Source identifier, such as an instance id.
/// @param {Real} _frame_number Frame number assigned by the caller.
/// @returns {Struct} Empty actor input frame.
function actor_input_frame_create_empty(_source_type, _source_id, _frame_number) {
    var _frame = new ActorInputFrame();

    _frame.source_type = _source_type;
    _frame.source_id = _source_id;
    _frame.frame_number = _frame_number;

    return _frame;
}

/// @function actor_input_frame_normalize
/// @description Normalizes axis and aim values on an ActorInputFrame while preserving raw fields.
/// @param {Struct} _frame Input frame to normalize.
/// @returns {Struct} Normalized input frame, or an empty frame if the input is invalid.
function actor_input_frame_normalize(_frame) {
    if (!is_struct(_frame)) {
        return actor_input_frame_create_empty(ActorInputSource.NONE, noone, 0);
    }

    if (!variable_struct_exists(_frame, "run_pressed")) {
        _frame.run_pressed = false;
    }
    if (!variable_struct_exists(_frame, "run_held")) {
        _frame.run_held = false;
    }
    if (!variable_struct_exists(_frame, "run_released")) {
        _frame.run_released = false;
    }
    if (!variable_struct_exists(_frame, "debug_unlimited_capacity_toggle_pressed")) {
        _frame.debug_unlimited_capacity_toggle_pressed = false;
    }

    var _move_x = clamp(_frame.raw_move_x, -1, 1);
    var _move_y = clamp(_frame.raw_move_y, -1, 1);
    var _move_length = point_distance(0, 0, _move_x, _move_y);

    if (_move_length > 1) {
        _move_x /= _move_length;
        _move_y /= _move_length;
    }

    _frame.move_x = _move_x;
    _frame.move_y = _move_y;

    var _aim_length = point_distance(0, 0, _frame.raw_aim_x, _frame.raw_aim_y);
    if (_aim_length > ACTOR_EPSILON) {
        _frame.aim_x = _frame.raw_aim_x / _aim_length;
        _frame.aim_y = _frame.raw_aim_y / _aim_length;
    } else {
        _frame.aim_x = 1;
        _frame.aim_y = 0;
    }

    _frame.aim_angle = point_direction(0, 0, _frame.aim_x, _frame.aim_y);
    _frame.nozzle_value_delta = clamp(_frame.nozzle_value_delta, -1, 1);

    return _frame;
}
