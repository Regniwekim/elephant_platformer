/// @description Surface metadata helpers for generic actor terrain.

/// @function actor_surface_read_optional
/// @description Reads a field from an instance or struct and returns a fallback when absent.
/// @param {Any} _source Instance id or struct containing optional surface fields.
/// @param {String} _field_name Field name to read.
/// @param {Any} _default_value Value returned when the source or field is unavailable.
/// @returns {Any} Field value or the provided fallback.
function actor_surface_read_optional(_source, _field_name, _default_value) {
    if (is_struct(_source)) {
        if (variable_struct_exists(_source, _field_name)) {
            return variable_struct_get(_source, _field_name);
        }

        return _default_value;
    }

    if (instance_exists(_source) && variable_instance_exists(_source, _field_name)) {
        return variable_instance_get(_source, _field_name);
    }

    return _default_value;
}

/// @function actor_surface_apply_modifiers
/// @description Copies optional surface modifier fields from an instance or struct onto surface info.
/// @param {Struct} _surface Surface info to modify.
/// @param {Any} _source Instance id or struct containing optional surface fields.
/// @returns {Struct} Modified surface info.
function actor_surface_apply_modifiers(_surface, _source) {
    if (!is_struct(_surface)) {
        _surface = new ActorSurfaceInfo();
    }

    _surface.surface_type = actor_surface_read_optional(_source, "surface_type", _surface.surface_type);
    _surface.friction_multiplier = max(0, actor_surface_read_optional(_source, "friction_multiplier", _surface.friction_multiplier));
    _surface.accel_multiplier = max(0, actor_surface_read_optional(_source, "accel_multiplier", _surface.accel_multiplier));
    _surface.top_speed_multiplier = max(0, actor_surface_read_optional(_source, "top_speed_multiplier", _surface.top_speed_multiplier));
    _surface.jump_multiplier = max(0, actor_surface_read_optional(_source, "jump_multiplier", _surface.jump_multiplier));
    _surface.recoil_multiplier = max(0, actor_surface_read_optional(_source, "recoil_multiplier", _surface.recoil_multiplier));
    _surface.conveyor_x = actor_surface_read_optional(_source, "conveyor_x", _surface.conveyor_x);
    _surface.conveyor_y = actor_surface_read_optional(_source, "conveyor_y", _surface.conveyor_y);
    _surface.hazard = actor_surface_read_optional(_source, "hazard", _surface.hazard);
    _surface.hazard = actor_surface_read_optional(_source, "is_hazard", _surface.hazard);
    _surface.water_refill_rate = max(0, actor_surface_read_optional(_source, "water_refill_rate", _surface.water_refill_rate));
    _surface.water_refill_rate = max(0, actor_surface_read_optional(_source, "refill_rate", _surface.water_refill_rate));

    return _surface;
}

/// @function actor_surface_get_info
/// @description Builds surface metadata for a terrain instance or returns default metadata.
/// @param {Any} _source Instance id or struct containing optional surface fields.
/// @returns {Struct} Surface info populated with available modifier fields.
function actor_surface_get_info(_source) {
    return actor_surface_apply_modifiers(new ActorSurfaceInfo(), _source);
}

/// @function actor_surface_is_hazard
/// @description Reports whether a surface should be treated as hazardous.
/// @param {Struct} _surface Surface info to inspect.
/// @returns {Bool} True when the surface is hazardous.
function actor_surface_is_hazard(_surface) {
    if (!is_struct(_surface)) {
        return false;
    }

    return _surface.hazard || (_surface.surface_type == ActorSurfaceType.HAZARD);
}

/// @function actor_surface_is_walkable
/// @description Reports whether a surface can be used as physical ground.
/// @param {Struct} _surface Surface info to inspect.
/// @returns {Bool} True when the surface can be walked on.
function actor_surface_is_walkable(_surface) {
    if (!is_struct(_surface)) {
        return true;
    }

    return !actor_surface_is_hazard(_surface);
}

/// @function actor_surface_get_refill_rate
/// @description Reads the water refill rate from a surface info struct.
/// @param {Struct} _surface Surface info to inspect.
/// @returns {Real} Non-negative water refill amount per frame.
function actor_surface_get_refill_rate(_surface) {
    if (!is_struct(_surface)) {
        return 0;
    }

    return max(0, _surface.water_refill_rate);
}
