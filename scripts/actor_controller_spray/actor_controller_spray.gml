/// @description Water spray resource, mode, refill, and recoil helpers.

/// @function actor_controller_is_continuous_spray_mode
/// @description Reports whether a spray mode is supported by the guide 6 continuous spray system.
/// @param {Real} _mode ActorSprayMode enum value.
/// @returns {Bool} True when the mode is wide or focused.
function actor_controller_is_continuous_spray_mode(_mode) {
    return (_mode == ActorSprayMode.WIDE) || (_mode == ActorSprayMode.FOCUSED);
}

/// @function actor_controller_has_spray_ability
/// @description Reports whether an actor's stats allow continuous spray.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when the spray ability flag is present.
function actor_controller_has_spray_ability(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    var _abilities = actor_stats_get_optional(_actor.stats, "abilities", ACTOR_ABILITY_NONE);

    return (_abilities & ACTOR_ABILITY_SPRAY) != 0;
}

/// @function actor_controller_has_charged_spray_ability
/// @description Reports whether an actor's stats allow charged spray releases.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when both spray and charged spray ability flags are present.
function actor_controller_has_charged_spray_ability(_actor) {
    if (!actor_controller_has_spray_ability(_actor)) {
        return false;
    }

    var _abilities = actor_stats_get_optional(_actor.stats, "abilities", ACTOR_ABILITY_NONE);

    return (_abilities & ACTOR_ABILITY_CHARGE_SPRAY) != 0;
}

/// @function actor_controller_get_spray_stats
/// @description Gets mode-specific water cost and recoil tuning for continuous spray.
/// @param {Struct} _actor Actor controller containing stats.
/// @param {Real} _mode ActorSprayMode enum value.
/// @returns {Struct} Spray tuning values for the requested mode.
function actor_controller_get_spray_stats(_actor, _mode) {
    var _spray_stats = {};

    _spray_stats.mode = _mode;
    _spray_stats.cost = 0;
    _spray_stats.recoil_strength = 0;
    _spray_stats.duration_frames = ACTOR_SPRAY_RECOIL_DURATION_FRAMES_DEFAULT;
    _spray_stats.damping = ACTOR_SPRAY_RECOIL_DAMPING_DEFAULT;
    _spray_stats.control_reduction = ACTOR_SPRAY_RECOIL_CONTROL_REDUCTION_DEFAULT;

    if (!is_struct(_actor)) {
        return _spray_stats;
    }

    switch (_mode) {
        case ActorSprayMode.WIDE:
            _spray_stats.cost = max(0, actor_stats_get_optional(_actor.stats, "spray_wide_cost", ACTOR_SPRAY_WIDE_COST_DEFAULT));
            _spray_stats.recoil_strength = max(0, actor_stats_get_optional(_actor.stats, "spray_wide_recoil", ACTOR_SPRAY_WIDE_RECOIL_DEFAULT));
            break;

        case ActorSprayMode.FOCUSED:
            _spray_stats.cost = max(0, actor_stats_get_optional(_actor.stats, "spray_focused_cost", ACTOR_SPRAY_FOCUSED_COST_DEFAULT));
            _spray_stats.recoil_strength = max(0, actor_stats_get_optional(_actor.stats, "spray_focused_recoil", ACTOR_SPRAY_FOCUSED_RECOIL_DEFAULT));
            break;
    }

    _spray_stats.duration_frames = max(1, floor(actor_stats_get_optional(_actor.stats, "spray_recoil_duration_frames", ACTOR_SPRAY_RECOIL_DURATION_FRAMES_DEFAULT)));
    _spray_stats.damping = clamp(actor_stats_get_optional(_actor.stats, "spray_recoil_damping", ACTOR_SPRAY_RECOIL_DAMPING_DEFAULT), 0, 1);
    _spray_stats.control_reduction = clamp(actor_stats_get_optional(_actor.stats, "spray_recoil_control_reduction", ACTOR_SPRAY_RECOIL_CONTROL_REDUCTION_DEFAULT), 0, 1);

    return _spray_stats;
}

