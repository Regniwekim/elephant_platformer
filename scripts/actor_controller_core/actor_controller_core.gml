/// @description Core actor controller shell and instance synchronization.

/// @function actor_controller_create
/// @description Creates a controller at a position using cloned actor stats.
/// @param {Struct} _stats Actor stats used to configure the controller.
/// @param {Real} _x Starting x position.
/// @param {Real} _y Starting y position.
/// @returns {Struct} New actor controller.
function actor_controller_create(_stats, _x, _y) {
    var _stats_source = actor_stats_validate(_stats) ? _stats : actor_stats_create_default();
    var _actor = new ActorController();

    _actor.stats = actor_stats_clone(_stats_source);
    _actor.water_max = _actor.stats.water_max;
    _actor.water_current = _actor.stats.water_max;
    _actor.debug_enabled = actor_stats_get_optional(_actor.stats, "debug_enabled", ACTOR_DEBUG_DEFAULT);
    _actor.debug_draw_collision = actor_stats_get_optional(_actor.stats, "debug_draw_collision", ACTOR_DEBUG_DRAW_COLLISION_DEFAULT);
    _actor.debug_draw_probes = actor_stats_get_optional(_actor.stats, "debug_draw_probes", ACTOR_DEBUG_DRAW_PROBES_DEFAULT);
    _actor.debug_draw_vectors = actor_stats_get_optional(_actor.stats, "debug_draw_vectors", ACTOR_DEBUG_DRAW_VECTORS_DEFAULT);
    _actor.debug_print_events = actor_stats_get_optional(_actor.stats, "debug_print_events", ACTOR_DEBUG_PRINT_EVENTS_DEFAULT);

    actor_controller_set_position(_actor, _x, _y);
    _actor.x_previous = _actor.x;
    _actor.y_previous = _actor.y;
    _actor.spray_origin_x = _actor.x;
    _actor.spray_origin_y = _actor.y;

    return _actor;
}

/// @function actor_controller_update
/// @description Runs the guide 0 controller update shell without applying movement or collision.
/// @param {Struct} _actor Actor controller to update.
/// @param {Struct} _input Input frame for this update.
/// @returns {Struct} Updated actor controller.
function actor_controller_update(_actor, _input) {
    actor_controller_begin_step(_actor, _input);
    actor_controller_end_step(_actor);

    return _actor;
}

/// @function actor_controller_begin_step
/// @description Caches previous frame state, clears one-frame data, and stores current input.
/// @param {Struct} _actor Actor controller to prepare.
/// @param {Struct} _input Input frame to store.
/// @returns {Undefined} No return value.
function actor_controller_begin_step(_actor, _input) {
    _actor.x_previous = _actor.x;
    _actor.y_previous = _actor.y;
    _actor.state_previous = _actor.state;
    _actor.was_grounded = _actor.is_grounded;
    _actor.input_previous = _actor.input;

    _actor.events = [];
    _actor.event_count = 0;

    if (is_struct(_input)) {
        _actor.input = _input;
    } else {
        _actor.input = actor_input_frame_create_empty(ActorInputSource.NONE, noone, _actor.step_index);
    }

    _actor.spray_aim_x = _actor.input.aim_x;
    _actor.spray_aim_y = _actor.input.aim_y;
    _actor.spray_origin_x = _actor.x;
    _actor.spray_origin_y = _actor.y;
}

/// @function actor_controller_end_step
/// @description Finalizes guide 0 bookkeeping after the update shell.
/// @param {Struct} _actor Actor controller to finalize.
/// @returns {Undefined} No return value.
function actor_controller_end_step(_actor) {
    _actor.water_current = clamp(_actor.water_current, 0, _actor.water_max);
    _actor.charge_amount = clamp(_actor.charge_amount, 0, 1);
    _actor.step_index += 1;
}

/// @function actor_controller_set_position
/// @description Sets the controller's real-valued position.
/// @param {Struct} _actor Actor controller to move.
/// @param {Real} _x New x position.
/// @param {Real} _y New y position.
/// @returns {Struct} The actor controller passed in.
function actor_controller_set_position(_actor, _x, _y) {
    _actor.x = _x;
    _actor.y = _y;

    return _actor;
}

/// @function actor_controller_set_velocity
/// @description Sets the controller's controlled velocity.
/// @param {Struct} _actor Actor controller to update.
/// @param {Real} _hsp New horizontal speed.
/// @param {Real} _vsp New vertical speed.
/// @returns {Struct} The actor controller passed in.
function actor_controller_set_velocity(_actor, _hsp, _vsp) {
    _actor.hsp = _hsp;
    _actor.vsp = _vsp;

    return _actor;
}

/// @function actor_controller_apply_to_instance
/// @description Applies controller position back to a GameMaker instance.
/// @param {Struct} _actor Actor controller containing output position.
/// @param {Id.Instance} _instance Instance to synchronize.
/// @returns {Undefined} No return value.
function actor_controller_apply_to_instance(_actor, _instance) {
    var _x = _actor.x;
    var _y = _actor.y;

    with (_instance) {
        x = _x;
        y = _y;
    }
}
