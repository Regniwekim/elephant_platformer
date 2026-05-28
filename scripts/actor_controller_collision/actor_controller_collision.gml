/// @description Flat solid collision helpers for the generic actor controller.

/// @function actor_collision_get_actor_rect
/// @description Builds the centered actor collision rectangle for a proposed position.
/// @param {Struct} _actor Actor controller containing collision stats.
/// @param {Real} _x Proposed actor center x position.
/// @param {Real} _y Proposed actor center y position.
/// @returns {Struct} Rectangle with left, top, right, and bottom fields.
function actor_collision_get_actor_rect(_actor, _x, _y) {
    var _half_width = _actor.stats.bbox_width * 0.5;
    var _half_height = _actor.stats.bbox_height * 0.5;
    var _rect = {};

    _rect.left = _x - _half_width;
    _rect.top = _y - _half_height;
    _rect.right = _x + _half_width;
    _rect.bottom = _y + _half_height;

    return _rect;
}

/// @function actor_collision_get_solid_rect
/// @description Builds the centered rectangle used by an obj_solid fixture.
/// @param {Id.Instance} _solid Solid instance to measure.
/// @returns {Struct} Rectangle with left, top, right, and bottom fields.
function actor_collision_get_solid_rect(_solid) {
    var _width = ACTOR_SOLID_BASE_SIZE * abs(_solid.image_xscale);
    var _height = ACTOR_SOLID_BASE_SIZE * abs(_solid.image_yscale);
    var _half_width = max(_width * 0.5, ACTOR_EPSILON);
    var _half_height = max(_height * 0.5, ACTOR_EPSILON);
    var _rect = {};

    _rect.left = _solid.x - _half_width;
    _rect.top = _solid.y - _half_height;
    _rect.right = _solid.x + _half_width;
    _rect.bottom = _solid.y + _half_height;

    return _rect;
}

/// @function actor_collision_get_instance_rect
/// @description Builds the centered rectangle used by actor-controller terrain fixtures.
/// @param {Id.Instance} _instance Terrain instance to measure.
/// @returns {Struct} Rectangle with left, top, right, and bottom fields.
function actor_collision_get_instance_rect(_instance) {
    return actor_collision_get_solid_rect(_instance);
}

/// @function actor_collision_normalize_angle
/// @description Normalizes an angle into the 0-360 degree range.
/// @param {Real} _angle Angle in degrees.
/// @returns {Real} Normalized angle in degrees.
function actor_collision_normalize_angle(_angle) {
    var _normalized = _angle mod 360;

    if (_normalized < 0) {
        _normalized += 360;
    }

    return _normalized;
}

/// @function actor_collision_is_rotated_slope
/// @description Reports whether an obj_solid instance should be handled as a slope fixture.
/// @param {Id.Instance} _solid Solid instance to inspect.
/// @returns {Bool} True when the solid is a rotated slope fixture.
function actor_collision_is_rotated_slope(_solid) {
    if (!instance_exists(_solid)) {
        return false;
    }

    if (_solid.object_index != obj_solid) {
        return false;
    }

    var _angle = actor_collision_normalize_angle(_solid.image_angle);

    return min(_angle, 360 - _angle) > ACTOR_EPSILON;
}

/// @function actor_collision_is_moving_platform
/// @description Reports whether an instance is a moving platform terrain fixture.
/// @param {Id.Instance} _instance Instance to inspect.
/// @returns {Bool} True when the instance is an obj_moving_platform.
function actor_collision_is_moving_platform(_instance) {
    return instance_exists(_instance) && (_instance.object_index == obj_moving_platform);
}

/// @function actor_collision_is_one_way_platform
/// @description Reports whether an instance is a one-way platform terrain fixture.
/// @param {Id.Instance} _instance Instance to inspect.
/// @returns {Bool} True when the instance is an obj_one_way_platform.
function actor_collision_is_one_way_platform(_instance) {
    return instance_exists(_instance) && (_instance.object_index == obj_one_way_platform);
}

/// @function actor_collision_should_ignore_instance
/// @description Checks whether a terrain instance is temporarily ignored by the actor.
/// @param {Struct} _actor Actor controller containing ignore state.
/// @param {Id.Instance} _instance Terrain instance to test.
/// @returns {Bool} True when the instance should be skipped.
function actor_collision_should_ignore_instance(_actor, _instance) {
    if (!is_struct(_actor) || !instance_exists(_instance)) {
        return false;
    }

    if (_actor.collision_ignore_object == _instance) {
        return true;
    }

    if ((_actor.drop_through_timer > 0) && (_actor.one_way_ignore_object == _instance)) {
        return true;
    }

    return false;
}

