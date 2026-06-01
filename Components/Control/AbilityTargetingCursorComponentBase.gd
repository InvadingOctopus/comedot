## Abstract base class for components which display a cursor and other UI for the player or other [Entity] to choose a target for an [Ability].
## The cursor may be controlled by the mouse or gamepad or even AI, depending on the specific subclass which extends this script, such as [AbilityTargetingPositionComponent].
## NOTE: The target must be an [Entity] with an [AbilityTargetableComponent].
## @experimental

@abstract class_name AbilityTargetingCursorComponentBase
extends AbilityTargetingComponentBase


#region Parameters
# TODO: Option to hide label
#endregion


#region State

@onready var cursorSprite: Sprite2D = %CursorSprite
@onready var cursorArea:   Area2D   = self.get_node(^".") as Area2D

## A list of [AbilityTargetableComponent]s currently in collision contact.
var abilityTargetableComponentInContact: Array[AbilityTargetableComponent]

#endregion


func _ready() -> void:
	super._ready()
	$Label.text = ability.displayName
	connectSignals()


#region Events

func connectSignals() -> void:
	cursorArea.area_entered.connect(self.onCursorArea_areaEntered)
	cursorArea.area_exited.connect(self.onCursorArea_areaExited)


func onCursorArea_areaEntered(area:Area2D) -> void:
	if not isEnabled or not isChoosing: return
	
	# Did the cursor enter a potential target?
	var abilityTargetableComponent: AbilityTargetableComponent = area.get_node(^".") as AbilityTargetableComponent
	if not abilityTargetableComponent: return
	if debugMode: printDebug(str("Entered ", abilityTargetableComponent))

	abilityTargetableComponentInContact.append(abilityTargetableComponent)
	abilityTargetableComponent.setHighlight(true)


func onCursorArea_areaExited(area:Area2D) -> void:
	# NOTE: Exiting and cleanup should not depend on `isEnabled` or `isChoosing`
	var abilityTargetableComponent: AbilityTargetableComponent = area.get_node(^".") as AbilityTargetableComponent
	if not abilityTargetableComponent: return
	if debugMode: printDebug(str("Exited ", abilityTargetableComponent))
	
	abilityTargetableComponentInContact.erase(abilityTargetableComponent)
	abilityTargetableComponent.setHighlight(false)

#endregion


func chooseTargetsUnderCursor() -> Array[AbilityTargetableComponent]:
	# TODO: Set limits on concurrent targets
	if not isEnabled: return [] # TBD: cancelTargetSelection() if not isEnabled?

	# If there are no eligible targets, the selection should be cancelled
	if self.abilityTargetableComponentInContact.is_empty():
		super.cancelTargetSelection()
		return []

	self.isChoosing = false # NOTE: This fixes unintended cancellation in _exit_tree() or `NOTIFICATION_UNPARENTED` when this component is removed after a successful selection.

	var chosenTargets: Array[AbilityTargetableComponent] # TBD: Add ENTITIES or components?
	for target in self.abilityTargetableComponentInContact:
		if self.chooseTarget(target): # Request the AbilityTargetableComponent to see if it lets us choose it
			chosenTargets.append(target)
		# TODO: break if number of targets > optional limit

	# TBD: Keep selecting if all targets refused AbilityTargetableComponent.requestToChoose()?
	# UNDECIDED: if chosenTargets.is_empty(): return []

	if not chosenTargets.is_empty(): # TBD: CHECK: Perform cleanup only if there is a chosen target?
		self.isChoosing = false
		self.get_viewport().set_input_as_handled()
		self.requestDeletion()

	return chosenTargets
