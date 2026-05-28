/// @description Move before actor Step events so platform velocity is visible to controllers.
platform_previous_x = x;
platform_previous_y = y;

var _distance = max(0, move_distance);
var _speed = max(0, move_speed);

if ((_distance <= ACTOR_EPSILON) || (_speed <= ACTOR_EPSILON)) {
    platform_velocity_x = 0;
    platform_velocity_y = 0;
    exit;
}

move_progress += _speed * move_direction;

if (move_progress >= _distance) {
    move_progress = _distance;
    move_direction = -1;
} else if (move_progress <= 0) {
    move_progress = 0;
    move_direction = 1;
}

x = platform_origin_x + move_axis_x * move_progress;
y = platform_origin_y + move_axis_y * move_progress;
platform_velocity_x = x - platform_previous_x;
platform_velocity_y = y - platform_previous_y;