/// @function actor_collision_rects_overlap
/// @description Checks whether two rectangles overlap with touching edges treated as non-overlap.
/// @param {Struct} _a First rectangle.
/// @param {Struct} _b Second rectangle.
/// @returns {Bool} True when the rectangles overlap.
function actor_collision_rects_overlap(_a, _b) {
    return (_a.left < _b.right)
        && (_a.right > _b.left)
        && (_a.top < _b.bottom)
        && (_a.bottom > _b.top);
}

/// @function actor_collision_find_solid_hit_for_rect
/// @description Finds the first full-solid terrain fixture whose rectangle overlaps the provided rectangle.
/// @param {Struct} _actor Actor controller containing temporary ignore state.
/// @param {Struct} _rect Rectangle to test.
/// @returns {Id.Instance} Solid instance id, or noone when clear.
function actor_collision_find_solid_hit_for_rect(_actor, _rect) {
    var _count = instance_number(obj_solid);

    for (var _i = 0; _i < _count; _i++) {
        var _solid = instance_find(obj_solid, _i);

        if (actor_collision_is_rotated_slope(_solid) || actor_collision_should_ignore_instance(_actor, _solid)) {
            continue;
        }

        var _solid_rect = actor_collision_get_instance_rect(_solid);

        if (actor_collision_rects_overlap(_rect, _solid_rect)) {
            return _solid;
        }
    }

    _count = instance_number(obj_moving_platform);

    for (var _j = 0; _j < _count; _j++) {
        var _platform = instance_find(obj_moving_platform, _j);

        if (actor_collision_should_ignore_instance(_actor, _platform)) {
            continue;
        }

        var _platform_rect = actor_collision_get_instance_rect(_platform);

        if (actor_collision_rects_overlap(_rect, _platform_rect)) {
            return _platform;
        }
    }

    return noone;
}

/// @function actor_collision_find_solid_hit
/// @description Finds the first solid overlapping an actor at a proposed position.
/// @param {Struct} _actor Actor controller to test.
/// @param {Real} _x Proposed actor center x position.
/// @param {Real} _y Proposed actor center y position.
/// @returns {Id.Instance} Solid instance id, or noone when clear.
function actor_collision_find_solid_hit(_actor, _x, _y) {
    var _rect = actor_collision_get_actor_rect(_actor, _x, _y);
    return actor_collision_find_solid_hit_for_rect(_actor, _rect);
}

/// @function actor_collision_place_solid
/// @description Checks whether the actor would overlap a flat obj_solid at a proposed position.
/// @param {Struct} _actor Actor controller to test.
/// @param {Real} _x Proposed actor center x position.
/// @param {Real} _y Proposed actor center y position.
/// @returns {Bool} True when the proposed position overlaps a solid.
function actor_collision_place_solid(_actor, _x, _y) {
    if (!is_struct(_actor)) {
        return false;
    }

    return actor_collision_find_solid_hit(_actor, _x, _y) != noone;
}

/// @function actor_collision_find_one_way_hit
/// @description Finds a one-way platform that blocks the actor at a proposed position.
/// @param {Struct} _actor Actor controller to test.
/// @param {Real} _x Proposed actor center x position.
/// @param {Real} _y Proposed actor center y position.
/// @param {Real} _move_y Proposed vertical movement amount.
/// @returns {Id.Instance} One-way platform instance id, or noone when clear.
function actor_collision_find_one_way_hit(_actor, _x, _y, _move_y) {
    if (!is_struct(_actor) || (_move_y < 0)) {
        return noone;
    }

    var _actor_rect = actor_collision_get_actor_rect(_actor, _x, _y);
    var _previous_rect = actor_collision_get_actor_rect(_actor, _actor.x_previous, _actor.y_previous);
    var _count = instance_number(obj_one_way_platform);

    for (var _i = 0; _i < _count; _i++) {
        var _platform = instance_find(obj_one_way_platform, _i);

        if (actor_collision_should_ignore_instance(_actor, _platform)) {
            continue;
        }

        var _platform_rect = actor_collision_get_instance_rect(_platform);
        var _horizontally_overlaps = (_actor_rect.left < _platform_rect.right)
            && (_actor_rect.right > _platform_rect.left);
        var _crossed_top = (_previous_rect.bottom <= _platform_rect.top + ACTOR_CONTACT_PROBE_DISTANCE)
            && (_actor_rect.bottom >= _platform_rect.top);
        var _actor_is_above = _actor_rect.top < _platform_rect.top;

        if (_horizontally_overlaps && _crossed_top && _actor_is_above) {
            return _platform;
        }
    }

    return noone;
}

/// @function actor_collision_place_one_way
/// @description Checks whether the actor would be blocked by a one-way platform at a proposed position.
/// @param {Struct} _actor Actor controller to test.
/// @param {Real} _x Proposed actor center x position.
/// @param {Real} _y Proposed actor center y position.
/// @param {Real} _move_y Proposed vertical movement amount.
/// @returns {Bool} True when the proposed position is blocked by a one-way platform.
function actor_collision_place_one_way(_actor, _x, _y, _move_y) {
    return actor_collision_find_one_way_hit(_actor, _x, _y, _move_y) != noone;
}

