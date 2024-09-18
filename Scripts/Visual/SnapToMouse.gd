## Sets the [Node2D]'s [member Node2D.global_position] to the mouse pointer.

extends Node2D


# TBD: Replace CameraMouseTracking?
# TBD: Do something more useful?


func _ready() -> void:
	self.global_position = self.get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion: return
	self.global_position = self.get_global_mouse_position()
