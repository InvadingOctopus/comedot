## Rotates the node every frame.

extends Node2D

@export_range(0.0, 10.0, 0.1) var speed: float = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.rotation += speed * delta
