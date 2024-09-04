## Moves the [Camera2D] as the mouse moves.

extends Camera2D


# TODO: TBD: Do something more useful?


func _ready() -> void:
	self.position = self.get_local_mouse_position()


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion: return
	self.position = self.get_local_mouse_position()