/// @function actor_controller_set_spray_mode
/// @description Sets the selected continuous spray mode and records a nozzle change event.
/// @param {Struct} _actor Actor controller to update.
/// @param {Real} _mode ActorSprayMode enum value.
/// @returns {Bool} True when the requested mode is usable.
function actor_controller_set_spray_mode(_actor, _mode) {
    if (!is_struct(_actor) || !actor_controller_has_spray_ability(_actor)) {
        return false;
    }

    if (!actor_controller_is_continuous_spray_mode(_mode)) {
        return false;
    }

    if (_actor.spray_mode == _mode) {
        return true;
    }

    _actor.spray_mode = _mode;

    var _event = actor_controller_record_event(_actor, ActorControllerEvent.NOZZLE_CHANGE);
    if (is_struct(_event)) {
        _event.spray_mode = _mode;
    }

    return true;
}

/// @function actor_controller_update_spray_mode_from_input
/// @description Applies nozzle input commands to toggle between wide and focused continuous spray modes.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when a mode command was handled.
function actor_controller_update_spray_mode_from_input(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.input)) {
        return false;
    }

    var _input = _actor.input;
    var _has_command = _input.nozzle_next_pressed
        || _input.nozzle_prev_pressed
        || (abs(_input.nozzle_value_delta) > ACTOR_EPSILON);

    if (!_has_command) {
        return false;
    }

    var _target_mode = ActorSprayMode.WIDE;
    if (_actor.spray_mode == ActorSprayMode.WIDE) {
        _target_mode = ActorSprayMode.FOCUSED;
    } else if (_actor.spray_mode == ActorSprayMode.FOCUSED) {
        _target_mode = ActorSprayMode.WIDE;
    }

    return actor_controller_set_spray_mode(_actor, _target_mode);
}

/// @function actor_controller_can_spray
/// @description Checks ability, selected mode, and water availability for starting spray.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when spray can start this frame.
function actor_controller_can_spray(_actor) {
    if (!is_struct(_actor) || !actor_controller_has_spray_ability(_actor)) {
        return false;
    }

    if (!actor_controller_is_continuous_spray_mode(_actor.spray_mode)) {
        return false;
    }

    return _actor.water_current > ACTOR_EPSILON;
}

/// @function actor_controller_start_spray
/// @description Starts continuous spray when the actor has ability, water, and a valid selected mode.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when spray is active after the call.
function actor_controller_start_spray(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    if (!actor_controller_has_spray_ability(_actor)) {
        return false;
    }

    if (!actor_controller_is_continuous_spray_mode(_actor.spray_mode)) {
        _actor.spray_mode = ActorSprayMode.WIDE;
    }

    if (!actor_controller_can_spray(_actor)) {
        return false;
    }

    if (_actor.spray_active) {
        return true;
    }

    _actor.spray_active = true;
    _actor.spray_empty_grace_timer = actor_controller_get_timer_stat(_actor, "empty_spray_grace_frames", ACTOR_EMPTY_SPRAY_GRACE_FRAMES_DEFAULT);

    var _event = actor_controller_record_event(_actor, ActorControllerEvent.SPRAY_START);
    if (is_struct(_event)) {
        _event.spray_mode = _actor.spray_mode;
    }

    return true;
}

/// @function actor_controller_stop_spray
/// @description Stops continuous spray and clears one-frame recoil state.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when an active spray was stopped.
function actor_controller_stop_spray(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    _actor.spray_recoil_x = 0;
    _actor.spray_recoil_y = 0;
    _actor.spray_empty_grace_timer = 0;

    if (!_actor.spray_active) {
        return false;
    }

    _actor.spray_active = false;

    var _event = actor_controller_record_event(_actor, ActorControllerEvent.SPRAY_STOP);
    if (is_struct(_event)) {
        _event.spray_mode = _actor.spray_mode;
    }

    return true;
}

