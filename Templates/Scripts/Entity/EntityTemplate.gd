# meta-default: true

## Description

class_name _CLASS_
extends Entity


#region Parameters
@export var isEnabled := true
#endregion


#region State
var property: int ## Placeholder
#endregion


#region Signals
signal didSomethingHappen ## Placeholder
#endregion


#region Dependencies
@onready var childNode: Node2D = $Node2D  ## Placeholder
#endregion


func _ready() -> void:
	pass # Placeholder: Add any code needed to configure and prepare the component.


func _input(event: InputEvent) -> void:
	if not isEnabled: return
	pass # Placeholder: Handle one-shot input events such as jumping or firing.


func _process(delta: float) -> void: # NOTE: If you need to process movement or collisions, use `_physics_process()`
	if not isEnabled: return
	pass # Placeholder: Perform any per-frame updates.