/// @function actor_collision_place_blocking
/// @description Checks full-solid and one-way blocking terrain for a proposed movement.
/// @param {Struct} _actor Actor controller to test.
/// @param {Real} _x Proposed actor center x position.
/// @param {Real} _y Proposed actor center y position.
/// @param {Real} _move_x Proposed horizontal movement amount.
/// @param {Real} _move_y Proposed vertical movement amount.
/// @returns {Bool} True when the proposed position is blocked.
function actor_collision_place_blocking(_actor, _x, _y, _move_x, _move_y) {
    if (actor_collision_place_solid(_actor, _x, _y)) {
        return true;
    }

    if (abs(_move_x) > ACTOR_EPSILON) {
        return false;
    }

    return actor_collision_place_one_way(_actor, _x, _y, _move_y);
}

/// @function actor_collision_create_move_result
/// @description Creates a movement result struct used by collision movement helpers.
/// @returns {Struct} Empty movement result data.
function actor_collision_create_move_result() {
    var _result = {};

    _result.moved_x = 0;
    _result.moved_y = 0;
    _result.blocked_x = false;
    _result.blocked_y = false;
    _result.iterations = 0;

    return _result;
}

/// @function actor_collision_get_safe_axis_step
/// @description Refines a blocked axis step to the nearest clear movement amount.
/// @param {Struct} _actor Actor controller to test.
/// @param {Real} _amount Signed step amount to refine.
/// @param {Bool} _move_x_axis True for x movement, false for y movement.
/// @returns {Real} Signed safe step amount.
function actor_collision_get_safe_axis_step(_actor, _amount, _move_x_axis) {
    var _direction = sign(_amount);
    var _low = 0;
    var _high = abs(_amount);
    var _refine_count = 0;

    while ((_high - _low > ACTOR_COLLISION_SWEEP_REFINEMENT) && (_refine_count < ACTOR_MAX_COLLISION_ITERATIONS)) {
        var _middle = (_low + _high) * 0.5;
        var _test_step = _middle * _direction;
        var _test_x = _actor.x + (_move_x_axis ? _test_step : 0);
        var _test_y = _actor.y + (_move_x_axis ? 0 : _test_step);

        if (actor_collision_place_blocking(_actor, _test_x, _test_y, _move_x_axis ? _test_step : 0, _move_x_axis ? 0 : _test_step)) {
            _high = _middle;
        } else {
            _low = _middle;
        }

        _refine_count += 1;
    }

    return _low * _direction;
}

/// @function actor_collision_move_x
/// @description Moves the actor horizontally in safe chunks and stops at flat solids.
/// @param {Struct} _actor Actor controller to move.
/// @param {Real} _amount Requested horizontal movement in pixels.
/// @returns {Struct} Movement result with moved and blocked fields.
function actor_collision_move_x(_actor, _amount) {
    var _result = actor_collision_create_move_result();

    if (!is_struct(_actor) || abs(_amount) <= ACTOR_EPSILON) {
        return _result;
    }

    var _direction = sign(_amount);
    var _remaining = abs(_amount);

    while ((_remaining > ACTOR_EPSILON) && (_result.iterations < ACTOR_MAX_COLLISION_ITERATIONS)) {
        var _step_size = min(_remaining, ACTOR_MAX_MOVE_STEP_PIXELS);
        var _step = _step_size * _direction;

        _result.iterations += 1;

        if (!actor_collision_place_blocking(_actor, _actor.x + _step, _actor.y, _step, 0)) {
            _actor.x += _step;
            _result.moved_x += _step;
            _remaining -= _step_size;
            continue;
        }

        var _safe_step = actor_collision_get_safe_axis_step(_actor, _step, true);
        if (abs(_safe_step) > ACTOR_EPSILON) {
            _actor.x += _safe_step;
            _result.moved_x += _safe_step;
        }

        _result.blocked_x = true;
        _actor.hsp = 0;
        _actor.external_hsp = 0;
        break;
    }

    _actor.collision_iterations += _result.iterations;
    _actor.collision_last_move_x += _result.moved_x;

    return _result;
}

