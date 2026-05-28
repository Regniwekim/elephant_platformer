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
/// @description Finds the first obj_solid whose rectangle overlaps the provided rectangle.
/// @param {Struct} _rect Rectangle to test.
/// @returns {Id.Instance} Solid instance id, or noone when clear.
function actor_collision_find_solid_hit_for_rect(_rect) {
    var _count = instance_number(obj_solid);

    for (var _i = 0; _i < _count; _i++) {
        var _solid = instance_find(obj_solid, _i);
        var _solid_rect = actor_collision_get_solid_rect(_solid);

        if (actor_collision_rects_overlap(_rect, _solid_rect)) {
            return _solid;
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
    return actor_collision_find_solid_hit_for_rect(_rect);
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

        if (actor_collision_place_solid(_actor, _test_x, _test_y)) {
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

        if (!actor_collision_place_solid(_actor, _actor.x + _step, _actor.y)) {
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

        if (!actor_collision_place_solid(_actor, _actor.x, _actor.y + _step)) {
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

    var _x_result = actor_collision_move_x(_actor, _move_x);
    var _y_result = actor_collision_move_y(_actor, _move_y);

    _result.moved_x = _x_result.moved_x;
    _result.moved_y = _y_result.moved_y;
    _result.blocked_x = _x_result.blocked_x;
    _result.blocked_y = _y_result.blocked_y;
    _result.iterations = _x_result.iterations + _y_result.iterations;

    _actor.collision_blocked_x = _result.blocked_x;
    _actor.collision_blocked_y = _result.blocked_y;

    actor_collision_refresh_contacts(_actor);

    return _result;
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
    _contact.surface = new ActorSurfaceInfo();

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
    var _solid = actor_collision_find_solid_hit_for_rect(_probe_rect);

    if (_solid == noone) {
        return new ActorContactInfo();
    }

    var _actor_rect = actor_collision_get_actor_rect(_actor, _actor.x, _actor.y);
    var _solid_rect = actor_collision_get_solid_rect(_solid);
    var _depth = actor_collision_get_contact_depth(_actor_rect, _solid_rect, _side);

    return actor_collision_make_contact(_side, _solid, _normal_x, _normal_y, _depth);
}

/// @function actor_collision_get_ground_info
/// @description Returns bottom contact data for flat solid ground.
/// @param {Struct} _actor Actor controller to probe.
/// @returns {Struct} Bottom contact info, inactive when no ground is touched.
function actor_collision_get_ground_info(_actor) {
    if (!is_struct(_actor)) {
        return new ActorContactInfo();
    }

    return actor_collision_get_contact_info(_actor, ActorCollisionSide.BOTTOM);
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
}
