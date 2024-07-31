## Moves the [Camera2D] as the mouse moves.

extends Camera2D


# TODO: TBD: Do something more useful?


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	self.position = get_local_mouse_position()
