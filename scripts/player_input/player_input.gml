/// @description Player-specific input adapter for actor controller frames.

/// @function player_input_build_frame
/// @description Reads human input and converts it into an ActorInputFrame.
/// @param {Id.Instance} _source_id Player instance id.
/// @param {Real} _origin_x Aim origin x position.
/// @param {Real} _origin_y Aim origin y position.
/// @param {Real} _frame_number Frame number assigned by the player object.
/// @returns {Struct} Actor input frame populated with player input.
function player_input_build_frame(_source_id, _origin_x, _origin_y, _frame_number) {
    var _frame = actor_input_frame_create_empty(ActorInputSource.PLAYER, _source_id, _frame_number);

    var _left = keyboard_check(vk_left) || keyboard_check(ord("A"));
    var _right = keyboard_check(vk_right) || keyboard_check(ord("D"));
    var _up = keyboard_check(vk_up) || keyboard_check(ord("W"));
    var _down = keyboard_check(vk_down) || keyboard_check(ord("S"));

    _frame.raw_move_x = (_right ? 1 : 0) - (_left ? 1 : 0);
    _frame.raw_move_y = (_down ? 1 : 0) - (_up ? 1 : 0);

    _frame.jump_pressed = keyboard_check_pressed(vk_space);
    _frame.jump_held = keyboard_check(vk_space);
    _frame.jump_released = keyboard_check_released(vk_space);

    _frame.run_pressed = keyboard_check_pressed(vk_control);
    _frame.run_held = keyboard_check(vk_control);
    _frame.run_released = keyboard_check_released(vk_control);

    _frame.slide_pressed = keyboard_check_pressed(vk_shift);
    _frame.slide_held = keyboard_check(vk_shift);
    _frame.slide_released = keyboard_check_released(vk_shift);

    _frame.spray_pressed = mouse_check_button_pressed(mb_left) || keyboard_check_pressed(ord("Z"));
    _frame.spray_held = mouse_check_button(mb_left) || keyboard_check(ord("Z"));
    _frame.spray_released = mouse_check_button_released(mb_left) || keyboard_check_released(ord("Z"));

    _frame.charge_pressed = mouse_check_button_pressed(mb_right) || keyboard_check_pressed(ord("X"));
    _frame.charge_held = mouse_check_button(mb_right) || keyboard_check(ord("X"));
    _frame.charge_released = mouse_check_button_released(mb_right) || keyboard_check_released(ord("X"));

    _frame.cancel_pressed = keyboard_check_pressed(vk_escape);
    _frame.cancel_held = keyboard_check(vk_escape);
    _frame.cancel_released = keyboard_check_released(vk_escape);
    _frame.drop_pressed = keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"));
    _frame.drop_held = _down;
    _frame.drop_released = keyboard_check_released(vk_down) || keyboard_check_released(ord("S"));

    _frame.nozzle_prev_pressed = keyboard_check_pressed(ord("Q"));
    _frame.nozzle_next_pressed = keyboard_check_pressed(ord("E"));
    _frame.nozzle_value_delta = (_frame.nozzle_next_pressed ? 1 : 0) - (_frame.nozzle_prev_pressed ? 1 : 0);

    _frame.raw_aim_x = mouse_x - _origin_x;
    _frame.raw_aim_y = mouse_y - _origin_y;

    _frame.debug_toggle_pressed = keyboard_check_pressed(vk_f3);
    _frame.debug_unlimited_capacity_toggle_pressed = keyboard_check_pressed(vk_f4);

    return actor_input_frame_normalize(_frame);
}
