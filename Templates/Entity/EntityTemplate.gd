# meta-default: true

## Description

class_name _CLASS_
extends Entity


#region Parameters
@export var isEnabled := true
#endregion


#region State
#endregion


func _ready() -> void:
	pass # Any code needed to configure and prepare the entity.


func _input(event: InputEvent) -> void:
	if not isEnabled: return
	pass # Handle one-shot input events such as jumping or firing.


func _process(delta: float) -> void:
	if not isEnabled: return
	pass # Handle per-frame updates and continuous input such as moving or turning.
