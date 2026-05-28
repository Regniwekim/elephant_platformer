/// @description Actor controller enums for finite controller categories.

enum ActorMoveState {
    GROUNDED,
    AIRBORNE,
    WALL_SLIDE,
    WALL_GRAB,
    LEDGE_GRAB,
    MANTLE,
    SLIDE,
    STUNNED,
    KNOCKBACK,
    LOCKED,
    DEAD
}

enum ActorFacing {
    LEFT = -1,
    RIGHT = 1
}

enum ActorSprayMode {
    NONE,
    WIDE,
    FOCUSED,
    CHARGED
}

enum ActorForceType {
    ADDITIVE,
    IMPULSE,
    OVERRIDE,
    CONTINUOUS,
    PLATFORM_CARRY,
    KNOCKBACK
}

enum ActorSurfaceType {
    NORMAL,
    ICE,
    MUD,
    WET,
    CONVEYOR,
    BOUNCE,
    STICKY,
    HAZARD,
    WATER_REFILL,
    CRUMBLING
}

enum ActorCollisionSide {
    NONE,
    LEFT,
    RIGHT,
    TOP,
    BOTTOM
}

enum ActorInputSource {
    NONE,
    PLAYER,
    AI,
    SCRIPT,
    REPLAY,
    GHOST
}

enum ActorControllerEvent {
    JUMP,
    LAND,
    HARD_LAND,
    WALL_SLIDE_START,
    WALL_JUMP,
    LEDGE_GRAB,
    MANTLE,
    SLIDE_START,
    SLIDE_END,
    SPRAY_START,
    SPRAY_STOP,
    NOZZLE_CHANGE,
    CHARGE_START,
    CHARGE_FULL,
    CHARGE_RELEASE,
    REFILL_START,
    REFILL_TICK,
    REFILL_FULL,
    HIT,
    DEATH,
    RESPAWN
}
