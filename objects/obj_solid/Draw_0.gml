/// @description Draw the sprite-less solid fixture rectangle.
var _rect = actor_collision_get_solid_rect(id);

if (actor_collision_is_rotated_slope(id)) {
    var _width = ACTOR_SOLID_BASE_SIZE * abs(image_xscale);
    var _height = ACTOR_SOLID_BASE_SIZE * abs(image_yscale);
    var _left_point = actor_collision_get_rotated_point(id, -_width * 0.5, -_height * 0.5);
    var _right_point = actor_collision_get_rotated_point(id, _width * 0.5, -_height * 0.5);

    draw_set_alpha(0.32);
    draw_set_color(c_gray);
    draw_line(_left_point.x, _left_point.y, _right_point.x, _right_point.y);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_line(_left_point.x, _left_point.y - 1, _right_point.x, _right_point.y - 1);
    exit;
}

draw_set_alpha(0.28);
draw_set_color(c_gray);
draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_rectangle(_rect.left, _rect.top, _rect.right, _rect.bottom, true);
