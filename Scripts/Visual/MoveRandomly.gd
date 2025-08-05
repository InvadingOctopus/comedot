## Changes the position of a node by a random amount each frame.
## TIP: May be useful for testing other scripts or physics etc.
## e.g. attach this script to a [Camera2D] node to test parallax effects etc.

extends Node2D


#region Parameters

## The strength to increase or decrease the unit vector by on each axis, per frame.
## 0 negates the movement on that axis.
@export var movementScale: Vector2 = Vector2.ONE

## The delay in seconds before moving. 0 = move every frame.
@export_range(0, 10, 0.01) var movementInterval: float = 0

#endregion


#region State
@onready var timeLeft: float = movementInterval
#endregion


func _process(delta: float) -> void:
	if timeLeft < 0 or is_zero_approx(timeLeft):
		# NOTE: Using delta may make the movement < 1 pixel (unless the scale is large), causing no visible movement
		self.position.x += Tools.plusMinusOneOrZero.pick_random() * movementScale.x # * delta
		self.position.y += Tools.plusMinusOneOrZero.pick_random() * movementScale.y # * delta
		timeLeft = movementInterval
	else:
		timeLeft -= delta