/// @function actor_collision_move_y
/// @description Moves the actor vertically in safe chunks and stops at flat solids.
/// @param {Struct} _actor Actor controller to move.
/// @param {Real} _amount Requested vertical movement in pixels.
/// @returns {Struct} Movement result with moved and blocked fields.
function actor_collision_move_y(_actor, _amount) {
    var _result = actor_collision_create_move_result();

    if (!is_struct(_actor) || abs(_amount) <= ACTOR_EPSILON) {
        return _result;
    }

    var _direction = sign(_amount);
    var _remaining = abs(_amount);

    while ((_remaining > ACTOR_EPSILON) && (_result.iterations < ACTOR_MAX_COLLISION_ITERATIONS)) {
        var _step_size = min(_remaining, ACTOR_MAX_MOVE_STEP_PIXELS);
        var _step = _step_size * _direction;

        _result.iterations += 1;

        if (!actor_collision_place_blocking(_actor, _actor.x, _actor.y + _step, 0, _step)) {
            _actor.y += _step;
            _result.moved_y += _step;
            _remaining -= _step_size;
            continue;
        }

        var _safe_step = actor_collision_get_safe_axis_step(_actor, _step, false);
        if (abs(_safe_step) > ACTOR_EPSILON) {
            _actor.y += _safe_step;
            _result.moved_y += _safe_step;
        }

        _result.blocked_y = true;
        _actor.vsp = 0;
        _actor.external_vsp = 0;
        break;
    }

    _actor.collision_iterations += _result.iterations;
    _actor.collision_last_move_y += _result.moved_y;

    return _result;
}

/// @function actor_collision_move_and_slide
/// @description Resolves horizontal then vertical movement against flat solids and refreshes contact state.
/// @param {Struct} _actor Actor controller to move.
/// @param {Real} _move_x Requested horizontal movement in pixels.
/// @param {Real} _move_y Requested vertical movement in pixels.
/// @returns {Struct} Combined movement result.
function actor_collision_move_and_slide(_actor, _move_x, _move_y) {
    var _result = actor_collision_create_move_result();

    if (!is_struct(_actor)) {
        return _result;
    }

    _actor.collision_blocked_x = false;
    _actor.collision_blocked_y = false;
    _actor.collision_last_move_x = 0;
    _actor.collision_last_move_y = 0;
    _actor.collision_iterations = 0;

    var _projected_move = actor_controller_project_velocity_on_slope(_actor, _move_x, _move_y);
    _move_x = _projected_move.x;
    _move_y = _projected_move.y;

    var _x_result = actor_collision_move_x(_actor, _move_x);
    var _y_result = actor_collision_move_y(_actor, _move_y);
    var _slope_result = actor_collision_resolve_slope(_actor, _move_x, _move_y);

    _result.moved_x = _x_result.moved_x;
    _result.moved_y = _y_result.moved_y + _slope_result.moved_y;
    _result.blocked_x = _x_result.blocked_x;
    _result.blocked_y = _y_result.blocked_y || _slope_result.blocked_y;
    _result.iterations = _x_result.iterations + _y_result.iterations + _slope_result.iterations;

    _actor.collision_blocked_x = _result.blocked_x;
    _actor.collision_blocked_y = _result.blocked_y;

    actor_collision_refresh_contacts(_actor);

    return _result;
}

/// @function actor_collision_make_empty_slope_info
/// @description Creates inactive slope probe data.
/// @returns {Struct} Empty slope info.
function actor_collision_make_empty_slope_info() {
    return {
        active: false,
        object_id: noone,
        surface_y: 0,
        distance: 0,
        normal_x: 0,
        normal_y: -1,
        tangent_x: 1,
        tangent_y: 0,
        angle: 0,
        walkable: false,
        surface: new ActorSurfaceInfo()
    };
}

/// @function actor_collision_get_rotated_point
/// @description Converts a local point on a fixture into world coordinates using image_angle.
/// @param {Id.Instance} _instance Terrain instance to transform against.
/// @param {Real} _local_x Local x offset from the instance origin.
/// @param {Real} _local_y Local y offset from the instance origin.
/// @returns {Struct} Point with x and y fields.
function actor_collision_get_rotated_point(_instance, _local_x, _local_y) {
    var _distance = point_distance(0, 0, _local_x, _local_y);
    var _direction = point_direction(0, 0, _local_x, _local_y) + _instance.image_angle;

    return {
        x: _instance.x + lengthdir_x(_distance, _direction),
        y: _instance.y + lengthdir_y(_distance, _direction)
    };
}

