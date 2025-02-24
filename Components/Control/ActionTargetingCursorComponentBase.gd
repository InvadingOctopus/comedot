## Abstract base class for components which display a cursor and other UI for the player or other [Entity] to choose a target for an [Action].
## The cursor may be controlled by the mouse or gamepad or even AI, depending on the specific subclass which extends this script, such as [ActionTargetingMouseComponent].
## The target must be an [Entity] with an [ActionTargetableComponent].
## @experimental

class_name ActionTargetingCursorComponentBase
extends ActionTargetingComponentBase


#region Parameters
# TODO: Option to hide label
#endregion


#region State

@onready var cursorSprite: Sprite2D = %CursorSprite
@onready var cursorArea:   Area2D   = self.get_node(^".") as Area2D

## A list of [ActionTargetableComponent]s currently in collision contact.
var actionTargetableComponentInContact: Array[ActionTargetableComponent]

#endregion


func _ready() -> void:
	super._ready()
	$Label.text = action.displayName
	connectSignals()


func connectSignals() -> void:
	cursorArea.area_entered.connect(self.onCursorArea_areaEntered)
	cursorArea.area_exited.connect(self.onCursorArea_areaExited)


func onCursorArea_areaEntered(area:Area2D) -> void:
	if not isEnabled or not isChoosing: return
	
	var actionTargetableComponent: ActionTargetableComponent = area.get_node(^".") as ActionTargetableComponent
	if not actionTargetableComponent: return
	if debugMode: printDebug(str("Entered ", actionTargetableComponent))

	actionTargetableComponentInContact.append(actionTargetableComponent)
	actionTargetableComponent.setHighlight(true)


func onCursorArea_areaExited(area:Area2D) -> void:
	# NOTE: Exiting should not depend on `isEnabled` or `isChoosing`
	var actionTargetableComponent: ActionTargetableComponent = area.get_node(^".") as ActionTargetableComponent
	if not actionTargetableComponent: return
	if debugMode: printDebug(str("Exited ", actionTargetableComponent))
	
	actionTargetableComponentInContact.erase(actionTargetableComponent)
	actionTargetableComponent.setHighlight(false)
