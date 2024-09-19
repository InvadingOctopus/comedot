## A subclass of [PositionControlComponent] that hides the [Entity] when there is no player input.
## May be useful for UI such as targeting cursors etc.

class_name StationaryHidingPositionControlComponent
extends PositionControlComponent


#region Parameters
const animationDuration: float = 0.5

@export var shouldHideOnReady: bool = true
#endregion


#region State
@onready var hidingTimer: Timer = $HidingTimer
var tween: Tween
#endregion


func _ready() -> void:
	if shouldHideOnReady: parentEntity.visible = false


func _process(delta: float) -> void: # TBD: Should this be `_physics_process()` or `_process()`?
	# NOTE: Cannot use `_input()` because `delta` is needed.
	if not isEnabled: return

	super._process(delta)
	
	# Start the auto-hiding countdown when there has been no movement input.
	if lastInput.is_zero_approx():
		if parentEntity.visible and hidingTimer.is_stopped(): hidingTimer.start()
	elif not parentEntity.visible or not hidingTimer.is_stopped(): # Halt any ongoing hiding animation
		showEntity()


func showEntity() -> void:
	# TBD: Animate?
	hidingTimer.stop()
	if tween: tween.kill()

	# Just modify the alpha of the current modulate to maintain the tint
	var opaqueModulate: Color = parentEntity.modulate
	opaqueModulate.a = 1.0
	parentEntity.modulate = opaqueModulate

	parentEntity.visible  = true


func hideEntity() -> void:
	if tween: tween.kill()
	tween = parentEntity.create_tween()
	
	# Just modify the alpha of the current modulate to maintain the tint
	var fadedModulate: Color = parentEntity.modulate
	fadedModulate.a = 0
	
	tween.tween_property(parentEntity, "modulate", fadedModulate, animationDuration)
	tween.tween_property(parentEntity, "visible",  false, 0)
	

func onHidingTimer_timeout() -> void:
	hideEntity()
