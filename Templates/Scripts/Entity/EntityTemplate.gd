# meta-default: true

## Description

class_name _CLASS_
extends Entity


#region Parameters
@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		# PERFORMANCE: Set once instead of every frame
		self.set_process(isEnabled)
		self.set_process_input(isEnabled)
#endregion


#region State
var property: int ## PLACEHOLDER
#endregion


#region Signals
signal didSomethingHappen ## PLACEHOLDER
#endregion


#region Dependencies
@onready var childNode: Node2D = $Node2D  ## PLACEHOLDER
#endregion


func _ready() -> void:
	# Apply setters because Godot doesn't on initialization
	self.set_process(isEnabled)
	self.set_process_input(isEnabled)
	# PLACEHOLDER: Add any code needed to configure and prepare the component.


func _input(event: InputEvent) -> void:
	pass # PLACEHOLDER: Handle one-shot input events such as jumping or firing.


func _process(delta: float) -> void: # NOTE: If you need to process movement or collisions, use `_physics_process()`
	pass # PLACEHOLDER: Perform any per-frame updates.
