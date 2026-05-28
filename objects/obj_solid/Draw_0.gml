/// @description Draw the sprite-less solid fixture rectangle.
var _rect = actor_collision_get_solid_rect(id);

draw_set_alpha(0.28);
draw_set_color(c_gray);
draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, true);
