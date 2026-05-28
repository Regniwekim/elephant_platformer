/// @description External force helpers for layered actor velocity.

/// @function actor_force_read_optional
/// @description Reads an optional field from a force struct.
/// @param {Struct} _force Force struct to inspect.
/// @param {String} _field_name Field name to read.
/// @param {Any} _default_value Value returned when the field is absent.
/// @returns {Any} Field value or the provided default.
function actor_force_read_optional(_force, _field_name, _default_value) {
    if (!is_struct(_force) || !variable_struct_exists(_force, _field_name)) {
        return _default_value;
    }

    return variable_struct_get(_force, _field_name);
}

/// @function actor_force_normalize
/// @description Completes and clamps force fields so force updates can use them safely.
/// @param {Struct} _force Force struct to normalize.
/// @returns {Struct} Normalized force, or noone when the input is invalid.
function actor_force_normalize(_force) {
    if (!is_struct(_force)) {
        return noone;
    }

    _force.type = actor_force_read_optional(_force, "type", ActorForceType.ADDITIVE);
    if ((_force.type < ActorForceType.ADDITIVE) || (_force.type > ActorForceType.KNOCKBACK)) {
        _force.type = ActorForceType.ADDITIVE;
    }

    _force.x = actor_force_read_optional(_force, "x", 0);
    _force.y = actor_force_read_optional(_force, "y", 0);
    _force.duration_frames = max(1, floor(actor_force_read_optional(_force, "duration_frames", 1)));
    _force.elapsed_frames = max(0, floor(actor_force_read_optional(_force, "elapsed_frames", 0)));
    _force.damping = clamp(actor_force_read_optional(_force, "damping", 1), 0, 1);
    _force.control_reduction = clamp(actor_force_read_optional(_force, "control_reduction", 0), 0, 1);
    _force.source_id = actor_force_read_optional(_force, "source_id", noone);
    _force.metadata = actor_force_read_optional(_force, "metadata", noone);
    _force.active = actor_force_read_optional(_force, "active", true);

    return _force;
}

/// @function actor_force_create
/// @description Creates an active external force for an actor controller.
/// @param {Real} _type ActorForceType enum value.
/// @param {Real} _x Horizontal external velocity contribution.
/// @param {Real} _y Vertical external velocity contribution.
/// @param {Real} _duration_frames Number of frames the force contributes.
/// @param {Real} _damping Per-frame velocity retention multiplier from 0 to 1.
/// @param {Real} _control_reduction Input acceleration reduction from 0 to 1.
/// @param {Any} _source_id Optional source id, usually an instance id.
/// @param {Any} _metadata Optional caller-owned metadata.
/// @returns {Struct} Active ActorForce data.
function actor_force_create(_type, _x, _y, _duration_frames, _damping, _control_reduction, _source_id, _metadata) {
    var _force = new ActorForce();

    _force.type = is_undefined(_type) ? ActorForceType.ADDITIVE : _type;
    _force.x = is_undefined(_x) ? 0 : _x;
    _force.y = is_undefined(_y) ? 0 : _y;
    _force.duration_frames = is_undefined(_duration_frames) ? 1 : _duration_frames;
    _force.elapsed_frames = 0;
    _force.damping = is_undefined(_damping) ? 1 : _damping;
    _force.control_reduction = is_undefined(_control_reduction) ? 0 : _control_reduction;
    _force.source_id = is_undefined(_source_id) ? noone : _source_id;
    _force.metadata = is_undefined(_metadata) ? noone : _metadata;
    _force.active = true;

    return actor_force_normalize(_force);
}

/// @function actor_controller_add_force
/// @description Adds an active force to an actor's external force stack.
/// @param {Struct} _actor Actor controller receiving the force.
/// @param {Struct} _force Force data to add.
/// @returns {Struct} Added force, or noone when the inputs are invalid.
function actor_controller_add_force(_actor, _force) {
    if (!is_struct(_actor)) {
        return noone;
    }

    _force = actor_force_normalize(_force);
    if (!is_struct(_force)) {
        return noone;
    }

    _force.active = true;

    if (!is_array(_actor.active_forces)) {
        _actor.active_forces = [];
    }

    array_push(_actor.active_forces, _force);
    _actor.active_force_count = array_length(_actor.active_forces);

    return _force;
}

/// @function actor_controller_clear_forces
/// @description Removes all external forces and clears derived external velocity state.
/// @param {Struct} _actor Actor controller to clear.
/// @returns {Undefined} No return value.
function actor_controller_clear_forces(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    _actor.active_forces = [];
    _actor.active_force_count = 0;
    _actor.external_hsp = 0;
    _actor.external_vsp = 0;
    _actor.external_control_reduction = 0;
    actor_controller_update_total_velocity(_actor);
}

/// @function actor_controller_update_forces
/// @description Filters inactive or expired forces before external velocity is applied.
/// @param {Struct} _actor Actor controller whose force stack should update.
/// @returns {Real} Active force count after filtering.
function actor_controller_update_forces(_actor) {
    if (!is_struct(_actor)) {
        return 0;
    }

    var _forces = is_array(_actor.active_forces) ? _actor.active_forces : [];
    var _active = [];

    for (var _i = 0; _i < array_length(_forces); _i++) {
        var _force = actor_force_normalize(_forces[_i]);

        if (!is_struct(_force) || !_force.active || (_force.elapsed_frames >= _force.duration_frames)) {
            continue;
        }

        array_push(_active, _force);
    }

    _actor.active_forces = _active;
    _actor.active_force_count = array_length(_active);
    _actor.external_control_reduction = 0;

    return _actor.active_force_count;
}