/// @function actor_collision_get_slope_info
/// @description Finds walkable top-edge slope data under an actor at a proposed position.
/// @param {Struct} _actor Actor controller to test.
/// @param {Real} _x Proposed actor center x position.
/// @param {Real} _y Proposed actor center y position.
/// @returns {Struct} Slope info, inactive when no slope is in range.
function actor_collision_get_slope_info(_actor, _x, _y) {
    if (!is_struct(_actor)) {
        return actor_collision_make_empty_slope_info();
    }

    var _half_width = _actor.stats.bbox_width * 0.5;
    var _half_height = _actor.stats.bbox_height * 0.5;
    var _actor_bottom = _y + _half_height;
    var _snap_distance = actor_stats_get_optional(_actor.stats, "slope_snap_distance", ACTOR_SLOPE_SNAP_DISTANCE_DEFAULT);
    var _best = actor_collision_make_empty_slope_info();
    var _best_abs_distance = ACTOR_NO_HIT_DISTANCE;
    var _count = instance_number(obj_solid);

    for (var _i = 0; _i < _count; _i++) {
        var _solid = instance_find(obj_solid, _i);

        if (!actor_collision_is_rotated_slope(_solid) || actor_collision_should_ignore_instance(_actor, _solid)) {
            continue;
        }

        var _width = ACTOR_SOLID_BASE_SIZE * abs(_solid.image_xscale);
        var _height = ACTOR_SOLID_BASE_SIZE * abs(_solid.image_yscale);
        var _left_point = actor_collision_get_rotated_point(_solid, -_width * 0.5, -_height * 0.5);
        var _right_point = actor_collision_get_rotated_point(_solid, _width * 0.5, -_height * 0.5);

        if (_left_point.x > _right_point.x) {
            var _swap = _left_point;
            _left_point = _right_point;
            _right_point = _swap;
        }

        var _span_x = _right_point.x - _left_point.x;
        if (abs(_span_x) <= ACTOR_EPSILON) {
            continue;
        }

        if ((_x < _left_point.x - _half_width) || (_x > _right_point.x + _half_width)) {
            continue;
        }

        var _t = clamp((_x - _left_point.x) / _span_x, 0, 1);
        var _surface_y = lerp(_left_point.y, _right_point.y, _t);
        var _distance = _actor_bottom - _surface_y;
        var _distance_limit = max(_snap_distance, max(0, _actor.vsp + _actor.external_vsp) + ACTOR_CONTACT_PROBE_DISTANCE);

        if ((_distance < -_distance_limit) || (_distance > _distance_limit)) {
            continue;
        }

        var _span_y = _right_point.y - _left_point.y;
        var _length = max(point_distance(_left_point.x, _left_point.y, _right_point.x, _right_point.y), ACTOR_EPSILON);
        var _tangent_x = _span_x / _length;
        var _tangent_y = _span_y / _length;
        var _normal_x = _tangent_y;
        var _normal_y = -_tangent_x;
        var _angle = radtodeg(arctan(abs(_span_y) / max(abs(_span_x), ACTOR_EPSILON)));
        var _surface = actor_surface_get_info(_solid);
        var _max_angle = actor_stats_get_optional(_actor.stats, "slope_max_angle", ACTOR_SLOPE_MAX_ANGLE_DEFAULT);
        var _walkable = (_angle <= _max_angle) && actor_surface_is_walkable(_surface);
        var _abs_distance = abs(_distance);

        if (_abs_distance < _best_abs_distance) {
            _best.active = true;
            _best.object_id = _solid;
            _best.surface_y = _surface_y;
            _best.distance = _distance;
            _best.normal_x = _normal_x;
            _best.normal_y = _normal_y;
            _best.tangent_x = _tangent_x;
            _best.tangent_y = _tangent_y;
            _best.angle = _angle;
            _best.walkable = _walkable;
            _best.surface = _surface;
            _best_abs_distance = _abs_distance;
        }
    }

    return _best;
}

/// @function actor_collision_snap_to_ground
/// @description Snaps the actor onto a nearby walkable slope without canceling upward launch velocity.
/// @param {Struct} _actor Actor controller to snap.
/// @param {Real} _max_distance Maximum signed distance from the actor feet to the slope.
/// @returns {Struct} Movement result describing any snap movement.
function actor_collision_snap_to_ground(_actor, _max_distance) {
    var _result = actor_collision_create_move_result();

    if (!is_struct(_actor) || (_actor.vsp < 0) || (_actor.external_vsp < 0)) {
        return _result;
    }

    var _slope = actor_collision_get_slope_info(_actor, _actor.x, _actor.y);

    if (!_slope.active || !_slope.walkable) {
        return _result;
    }

    var _allowed_distance = max(0, _max_distance);
    if ((-_slope.distance > _allowed_distance) || (_slope.distance > _allowed_distance)) {
        return _result;
    }

    var _target_y = _slope.surface_y - (_actor.stats.bbox_height * 0.5);
    var _snap_y = _target_y - _actor.y;

    if (abs(_snap_y) <= ACTOR_EPSILON) {
        return _result;
    }

    if (actor_collision_place_solid(_actor, _actor.x, _target_y)) {
        return _result;
    }

    _actor.y = _target_y;
    _actor.vsp = min(_actor.vsp, 0);
    _actor.external_vsp = min(_actor.external_vsp, 0);
    _result.moved_y = _snap_y;
    _result.iterations = 1;
    _actor.collision_last_move_y += _snap_y;
    _actor.collision_iterations += 1;

    return _result;
}

