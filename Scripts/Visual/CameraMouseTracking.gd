## Moves the [Camera2D] as the mouse moves.

extends Camera2D


# TODO: TBD: Do something more useful?


func _ready() -> void:
	self.position = self.get_local_mouse_position()


func _process(_delta: float) -> void:
	# NOTE: Cannot use `_input()` for updating position only on mouse events, because it causes erratic behavior.
	self.position = self.get_local_mouse_position()