/// @function actor_controller_apply_external_forces
/// @description Resolves active forces into external velocity and ages force lifetimes by one frame.
/// @param {Struct} _actor Actor controller whose external velocity should update.
/// @returns {Undefined} No return value.
function actor_controller_apply_external_forces(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    actor_controller_update_forces(_actor);

    var _add_x = 0;
    var _add_y = 0;
    var _override_x = 0;
    var _override_y = 0;
    var _has_override = false;
    var _control_reduction = 0;

    for (var _i = 0; _i < _actor.active_force_count; _i++) {
        var _force = _actor.active_forces[_i];

        switch (_force.type) {
            case ActorForceType.OVERRIDE:
                _override_x = _force.x;
                _override_y = _force.y;
                _has_override = true;
                break;

            case ActorForceType.ADDITIVE:
            case ActorForceType.IMPULSE:
            case ActorForceType.CONTINUOUS:
            case ActorForceType.PLATFORM_CARRY:
            case ActorForceType.KNOCKBACK:
                _add_x += _force.x;
                _add_y += _force.y;
                break;
        }

        _control_reduction = max(_control_reduction, _force.control_reduction);
    }

    if (_has_override) {
        _actor.external_hsp = _override_x;
        _actor.external_vsp = _override_y;
    } else {
        _actor.external_hsp = _add_x;
        _actor.external_vsp = _add_y;
    }

    _actor.external_control_reduction = clamp(_control_reduction, 0, 1);
    actor_controller_age_forces(_actor);
    actor_controller_update_total_velocity(_actor);
}

/// @function actor_controller_age_forces
/// @description Advances force lifetimes and applies force-local damping after the current frame contribution.
/// @param {Struct} _actor Actor controller whose active forces should age.
/// @returns {Undefined} No return value.
function actor_controller_age_forces(_actor) {
    if (!is_struct(_actor) || !is_array(_actor.active_forces)) {
        return;
    }

    var _remaining = [];

    for (var _i = 0; _i < array_length(_actor.active_forces); _i++) {
        var _force = _actor.active_forces[_i];

        if (!is_struct(_force)) {
            continue;
        }

        _force.elapsed_frames += 1;
        if (_force.damping < 1) {
            _force.x *= _force.damping;
            _force.y *= _force.damping;
        }

        if (_force.active && (_force.elapsed_frames < _force.duration_frames)) {
            array_push(_remaining, _force);
        } else {
            _force.active = false;
        }
    }

    _actor.active_forces = _remaining;
    _actor.active_force_count = array_length(_remaining);
}

/// @function actor_controller_get_external_control_scale
/// @description Gets the current input acceleration scale after external control reduction.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Real} Control scale from 0 to 1.
function actor_controller_get_external_control_scale(_actor) {
    if (!is_struct(_actor)) {
        return 1;
    }

    return 1 - clamp(_actor.external_control_reduction, 0, 1);
}

/// @function actor_controller_update_total_velocity
/// @description Combines controlled and external velocity and clamps the total to the hard safety cap.
/// @param {Struct} _actor Actor controller whose total velocity should update.
/// @returns {Undefined} No return value.
function actor_controller_update_total_velocity(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    var _total_x = _actor.hsp + _actor.external_hsp;
    var _total_y = _actor.vsp + _actor.external_vsp;
    var _cap = max(0, ACTOR_HARD_SPEED_CAP);
    var _speed = point_distance(0, 0, _total_x, _total_y);

    if ((_cap > 0) && (_speed > _cap)) {
        var _scale = _cap / _speed;
        var _clamped_x = _total_x * _scale;
        var _clamped_y = _total_y * _scale;
        var _has_external = (abs(_actor.external_hsp) > ACTOR_EPSILON) || (abs(_actor.external_vsp) > ACTOR_EPSILON);

        if (_has_external) {
            _actor.external_hsp = _clamped_x - _actor.hsp;
            _actor.external_vsp = _clamped_y - _actor.vsp;
        } else {
            _actor.hsp = _clamped_x;
            _actor.vsp = _clamped_y;
        }

        _total_x = _clamped_x;
        _total_y = _clamped_y;
    }

    _actor.total_hsp = _total_x;
    _actor.total_vsp = _total_y;
}

/// @function actor_controller_clear_external_axis
/// @description Clears external velocity and active force vectors for one collision-blocked axis.
/// @param {Struct} _actor Actor controller whose force axis should clear.
/// @param {Bool} _clear_x True to clear horizontal force, false to clear vertical force.
/// @returns {Undefined} No return value.
function actor_controller_clear_external_axis(_actor, _clear_x) {
    if (!is_struct(_actor)) {
        return;
    }

    if (_clear_x) {
        _actor.external_hsp = 0;
    } else {
        _actor.external_vsp = 0;
    }

    if (is_array(_actor.active_forces)) {
        for (var _i = 0; _i < array_length(_actor.active_forces); _i++) {
            var _force = _actor.active_forces[_i];

            if (!is_struct(_force)) {
                continue;
            }

            if (_clear_x) {
                _force.x = 0;
            } else {
                _force.y = 0;
            }
        }
    }

    actor_controller_update_total_velocity(_actor);
}