/// @function actor_collision_resolve_slope
/// @description Resolves final actor placement onto nearby walkable slope ground after axis movement.
/// @param {Struct} _actor Actor controller to resolve.
/// @param {Real} _requested_move_x Horizontal movement requested this frame.
/// @param {Real} _requested_move_y Vertical movement requested this frame.
/// @returns {Struct} Movement result describing slope correction.
function actor_collision_resolve_slope(_actor, _requested_move_x, _requested_move_y) {
    var _result = actor_collision_create_move_result();

    if (!is_struct(_actor)) {
        return _result;
    }

    var _snap_distance = actor_stats_get_optional(_actor.stats, "slope_snap_distance", ACTOR_SLOPE_SNAP_DISTANCE_DEFAULT);
    var _step_height = actor_stats_get_optional(_actor.stats, "slope_step_height", ACTOR_SLOPE_STEP_HEIGHT_DEFAULT);
    var _allowed_distance = _snap_distance;

    if (abs(_requested_move_x) > ACTOR_EPSILON) {
        _allowed_distance = max(_allowed_distance, _step_height);
    }

    if (_requested_move_y > 0) {
        _allowed_distance = max(_allowed_distance, _requested_move_y + ACTOR_CONTACT_PROBE_DISTANCE);
    }

    return actor_collision_snap_to_ground(_actor, _allowed_distance);
}

/// @function actor_collision_reset_contact
/// @description Clears a contact struct back to its inactive state.
/// @param {Struct} _contact Contact struct to reset.
/// @returns {Struct} Reset contact struct.
function actor_collision_reset_contact(_contact) {
    if (!is_struct(_contact)) {
        _contact = new ActorContactInfo();
    }

    _contact.active = false;
    _contact.side = ActorCollisionSide.NONE;
    _contact.object_id = noone;
    _contact.normal_x = 0;
    _contact.normal_y = 0;
    _contact.depth = 0;
    _contact.surface = new ActorSurfaceInfo();

    return _contact;
}

/// @function actor_collision_make_contact
/// @description Creates populated contact data for a solid hit.
/// @param {Real} _side ActorCollisionSide enum value for the contact side.
/// @param {Id.Instance} _solid Solid instance that was contacted.
/// @param {Real} _normal_x Contact normal x direction.
/// @param {Real} _normal_y Contact normal y direction.
/// @param {Real} _depth Overlap depth in pixels.
/// @returns {Struct} Populated contact info.
function actor_collision_make_contact(_side, _solid, _normal_x, _normal_y, _depth) {
    var _contact = new ActorContactInfo();

    _contact.active = true;
    _contact.side = _side;
    _contact.object_id = _solid;
    _contact.normal_x = _normal_x;
    _contact.normal_y = _normal_y;
    _contact.depth = _depth;
    _contact.surface = actor_surface_get_info(_solid);

    return _contact;
}

/// @function actor_collision_get_contact_depth
/// @description Calculates flat overlap depth for a side contact.
/// @param {Struct} _actor_rect Actor rectangle at the current position.
/// @param {Struct} _solid_rect Solid rectangle being contacted.
/// @param {Real} _side ActorCollisionSide enum value.
/// @returns {Real} Non-negative contact depth in pixels.
function actor_collision_get_contact_depth(_actor_rect, _solid_rect, _side) {
    switch (_side) {
        case ActorCollisionSide.LEFT:
            return max(0, _solid_rect.right - _actor_rect.left);
        case ActorCollisionSide.RIGHT:
            return max(0, _actor_rect.right - _solid_rect.left);
        case ActorCollisionSide.TOP:
            return max(0, _solid_rect.bottom - _actor_rect.top);
        case ActorCollisionSide.BOTTOM:
            return max(0, _actor_rect.bottom - _solid_rect.top);
    }

    return 0;
}

/// @function actor_collision_get_contact_info
/// @description Probes one side of the actor and returns matching contact info.
/// @param {Struct} _actor Actor controller to probe.
/// @param {Real} _side ActorCollisionSide enum value to probe.
/// @returns {Struct} Contact info for the side, inactive when clear.
function actor_collision_get_contact_info(_actor, _side) {
    var _probe_x = _actor.x;
    var _probe_y = _actor.y;
    var _normal_x = 0;
    var _normal_y = 0;

    switch (_side) {
        case ActorCollisionSide.LEFT:
            _probe_x -= ACTOR_CONTACT_PROBE_DISTANCE;
            _normal_x = 1;
            break;
        case ActorCollisionSide.RIGHT:
            _probe_x += ACTOR_CONTACT_PROBE_DISTANCE;
            _normal_x = -1;
            break;
        case ActorCollisionSide.TOP:
            _probe_y -= ACTOR_CONTACT_PROBE_DISTANCE;
            _normal_y = 1;
            break;
        case ActorCollisionSide.BOTTOM:
            _probe_y += ACTOR_CONTACT_PROBE_DISTANCE;
            _normal_y = -1;
            break;
    }

    var _probe_rect = actor_collision_get_actor_rect(_actor, _probe_x, _probe_y);
    var _solid = actor_collision_find_solid_hit_for_rect(_actor, _probe_rect);

    if (_solid == noone) {
        return new ActorContactInfo();
    }

    var _actor_rect = actor_collision_get_actor_rect(_actor, _actor.x, _actor.y);
    var _solid_rect = actor_collision_get_instance_rect(_solid);
    var _depth = actor_collision_get_contact_depth(_actor_rect, _solid_rect, _side);

    return actor_collision_make_contact(_side, _solid, _normal_x, _normal_y, _depth);
}

