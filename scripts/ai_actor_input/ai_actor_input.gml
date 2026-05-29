/// @description AI and scripted input adapters for actor controller frames.

/// @function ai_actor_input_build_frame
/// @description Converts AI intent data into an ActorInputFrame.
/// @param {Any} _source_id AI source identifier, such as an instance id.
/// @param {Real} _frame_number Frame number assigned by the caller.
/// @param {Struct} _intent Data-only movement, button, aim, and command intent.
/// @returns {Struct} Actor input frame populated with AI intent.
function ai_actor_input_build_frame(_source_id, _frame_number, _intent) {
    var _frame = actor_input_frame_create_empty(ActorInputSource.AI, _source_id, _frame_number);

    ai_actor_input_apply_intent(_frame, _intent);

    return actor_input_frame_normalize(_frame);
}

/// @function script_actor_input_build_frame
/// @description Converts scripted intent data into an ActorInputFrame.
/// @param {Any} _source_id Script source identifier, such as an instance id or data id.
/// @param {Real} _frame_number Frame number assigned by the caller.
/// @param {Struct} _intent Data-only movement, button, aim, and command intent.
/// @returns {Struct} Actor input frame populated with scripted intent.
function script_actor_input_build_frame(_source_id, _frame_number, _intent) {
    var _frame = actor_input_frame_create_empty(ActorInputSource.SCRIPT, _source_id, _frame_number);

    ai_actor_input_apply_intent(_frame, _intent);

    return actor_input_frame_normalize(_frame);
}

/// @function ai_actor_input_apply_intent
/// @description Copies recognized input intent fields onto an ActorInputFrame.
/// @param {Struct} _frame Input frame to populate.
/// @param {Struct} _intent Intent values to copy.
/// @returns {Struct} The input frame passed in.
function ai_actor_input_apply_intent(_frame, _intent) {
    if (!is_struct(_frame) || !is_struct(_intent)) {
        return _frame;
    }

    var _has_raw_move_x = ai_actor_input_copy_intent_field(_frame, _intent, "raw_move_x");
    if (!_has_raw_move_x && ai_actor_input_copy_intent_field(_frame, _intent, "move_x")) {
        _frame.raw_move_x = _frame.move_x;
    }

    var _has_raw_move_y = ai_actor_input_copy_intent_field(_frame, _intent, "raw_move_y");
    if (!_has_raw_move_y && ai_actor_input_copy_intent_field(_frame, _intent, "move_y")) {
        _frame.raw_move_y = _frame.move_y;
    }

    ai_actor_input_copy_intent_field(_frame, _intent, "jump_pressed");
    ai_actor_input_copy_intent_field(_frame, _intent, "jump_held");
    ai_actor_input_copy_intent_field(_frame, _intent, "jump_released");
    ai_actor_input_copy_intent_field(_frame, _intent, "run_pressed");
    ai_actor_input_copy_intent_field(_frame, _intent, "run_held");
    ai_actor_input_copy_intent_field(_frame, _intent, "run_released");
    ai_actor_input_copy_intent_field(_frame, _intent, "slide_pressed");
    ai_actor_input_copy_intent_field(_frame, _intent, "slide_held");
    ai_actor_input_copy_intent_field(_frame, _intent, "slide_released");
    ai_actor_input_copy_intent_field(_frame, _intent, "spray_pressed");
    ai_actor_input_copy_intent_field(_frame, _intent, "spray_held");
    ai_actor_input_copy_intent_field(_frame, _intent, "spray_released");
    ai_actor_input_copy_intent_field(_frame, _intent, "charge_pressed");
    ai_actor_input_copy_intent_field(_frame, _intent, "charge_held");
    ai_actor_input_copy_intent_field(_frame, _intent, "charge_released");
    ai_actor_input_copy_intent_field(_frame, _intent, "cancel_pressed");
    ai_actor_input_copy_intent_field(_frame, _intent, "cancel_held");
    ai_actor_input_copy_intent_field(_frame, _intent, "cancel_released");
    ai_actor_input_copy_intent_field(_frame, _intent, "drop_pressed");
    ai_actor_input_copy_intent_field(_frame, _intent, "drop_held");
    ai_actor_input_copy_intent_field(_frame, _intent, "drop_released");

    var _has_raw_aim_x = ai_actor_input_copy_intent_field(_frame, _intent, "raw_aim_x");
    if (!_has_raw_aim_x && ai_actor_input_copy_intent_field(_frame, _intent, "aim_x")) {
        _frame.raw_aim_x = _frame.aim_x;
    }

    var _has_raw_aim_y = ai_actor_input_copy_intent_field(_frame, _intent, "raw_aim_y");
    if (!_has_raw_aim_y && ai_actor_input_copy_intent_field(_frame, _intent, "aim_y")) {
        _frame.raw_aim_y = _frame.aim_y;
    }

    ai_actor_input_copy_intent_field(_frame, _intent, "nozzle_next_pressed");
    ai_actor_input_copy_intent_field(_frame, _intent, "nozzle_prev_pressed");
    var _has_nozzle_delta = ai_actor_input_copy_intent_field(_frame, _intent, "nozzle_value_delta");
    if (!_has_nozzle_delta) {
        _frame.nozzle_value_delta = (_frame.nozzle_next_pressed ? 1 : 0) - (_frame.nozzle_prev_pressed ? 1 : 0);
    }

    ai_actor_input_copy_intent_field(_frame, _intent, "debug_toggle_pressed");
    ai_actor_input_copy_intent_field(_frame, _intent, "debug_unlimited_capacity_toggle_pressed");

    return _frame;
}

/// @function ai_actor_input_copy_intent_field
/// @description Copies one matching field from an intent struct to an input frame.
/// @param {Struct} _frame Input frame receiving the field.
/// @param {Struct} _intent Intent struct providing the field.
/// @param {String} _field_name Field name to copy.
/// @returns {Bool} True when the field existed and was copied.
function ai_actor_input_copy_intent_field(_frame, _intent, _field_name) {
    if (!variable_struct_exists(_intent, _field_name)) {
        return false;
    }

    variable_struct_set(_frame, _field_name, variable_struct_get(_intent, _field_name));

    return true;
}
