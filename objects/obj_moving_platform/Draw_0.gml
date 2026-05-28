/// @description Draw the moving platform fixture and path.
var _rect = actor_collision_get_instance_rect(id);
var _end_x = platform_origin_x + move_axis_x * move_distance;
var _end_y = platform_origin_y + move_axis_y * move_distance;

draw_set_alpha(0.35);
draw_set_color(c_orange);
draw_line(platform_origin_x, platform_origin_y, _end_x, _end_y);
draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, false);
draw_set_alpha(1);
draw_set_color(c_yellow);
draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, true);