/// @function actor_controller_apply_spray_cost
/// @description Drains water for the selected spray mode and enforces empty-spray grace.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when active spray may continue this frame.
function actor_controller_apply_spray_cost(_actor) {
    if (!is_struct(_actor) || !_actor.spray_active) {
        return false;
    }

    var _spray_stats = actor_controller_get_spray_stats(_actor, _actor.spray_mode);
    if (_spray_stats.cost <= ACTOR_EPSILON) {
        return true;
    }

    if (_actor.water_current > ACTOR_EPSILON) {
        _actor.water_current = max(0, _actor.water_current - _spray_stats.cost);

        if (_actor.water_current > ACTOR_EPSILON) {
            _actor.spray_empty_grace_timer = actor_controller_get_timer_stat(_actor, "empty_spray_grace_frames", ACTOR_EMPTY_SPRAY_GRACE_FRAMES_DEFAULT);
            return true;
        }

        _actor.spray_empty_grace_timer = actor_controller_get_timer_stat(_actor, "empty_spray_grace_frames", ACTOR_EMPTY_SPRAY_GRACE_FRAMES_DEFAULT);
        return true;
    }

    if (_actor.spray_empty_grace_timer > 0) {
        _actor.spray_empty_grace_timer -= 1;
        return true;
    }

    return false;
}

/// @function actor_controller_filter_grounded_spray_lift
/// @description Removes the away-from-ground component from spray recoil while preserving tangent movement.
/// @param {Struct} _actor Actor controller receiving recoil.
/// @param {Real} _recoil_x Raw horizontal recoil.
/// @param {Real} _recoil_y Raw vertical recoil.
/// @returns {Struct} Filtered recoil with x and y fields.
function actor_controller_filter_grounded_spray_lift(_actor, _recoil_x, _recoil_y) {
    var _filtered = {
        x: _recoil_x,
        y: _recoil_y
    };

    if (!is_struct(_actor) || !_actor.is_physically_grounded) {
        return _filtered;
    }

    var _normal_x = _actor.ground_normal_x;
    var _normal_y = _actor.ground_normal_y;
    var _normal_length = point_distance(0, 0, _normal_x, _normal_y);

    if ((_normal_length <= ACTOR_EPSILON) || (_normal_y > ACTOR_EPSILON)) {
        _normal_x = 0;
        _normal_y = -1;
    } else {
        _normal_x /= _normal_length;
        _normal_y /= _normal_length;
    }

    var _away_from_ground = (_filtered.x * _normal_x) + (_filtered.y * _normal_y);
    if (_away_from_ground > ACTOR_EPSILON) {
        _filtered.x -= _normal_x * _away_from_ground;
        _filtered.y -= _normal_y * _away_from_ground;
    }

    if (abs(_filtered.x) <= ACTOR_EPSILON) {
        _filtered.x = 0;
    }
    if (abs(_filtered.y) <= ACTOR_EPSILON) {
        _filtered.y = 0;
    }

    return _filtered;
}

/// @function actor_controller_apply_spray_recoil
/// @description Adds continuous spray recoil through the external force stack.
/// @param {Struct} _actor Actor controller receiving recoil.
/// @returns {Struct} Added force, or noone when no recoil is applied.
function actor_controller_apply_spray_recoil(_actor) {
    if (!is_struct(_actor) || !_actor.spray_active) {
        return noone;
    }

    var _spray_stats = actor_controller_get_spray_stats(_actor, _actor.spray_mode);
    var _surface_recoil = actor_controller_get_surface_multiplier(_actor, "recoil_multiplier");
    var _strength = _spray_stats.recoil_strength * _surface_recoil;

    var _filtered_recoil = actor_controller_filter_grounded_spray_lift(
        _actor,
        -_actor.spray_aim_x * _strength,
        -_actor.spray_aim_y * _strength
    );

    _actor.spray_recoil_x = _filtered_recoil.x;
    _actor.spray_recoil_y = _filtered_recoil.y;

    if (point_distance(0, 0, _actor.spray_recoil_x, _actor.spray_recoil_y) <= ACTOR_EPSILON) {
        return noone;
    }

    var _source_id = is_struct(_actor.input) ? _actor.input.source_id : noone;
    var _metadata = {
        spray_mode: _actor.spray_mode
    };

    var _force = actor_force_create(
        ActorForceType.CONTINUOUS,
        _actor.spray_recoil_x,
        _actor.spray_recoil_y,
        _spray_stats.duration_frames,
        _spray_stats.damping,
        _spray_stats.control_reduction,
        _source_id,
        _metadata
    );

    return actor_controller_add_force(_actor, _force);
}

