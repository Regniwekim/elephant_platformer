/// @description Generic input frame helpers for actor controller consumers.

/// @function actor_input_frame_create_empty
/// @description Creates an empty input frame tagged with source metadata.
/// @param {Real} _source_type ActorInputSource enum value.
/// @param {Any} _source_id Source identifier, such as an instance id.
/// @param {Real} _frame_number Frame number assigned by the caller.
/// @returns {Struct} Empty actor input frame.
function actor_input_frame_create_empty(_source_type, _source_id, _frame_number) {
    var _frame = new ActorInputFrame();

    _frame.source_type = _source_type;
    _frame.source_id = _source_id;
    _frame.frame_number = _frame_number;

    return _frame;
}
