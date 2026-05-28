/// @description Draw the top-only one-way platform fixture rectangle.
var _rect = actor_collision_get_instance_rect(id);

draw_set_alpha(0.24);
draw_set_color(c_lime);
draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, false);
draw_set_alpha(1);
draw_set_color(c_green);
draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, true);
draw_line(_rect.left, _rect.top, _rect.right, _rect.top);