/// @function actor_controller_update_charge_flags
/// @description Refreshes normalized charge amount and readiness flags from charge timer state.
/// @param {Struct} _actor Actor controller with charge fields.
/// @returns {Real} Normalized charge amount after refresh.
function actor_controller_update_charge_flags(_actor) {
    if (!is_struct(_actor)) {
        return 0;
    }

    var _build_frames = max(1, floor(actor_stats_get_optional(_actor.stats, "charge_build_frames", ACTOR_CHARGE_BUILD_FRAMES_DEFAULT)));
    var _threshold = clamp(actor_stats_get_optional(_actor.stats, "ground_launch_charge_min", ACTOR_GROUND_LAUNCH_CHARGE_MIN_DEFAULT), 0, 1);

    _actor.charge_timer = clamp(floor(_actor.charge_timer), 0, _build_frames);
    _actor.charge_amount = clamp(_actor.charge_timer / _build_frames, 0, 1);
    _actor.charge_ready = (_actor.charge_amount > ACTOR_EPSILON) && (_actor.charge_amount >= _threshold - ACTOR_EPSILON);
    _actor.charge_overready = _actor.charge_amount >= 1 - ACTOR_EPSILON;

    return _actor.charge_amount;
}

/// @function actor_controller_reset_charge
/// @description Clears charged spray buildup state.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_reset_charge(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    _actor.charge_timer = 0;
    _actor.charge_amount = 0;
    _actor.charge_ready = false;
    _actor.charge_overready = false;
}

/// @function actor_controller_can_ground_launch_from_charge
/// @description Reports whether the current charge amount meets the grounded launch threshold.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when the actor is physically grounded and charge is at or above threshold.
function actor_controller_can_ground_launch_from_charge(_actor) {
    if (!is_struct(_actor) || !_actor.is_physically_grounded) {
        return false;
    }

    var _threshold = clamp(actor_stats_get_optional(_actor.stats, "ground_launch_charge_min", ACTOR_GROUND_LAUNCH_CHARGE_MIN_DEFAULT), 0, 1);

    return (_actor.charge_amount > ACTOR_EPSILON) && (_actor.charge_amount >= _threshold - ACTOR_EPSILON);
}

/// @function actor_controller_can_release_charged_shot
/// @description Checks ability, built charge, and water cost for a charged spray release.
/// @param {Struct} _actor Actor controller to inspect.
/// @returns {Bool} True when a charged shot may release this frame.
function actor_controller_can_release_charged_shot(_actor) {
    if (!is_struct(_actor) || !actor_controller_has_charged_spray_ability(_actor)) {
        return false;
    }

    if (_actor.charge_amount <= ACTOR_EPSILON) {
        return false;
    }

    var _cost = max(0, actor_stats_get_optional(_actor.stats, "charged_shot_cost", ACTOR_CHARGED_SHOT_COST_DEFAULT));

    return _actor.water_current + ACTOR_EPSILON >= _cost;
}

