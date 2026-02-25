## Abstract base class for components which display a cursor and other UI for the player or other [Entity] to choose a target for an [Action].
## The cursor may be controlled by the mouse or gamepad or even AI, depending on the specific subclass which extends this script, such as [ActionTargetingPositionComponent].
## NOTE: The target must be an [Entity] with an [ActionTargetableComponent].
## @experimental

@abstract class_name ActionTargetingCursorComponentBase
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


#region Events

func connectSignals() -> void:
	cursorArea.area_entered.connect(self.onCursorArea_areaEntered)
	cursorArea.area_exited.connect(self.onCursorArea_areaExited)


func onCursorArea_areaEntered(area:Area2D) -> void:
	if not isEnabled or not isChoosing: return
	
	# Did the cursor enter a potential target?
	var actionTargetableComponent: ActionTargetableComponent = area.get_node(^".") as ActionTargetableComponent
	if not actionTargetableComponent: return
	if debugMode: printDebug(str("Entered ", actionTargetableComponent))

	actionTargetableComponentInContact.append(actionTargetableComponent)
	actionTargetableComponent.setHighlight(true)


func onCursorArea_areaExited(area:Area2D) -> void:
	# NOTE: Exiting and cleanup should not depend on `isEnabled` or `isChoosing`
	var actionTargetableComponent: ActionTargetableComponent = area.get_node(^".") as ActionTargetableComponent
	if not actionTargetableComponent: return
	if debugMode: printDebug(str("Exited ", actionTargetableComponent))
	
	actionTargetableComponentInContact.erase(actionTargetableComponent)
	actionTargetableComponent.setHighlight(false)

#endregion


func chooseTargetsUnderCursor() -> Array[ActionTargetableComponent]:
	# TODO: Set limits on concurrent targets
	if not isEnabled: return [] # TBD: cancelTargetSelection() if not isEnabled?

	# If there are no eligible targets, the selection should be cancelled
	if self.actionTargetableComponentInContact.is_empty():
		super.cancelTargetSelection()
		return []

	self.isChoosing = false # NOTE: This fixes unintended cancellation in _exit_tree() or `NOTIFICATION_UNPARENTED` when this component is removed after a successful selection.

	var chosenTargets: Array[ActionTargetableComponent] # TBD: Add ENTITIES or components?
	for target in self.actionTargetableComponentInContact:
		if self.chooseTarget(target): # Request the ActionTargetableComponent to see if it lets us choose it
			chosenTargets.append(target)
		# TODO: break if number of targets > optional limit

	# TBD: Keep selecting if all targets refused ActionTargetableComponent.requestToChoose()?
	# UNDECIDED: if chosenTargets.is_empty(): return []

	if not chosenTargets.is_empty(): # TBD: CHECK: Perform cleanup only if there is a chosen target?
		self.isChoosing = false
		self.get_viewport().set_input_as_handled()
		self.requestDeletion()

	return chosenTargets