/// @function actor_collision_get_one_way_contact_info
/// @description Probes for a bottom contact on a one-way platform.
/// @param {Struct} _actor Actor controller to probe.
/// @returns {Struct} Bottom contact info, inactive when no one-way platform is touched.
function actor_collision_get_one_way_contact_info(_actor) {
    if (!is_struct(_actor)) {
        return new ActorContactInfo();
    }

    var _one_way = actor_collision_find_one_way_hit(_actor, _actor.x, _actor.y + ACTOR_CONTACT_PROBE_DISTANCE, ACTOR_CONTACT_PROBE_DISTANCE);
    if (_one_way == noone) {
        return new ActorContactInfo();
    }

    var _actor_rect = actor_collision_get_actor_rect(_actor, _actor.x, _actor.y);
    var _platform_rect = actor_collision_get_instance_rect(_one_way);
    var _depth = max(0, _actor_rect.bottom - _platform_rect.top);

    return actor_collision_make_contact(ActorCollisionSide.BOTTOM, _one_way, 0, -1, _depth);
}

/// @function actor_collision_get_slope_contact_info
/// @description Probes for a bottom contact on a walkable slope.
/// @param {Struct} _actor Actor controller to probe.
/// @returns {Struct} Bottom contact info, inactive when no slope is touched.
function actor_collision_get_slope_contact_info(_actor) {
    if (!is_struct(_actor)) {
        return new ActorContactInfo();
    }

    var _slope = actor_collision_get_slope_info(_actor, _actor.x, _actor.y);

    if (!_slope.active || !_slope.walkable || (abs(_slope.distance) > ACTOR_CONTACT_PROBE_DISTANCE + ACTOR_EPSILON)) {
        return new ActorContactInfo();
    }

    var _contact = new ActorContactInfo();
    _contact.active = true;
    _contact.side = ActorCollisionSide.BOTTOM;
    _contact.object_id = _slope.object_id;
    _contact.normal_x = _slope.normal_x;
    _contact.normal_y = _slope.normal_y;
    _contact.depth = max(0, _slope.distance);
    _contact.surface = _slope.surface;

    return _contact;
}

/// @function actor_collision_get_ground_info
/// @description Returns bottom contact data for flat, one-way, moving, or slope ground.
/// @param {Struct} _actor Actor controller to probe.
/// @returns {Struct} Bottom contact info, inactive when no ground is touched.
function actor_collision_get_ground_info(_actor) {
    if (!is_struct(_actor)) {
        return new ActorContactInfo();
    }

    var _solid_contact = actor_collision_get_contact_info(_actor, ActorCollisionSide.BOTTOM);
    if (_solid_contact.active) {
        return _solid_contact;
    }

    var _one_way_contact = actor_collision_get_one_way_contact_info(_actor);
    if (_one_way_contact.active) {
        return _one_way_contact;
    }

    return actor_collision_get_slope_contact_info(_actor);
}

/// @function actor_collision_get_wall_info
/// @description Returns side contact data for a requested wall direction.
/// @param {Struct} _actor Actor controller to probe.
/// @param {Real} _direction Negative probes left, positive probes right, zero returns any wall contact.
/// @returns {Struct} Wall contact info, inactive when no wall is touched.
function actor_collision_get_wall_info(_actor, _direction) {
    if (!is_struct(_actor)) {
        return new ActorContactInfo();
    }

    if (_direction < 0) {
        return actor_collision_get_contact_info(_actor, ActorCollisionSide.LEFT);
    }

    if (_direction > 0) {
        return actor_collision_get_contact_info(_actor, ActorCollisionSide.RIGHT);
    }

    var _left = actor_collision_get_contact_info(_actor, ActorCollisionSide.LEFT);
    if (_left.active) {
        return _left;
    }

    return actor_collision_get_contact_info(_actor, ActorCollisionSide.RIGHT);
}

/// @function actor_collision_can_stand
/// @description Checks whether the actor's standing collision box is clear at its current center.
/// @param {Struct} _actor Actor controller to test.
/// @returns {Bool} True when the standing collision box does not overlap a solid.
function actor_collision_can_stand(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    return !actor_collision_place_solid(_actor, _actor.x, _actor.y);
}

