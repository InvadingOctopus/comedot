## Abstract base class for components which display a cursor and other UI for the player or other [Entity] to choose a target for an [Action].
## The cursor may be controlled by the mouse or gamepad or even AI, depending on the specific subclass which extends this script, such as [ActionTargetingMouseComponent].

class_name ActionTargetingCursorComponentBase
extends ActionTargetingComponentBase


#region Parameters
#endregion


#region State
@onready var cursorSprite: Sprite2D = %CursorSprite
@onready var cursorArea:   Area2D   = self.get_node(^".") as Area2D
#endregion


#region Signals
#endregion


#region Dependencies
#endregion


func _ready() -> void:
	super._ready()
	connectSignals()


func connectSignals() -> void:
	cursorArea.area_entered.connect(self.onCursorArea_areaEntered)
	cursorArea.area_exited.connect(self.onCursorArea_areaExited)


func onCursorArea_areaEntered(area:Area2D) -> void:
	if not isEnabled or not isChoosing: return
	
	var actionTargetableComponent: ActionTargetableComponent = area.get_node(^".") as ActionTargetableComponent
	if not actionTargetableComponent: return
	if shouldShowDebugInfo: printDebug(str("Entered ", actionTargetableComponent))

	actionTargetableComponent.setHighlight(true)


func onCursorArea_areaExited(area:Area2D) -> void:
	# NOTE: Exiting should not depend on `isEnabled` or `isChoosing`
	var actionTargetableComponent: ActionTargetableComponent = area.get_node(^".") as ActionTargetableComponent
	if not actionTargetableComponent: return
	if shouldShowDebugInfo: printDebug(str("Exited ", actionTargetableComponent))
	actionTargetableComponent.setHighlight(false)