/// @function actor_controller_release_charged_shot
/// @description Releases a charged spray shot as an impulse and applies grounded launch threshold rules.
/// @param {Struct} _actor Actor controller releasing the shot.
/// @returns {Bool} True when water was spent and release event was recorded.
function actor_controller_release_charged_shot(_actor) {
    if (!is_struct(_actor)) {
        return false;
    }

    if (!actor_controller_has_charged_spray_ability(_actor)) {
        actor_controller_reset_charge(_actor);
        return false;
    }

    actor_controller_update_charge_flags(_actor);

    var _charge_amount = clamp(_actor.charge_amount, 0, 1);
    if (_charge_amount <= ACTOR_EPSILON) {
        actor_controller_reset_charge(_actor);
        return false;
    }

    var _cost = max(0, actor_stats_get_optional(_actor.stats, "charged_shot_cost", ACTOR_CHARGED_SHOT_COST_DEFAULT));
    if (!actor_controller_can_release_charged_shot(_actor)) {
        var _dry_event = actor_controller_record_event(_actor, ActorControllerEvent.NO_WATER);
        if (is_struct(_dry_event)) {
            _dry_event.spray_mode = ActorSprayMode.CHARGED;
            _dry_event.charge_amount = _charge_amount;
            _dry_event.water_cost = _cost;
            _dry_event.water_current = _actor.water_current;
        }

        actor_controller_reset_charge(_actor);
        return false;
    }

    _actor.water_current = max(0, _actor.water_current - _cost);

    var _impulse = max(0, actor_stats_get_optional(_actor.stats, "charged_shot_impulse", ACTOR_CHARGED_SHOT_IMPULSE_DEFAULT)) * _charge_amount;
    var _force_x = -_actor.spray_aim_x * _impulse;
    var _force_y = -_actor.spray_aim_y * _impulse;
    var _ground_launch_allowed = actor_controller_can_ground_launch_from_charge(_actor);
    var _ground_launch_applied = false;

    if (_actor.is_physically_grounded && !_ground_launch_allowed) {
        var _filtered_force = actor_controller_filter_grounded_spray_lift(_actor, _force_x, _force_y);
        _force_x = _filtered_force.x;
        _force_y = _filtered_force.y;
    } else if (_actor.is_physically_grounded) {
        var _normal_x = _actor.ground_normal_x;
        var _normal_y = _actor.ground_normal_y;
        var _normal_length = point_distance(0, 0, _normal_x, _normal_y);

        if ((_normal_length <= ACTOR_EPSILON) || (_normal_y > ACTOR_EPSILON)) {
            _normal_x = 0;
            _normal_y = -1;
        } else {
            _normal_x /= _normal_length;
            _normal_y /= _normal_length;
        }

        _ground_launch_applied = ((_force_x * _normal_x) + (_force_y * _normal_y)) > ACTOR_EPSILON;

        if (_ground_launch_applied) {
            _actor.is_grounded = false;
            _actor.is_physically_grounded = false;
            _actor.ground_object = noone;
            _actor.platform_object = noone;
            _actor.platform_inherit_object = noone;
            _actor.platform_inherit_velocity_x = 0;
            _actor.platform_inherit_velocity_y = 0;
            _actor.contact_bottom = actor_collision_reset_contact(_actor.contact_bottom);
            actor_controller_set_state(_actor, ActorMoveState.AIRBORNE);
        }
    }

    _actor.spray_recoil_x = _force_x;
    _actor.spray_recoil_y = _force_y;

    if (point_distance(0, 0, _force_x, _force_y) > ACTOR_EPSILON) {
        var _duration = max(1, floor(actor_stats_get_optional(_actor.stats, "charged_shot_duration_frames", ACTOR_CHARGED_SHOT_DURATION_FRAMES_DEFAULT)));
        var _damping = clamp(actor_stats_get_optional(_actor.stats, "charged_shot_damping", ACTOR_CHARGED_SHOT_DAMPING_DEFAULT), 0, 1);
        var _control_reduction = clamp(actor_stats_get_optional(_actor.stats, "charged_shot_control_reduction", ACTOR_CHARGED_SHOT_CONTROL_REDUCTION_DEFAULT), 0, 1);
        var _source_id = is_struct(_actor.input) ? _actor.input.source_id : noone;
        var _metadata = {
            spray_mode: ActorSprayMode.CHARGED,
            charge_amount: _charge_amount,
            ground_launch_allowed: _ground_launch_allowed,
            ground_launch_applied: _ground_launch_applied
        };

        actor_controller_add_force(_actor, actor_force_create(
            ActorForceType.IMPULSE,
            _force_x,
            _force_y,
            _duration,
            _damping,
            _control_reduction,
            _source_id,
            _metadata
        ));
    }

    var _event = actor_controller_record_event(_actor, ActorControllerEvent.CHARGE_RELEASE);
    if (is_struct(_event)) {
        _event.spray_mode = ActorSprayMode.CHARGED;
        _event.charge_amount = _charge_amount;
        _event.water_cost = _cost;
        _event.impulse_x = _force_x;
        _event.impulse_y = _force_y;
        _event.ground_launch_allowed = _ground_launch_allowed;
        _event.ground_launch_applied = _ground_launch_applied;
    }

    actor_controller_reset_charge(_actor);
    return true;
}