/// @function actor_collision_try_unstuck
/// @description Attempts to move a slightly embedded actor to a nearby clear position.
/// @param {Struct} _actor Actor controller to resolve.
/// @returns {Bool} True when the actor is clear or was moved to a clear position.
function actor_collision_try_unstuck(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    _actor.collision_unstuck_offset_x = 0;
    _actor.collision_unstuck_offset_y = 0;

    if (!actor_collision_place_solid(_actor, _actor.x, _actor.y)) {
        _actor.collision_unstuck_succeeded = true;
        return true;
    }

    var _origin_x = _actor.x;
    var _origin_y = _actor.y;

    for (var _distance = 1; _distance <= ACTOR_UNSTUCK_MAX_DISTANCE; _distance += 1) {
        for (var _dy = -_distance; _dy <= _distance; _dy += 1) {
            for (var _dx = -_distance; _dx <= _distance; _dx += 1) {
                if ((abs(_dx) != _distance) && (abs(_dy) != _distance)) {
                    continue;
                }

                var _test_x = _origin_x + _dx;
                var _test_y = _origin_y + _dy;

                if (!actor_collision_place_solid(_actor, _test_x, _test_y)) {
                    _actor.x = _test_x;
                    _actor.y = _test_y;
                    _actor.collision_unstuck_succeeded = true;
                    _actor.collision_unstuck_offset_x = _dx;
                    _actor.collision_unstuck_offset_y = _dy;
                    return true;
                }
            }
        }
    }

    _actor.collision_unstuck_succeeded = false;
    return false;
}

/// @function actor_collision_refresh_contacts
/// @description Rebuilds all contact fields from post-move collision probes.
/// @param {Struct} _actor Actor controller whose contacts should refresh.
/// @returns {Undefined} No return value.
function actor_collision_refresh_contacts(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    _actor.contact_bottom = actor_collision_get_ground_info(_actor);
    _actor.contact_top = actor_collision_get_contact_info(_actor, ActorCollisionSide.TOP);
    _actor.contact_left = actor_collision_get_contact_info(_actor, ActorCollisionSide.LEFT);
    _actor.contact_right = actor_collision_get_contact_info(_actor, ActorCollisionSide.RIGHT);

    _actor.is_physically_grounded = _actor.contact_bottom.active;
    _actor.is_grounded = _actor.is_physically_grounded;
    _actor.ceiling_contact = _actor.contact_top.active;
    _actor.wall_left = _actor.contact_left.active;
    _actor.wall_right = _actor.contact_right.active;

    _actor.ground_object = _actor.contact_bottom.active ? _actor.contact_bottom.object_id : noone;
    _actor.wall_object = noone;
    if (_actor.contact_left.active) {
        _actor.wall_object = _actor.contact_left.object_id;
    } else if (_actor.contact_right.active) {
        _actor.wall_object = _actor.contact_right.object_id;
    }

    _actor.ground_normal_x = _actor.contact_bottom.active ? _actor.contact_bottom.normal_x : 0;
    _actor.ground_normal_y = _actor.contact_bottom.active ? _actor.contact_bottom.normal_y : -1;
    _actor.ground_angle = 0;
    _actor.ground_tangent_x = 1;
    _actor.ground_tangent_y = 0;
    _actor.ground_slope_walkable = true;

    if (_actor.contact_bottom.active && actor_collision_is_rotated_slope(_actor.contact_bottom.object_id)) {
        var _slope = actor_collision_get_slope_info(_actor, _actor.x, _actor.y);
        if (_slope.active) {
            _actor.ground_angle = _slope.angle;
            _actor.ground_tangent_x = _slope.tangent_x;
            _actor.ground_tangent_y = _slope.tangent_y;
            _actor.ground_slope_walkable = _slope.walkable;
        }
    }

    if (_actor.contact_left.active) {
        _actor.wall_normal_x = _actor.contact_left.normal_x;
        _actor.wall_normal_y = _actor.contact_left.normal_y;
    } else if (_actor.contact_right.active) {
        _actor.wall_normal_x = _actor.contact_right.normal_x;
        _actor.wall_normal_y = _actor.contact_right.normal_y;
    } else {
        _actor.wall_normal_x = 0;
        _actor.wall_normal_y = 0;
    }

    _actor.surface_info = _actor.contact_bottom.active ? _actor.contact_bottom.surface : new ActorSurfaceInfo();

    _actor.platform_previous_object = _actor.platform_object;
    if (_actor.contact_bottom.active && actor_collision_is_moving_platform(_actor.contact_bottom.object_id)) {
        _actor.platform_object = _actor.contact_bottom.object_id;
        _actor.platform_velocity_x = actor_surface_read_optional(_actor.platform_object, "platform_velocity_x", 0);
        _actor.platform_velocity_y = actor_surface_read_optional(_actor.platform_object, "platform_velocity_y", 0);
    } else {
        _actor.platform_object = noone;
        _actor.platform_velocity_x = 0;
        _actor.platform_velocity_y = 0;
    }
}
