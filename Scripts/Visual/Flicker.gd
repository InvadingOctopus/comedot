# Randomly toggles a node's visibility on & off.
## @experimental

# class_name Flicker
extends CanvasItem


#region Parameters

@export var interval:	float = 0.2 ## The time in seconds before the next attempt to toggle visibility.

@export_range(0, 1.0, 0.01) var hideChance: float = 0.9 ## The chance to disappear every [member interval] seconds, where 1.0 = 100%
@export_range(0, 1.0, 0.01) var showChance: float = 1.0 ## If hidden, the chance to appear every [member interval] seconds, where 1.0 = 100%

@export var isEnabled:   bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		self.set_process(isEnabled) # PERFORMANCE: Set once instead of every frame

#endregion


#region State
var intervalElapsed: float
#endregion


func _ready() -> void:
	self.set_process(isEnabled) # Apply setter because Godot doesn't on initialization


func _process(delta: float) -> void:
	intervalElapsed += delta
	if intervalElapsed < interval: return
	intervalElapsed = 0

	# If hidden, show and go wait for the next disappearance
	if  self.visible and randf() <= hideChance:
		self.visible = false
	elif not self.visible and randf() <= showChance:
		self.visible = true
