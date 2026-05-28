/// @description Create the player-owned generic actor controller.
actor_stats = player_stats_create_elephant();
actor_controller = actor_controller_create(actor_stats, x, y);
actor_input_frame_number = 0;
actor_input = actor_input_frame_create_empty(ActorInputSource.PLAYER, id, actor_input_frame_number);
