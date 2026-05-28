/// @description Stats creation, cloning, and placeholder validation for actors.

/// @function actor_stats_create_default
/// @description Creates the default reusable actor stats.
/// @returns {Struct} Default actor stats.
function actor_stats_create_default() {
    return new ActorStats();
}

/// @function actor_stats_create_player_elephant
/// @description Creates the player elephant stat preset without adding player behavior to the controller.
/// @returns {Struct} Elephant player actor stats.
function actor_stats_create_player_elephant() {
    var _stats = actor_stats_create_default();

    _stats.name = "Elephant Player";
    _stats.bbox_width = 24;
    _stats.bbox_height = 32;
    _stats.bbox_slide_height = 18;
    _stats.water_max = ACTOR_WATER_MAX_DEFAULT;
    _stats.abilities = ACTOR_ABILITY_ALL;
    _stats.debug_enabled = true;

    return _stats;
}

/// @function actor_stats_clone
/// @description Creates a shallow copy of actor stats for controller ownership.
/// @param {Struct} _stats Stats to clone.
/// @returns {Struct} Cloned actor stats, or default stats if the input is invalid.
function actor_stats_clone(_stats) {
    if (!is_struct(_stats)) {
        return actor_stats_create_default();
    }

    var _clone = new ActorStats();
    var _names = variable_struct_get_names(_stats);
    for (var _i = 0; _i < array_length(_names); _i++) {
        var _name = _names[_i];
        variable_struct_set(_clone, _name, variable_struct_get(_stats, _name));
    }

    return _clone;
}

/// @function actor_stats_validate
/// @description Performs placeholder validation for the minimum fields guide 0 needs.
/// @param {Struct} _stats Stats to validate.
/// @returns {Bool} True when required foundation stat fields are present and usable.
function actor_stats_validate(_stats) {
    if (!is_struct(_stats)) {
        return false;
    }

    if (!variable_struct_exists(_stats, "bbox_width")) return false;
    if (!variable_struct_exists(_stats, "bbox_height")) return false;
    if (!variable_struct_exists(_stats, "water_max")) return false;
    if (!variable_struct_exists(_stats, "abilities")) return false;
    if (!variable_struct_exists(_stats, "debug_enabled")) return false;

    if (_stats.bbox_width <= 0) return false;
    if (_stats.bbox_height <= 0) return false;
    if (_stats.water_max < 0) return false;

    return true;
}