/// @function actor_controller_update_charge
/// @description Updates charged spray buildup, release, cancel, and feedback events from input data.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Bool} True when charge input was handled and continuous spray should be skipped.
function actor_controller_update_charge(_actor) {
    if (!is_struct(_actor) || !is_struct(_actor.input)) {
        return false;
    }

    if (!actor_controller_has_charged_spray_ability(_actor)) {
        actor_controller_reset_charge(_actor);
        return false;
    }

    var _input = _actor.input;
    var _has_charge = (_actor.charge_timer > 0) || (_actor.charge_amount > ACTOR_EPSILON);

    if (_input.cancel_pressed && _has_charge) {
        actor_controller_reset_charge(_actor);
        return true;
    }

    if (_input.charge_released) {
        if (_has_charge) {
            actor_controller_release_charged_shot(_actor);
        }

        return true;
    }

    if (!_input.charge_pressed && !_input.charge_held) {
        return false;
    }

    var _was_charging = _has_charge;
    var _was_full = _actor.charge_overready;
    var _build_frames = max(1, floor(actor_stats_get_optional(_actor.stats, "charge_build_frames", ACTOR_CHARGE_BUILD_FRAMES_DEFAULT)));

    if (!_was_charging) {
        var _start_event = actor_controller_record_event(_actor, ActorControllerEvent.CHARGE_START);
        if (is_struct(_start_event)) {
            _start_event.spray_mode = ActorSprayMode.CHARGED;
        }
    }

    _actor.charge_timer = min(_build_frames, _actor.charge_timer + 1);
    actor_controller_update_charge_flags(_actor);

    if (!_was_full && _actor.charge_overready) {
        var _full_event = actor_controller_record_event(_actor, ActorControllerEvent.CHARGE_FULL);
        if (is_struct(_full_event)) {
            _full_event.spray_mode = ActorSprayMode.CHARGED;
            _full_event.charge_amount = _actor.charge_amount;
        }
    }

    return true;
}

/// @function actor_controller_record_refill_events
/// @description Records refill lifecycle events when water increases.
/// @param {Struct} _actor Actor controller receiving water.
/// @param {Real} _old_water Water amount before refill.
/// @param {Real} _new_water Water amount after refill.
/// @returns {Undefined} No return value.
function actor_controller_record_refill_events(_actor, _old_water, _new_water) {
    if (!is_struct(_actor) || (_new_water <= _old_water + ACTOR_EPSILON)) {
        return;
    }

    if (_actor.water_refill_frame != _actor.step_index) {
        _actor.water_refill_frame = _actor.step_index;

        if (!_actor.water_refill_active) {
            actor_controller_record_event(_actor, ActorControllerEvent.REFILL_START);
        }

        _actor.water_refill_active = true;
    }

    actor_controller_record_event(_actor, ActorControllerEvent.REFILL_TICK);

    if ((_old_water < _actor.water_max - ACTOR_EPSILON) && (_new_water >= _actor.water_max - ACTOR_EPSILON)) {
        actor_controller_record_event(_actor, ActorControllerEvent.REFILL_FULL);
    }
}

