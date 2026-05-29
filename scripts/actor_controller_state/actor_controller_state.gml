/// @description Movement state helpers for the generic actor controller.

/// @function actor_controller_set_state
/// @description Changes the actor movement state when the requested transition is currently allowed.
/// @param {Struct} _actor Actor controller to update.
/// @param {Real} _new_state ActorMoveState enum value to enter.
/// @returns {Bool} True when the state was changed or already matched.
function actor_controller_set_state(_actor, _new_state) {
    if (!is_struct(_actor)) {
        return false;
    }

    if (_actor.state == _new_state) {
        return true;
    }

    if (!actor_controller_can_enter_state(_actor, _new_state)) {
        return false;
    }

    _actor.state_previous = _actor.state;
    _actor.state = _new_state;
    _actor.time_in_state = 0;

    return true;
}

/// @function actor_controller_is_state
/// @description Checks whether the actor is currently in a specific movement state.
/// @param {Struct} _actor Actor controller to inspect.
/// @param {Real} _state ActorMoveState enum value to compare.
/// @returns {Bool} True when the actor is in the requested state.
function actor_controller_is_state(_actor, _state) {
    if (!is_struct(_actor)) {
        return false;
    }

    return _actor.state == _state;
}

/// @function actor_controller_update_state
/// @description Updates guide 3's basic grounded or airborne state from physical contact data.
/// @param {Struct} _actor Actor controller to update.
/// @returns {Undefined} No return value.
function actor_controller_update_state(_actor) {
    if (!is_struct(_actor)) {
        return;
    }

    switch (_actor.state) {
        case ActorMoveState.DEAD:
        case ActorMoveState.LOCKED:
        case ActorMoveState.STUNNED:
        case ActorMoveState.KNOCKBACK:
        case ActorMoveState.MANTLE:
        case ActorMoveState.LEDGE_GRAB:
            return;
    }

    if (_actor.is_physically_grounded) {
        actor_controller_set_state(_actor, ActorMoveState.GROUNDED);
    } else if (actor_controller_can_wall_slide(_actor)) {
        actor_controller_try_enter_wall_slide(_actor);
    } else {
        actor_controller_set_state(_actor, ActorMoveState.AIRBORNE);
    }
}

/// @function actor_controller_can_enter_state
/// @description Reports whether guide 3 allows the actor to enter a requested movement state.
/// @param {Struct} _actor Actor controller to inspect.
/// @param {Real} _state ActorMoveState enum value being requested.
/// @returns {Bool} True when the requested state can be entered.
function actor_controller_can_enter_state(_actor, _state) {
    if (!is_struct(_actor)) {
        return false;
    }

    switch (_state) {
        case ActorMoveState.GROUNDED:
            return _actor.is_physically_grounded;

        case ActorMoveState.AIRBORNE:
            return true;

        case ActorMoveState.WALL_SLIDE:
            return actor_controller_can_wall_slide(_actor);

        case ActorMoveState.LEDGE_GRAB:
            return is_struct(_actor.stats)
                && ((_actor.stats.abilities & ACTOR_ABILITY_LEDGE_GRAB) != 0)
                && is_struct(_actor.ledge_candidate)
                && _actor.ledge_candidate.active;

        case ActorMoveState.MANTLE:
            return (_actor.state == ActorMoveState.LEDGE_GRAB)
                || (_actor.state == ActorMoveState.MANTLE);

        case ActorMoveState.STUNNED:
        case ActorMoveState.KNOCKBACK:
        case ActorMoveState.LOCKED:
        case ActorMoveState.DEAD:
            return true;
    }

    return false;
}

/// @function actor_controller_get_state_name
/// @description Converts an ActorMoveState enum value into readable debug text.
/// @param {Real} _state ActorMoveState enum value to format.
/// @returns {String} Readable state name.
function actor_controller_get_state_name(_state) {
    switch (_state) {
        case ActorMoveState.GROUNDED: return "GROUNDED";
        case ActorMoveState.AIRBORNE: return "AIRBORNE";
        case ActorMoveState.WALL_SLIDE: return "WALL_SLIDE";
        case ActorMoveState.WALL_GRAB: return "WALL_GRAB";
        case ActorMoveState.LEDGE_GRAB: return "LEDGE_GRAB";
        case ActorMoveState.MANTLE: return "MANTLE";
        case ActorMoveState.SLIDE: return "SLIDE";
        case ActorMoveState.STUNNED: return "STUNNED";
        case ActorMoveState.KNOCKBACK: return "KNOCKBACK";
        case ActorMoveState.LOCKED: return "LOCKED";
        case ActorMoveState.DEAD: return "DEAD";
    }

    return "UNKNOWN";
}
