/// @description Initialize moving platform path state.
platform_origin_x = x;
platform_origin_y = y;
platform_previous_x = x;
platform_previous_y = y;
platform_velocity_x = 0;
platform_velocity_y = 0;
move_axis_x = lengthdir_x(1, image_angle);
move_axis_y = lengthdir_y(1, image_angle);
move_distance = ACTOR_MOVING_PLATFORM_DISTANCE_DEFAULT;
move_speed = ACTOR_MOVING_PLATFORM_SPEED_DEFAULT;
move_progress = 0;
move_direction = 1;