/// @function actor_controller_set_water
/// @description Sets actor water to a clamped amount and records refill events if water increases.
/// @param {Struct} _actor Actor controller to update.
/// @param {Real} _amount Target water amount.
/// @returns {Real} Clamped water amount after the call.
function actor_controller_set_water(_actor, _amount) {
    if (!is_struct(_actor)) {
        return 0;
    }

    _actor.water_max = max(0, _actor.water_max);

    var _old_water = _actor.water_current;
    _actor.water_current = clamp(_amount, 0, _actor.water_max);

    actor_controller_record_refill_events(_actor, _old_water, _actor.water_current);

    return _actor.water_current;
}

/// @function actor_controller_add_water
/// @description Adds water to the actor resource, clamped by water max.
/// @param {Struct} _actor Actor controller to update.
/// @param {Real} _amount Water amount to add.
/// @returns {Real} Clamped water amount after the call.
function actor_controller_add_water(_actor, _amount) {
    if (!is_struct(_actor)) {
        return 0;
    }

    var _add_amount = is_undefined(_amount) ? 0 : max(0, _amount);

    return actor_controller_set_water(_actor, _actor.water_current + _add_amount);
}

/// @function actor_controller_refill_water_rate
/// @description Refills water by a per-frame amount for zones, surfaces, or simple refill objects.
/// @param {Struct} _actor Actor controller to update.
/// @param {Real} _amount_per_step Water amount to add this frame, or undefined to use the actor stat default.
/// @returns {Real} Clamped water amount after the call.
function actor_controller_refill_water_rate(_actor, _amount_per_step) {
    if (!is_struct(_actor)) {
        return 0;
    }

    var _amount = is_undefined(_amount_per_step)
        ? actor_stats_get_optional(_actor.stats, "water_refill_rate", ACTOR_WATER_REFILL_RATE_DEFAULT)
        : _amount_per_step;

    return actor_controller_add_water(_actor, max(0, _amount));
}

/// @function actor_controller_update_spray
/// @description Updates spray mode, surface refill, active spray state, water drain, and recoil.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_update_spray(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    _actor.spray_recoil_x = 0;
    _actor.spray_recoil_y = 0;

    if (!actor_controller_has_spray_ability(_actor)) {
        actor_controller_stop_spray(_actor);
        _actor.spray_mode = ActorSprayMode.NONE;
        return;
    }

    if (!actor_controller_is_continuous_spray_mode(_actor.spray_mode)) {
        _actor.spray_mode = ActorSprayMode.WIDE;
    }

    actor_controller_update_spray_mode_from_input(_actor);

    if (_actor.is_physically_grounded) {
        var _surface_refill_rate = actor_surface_get_refill_rate(_actor.surface_info);
        if (_surface_refill_rate > ACTOR_EPSILON) {
            actor_controller_refill_water_rate(_actor, _surface_refill_rate);
        }
    }

    if (!is_struct(_actor.input)) {
        actor_controller_stop_spray(_actor);
        return;
    }

    if (actor_controller_has_charged_spray_ability(_actor)) {
        var _has_charge_state = (_actor.charge_timer > 0) || (_actor.charge_amount > ACTOR_EPSILON);
        var _has_charge_input = _actor.input.charge_pressed
            || _actor.input.charge_held
            || _actor.input.charge_released
            || (_actor.input.cancel_pressed && _has_charge_state);

        if (_has_charge_input) {
            actor_controller_stop_spray(_actor);
        }

        if (actor_controller_update_charge(_actor)) {
            return;
        }
    } else {
        actor_controller_update_charge(_actor);
    }

    var _wants_spray = _actor.input.spray_held || _actor.input.spray_pressed;
    if (_actor.input.spray_released || !_wants_spray) {
        actor_controller_stop_spray(_actor);
        return;
    }

    if (!_actor.spray_active && !actor_controller_start_spray(_actor)) {
        return;
    }

    if (!actor_controller_apply_spray_cost(_actor)) {
        actor_controller_stop_spray(_actor);
        return;
    }

    actor_controller_apply_spray_recoil(_actor);
}
