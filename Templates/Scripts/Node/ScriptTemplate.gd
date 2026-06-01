# meta-default: true

## Description

class_name _CLASS_
extends Node


#region Parameters
@export var debugMode: bool = false
#endregion


#region State
var placeholder: int ## PLACEHOLDER
#endregion


#region Signals
signal didSomethingHappen ## PLACEHOLDER
#endregion


#region Dependencies
var player: Entity: # PlayerEntity or TurnBasedPlayerEntity
	get: return GameState.players.front()
#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if debugMode: Debug.printLog("_ready()", self, "white")
	pass # Replace with function body.


func _input(event: InputEvent) -> void:
	pass # Handle one-shot input events such as jumping or firing.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass  # Perform any per-frame updates or continuous input.
