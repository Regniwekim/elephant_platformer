/// @description Build input and update the generic actor controller.
actor_input_frame_number += 1;
actor_input = player_input_build_frame(id, actor_controller.x, actor_controller.y, actor_input_frame_number);

if (actor_input.debug_toggle_pressed) {
    actor_controller.debug_enabled = !actor_controller.debug_enabled;
}

if (actor_input.debug_unlimited_capacity_toggle_pressed) {
    actor_controller.debug_unlimited_capacity = !actor_controller.debug_unlimited_capacity;
}

actor_controller_update(actor_controller, actor_input);
actor_controller_apply_to_instance(actor_controller, id);
