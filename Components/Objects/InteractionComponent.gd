## Represents an area where an interaction may occur when the player inputs the interaction action.

class_name InteractionComponent
extends Component


#region Parameters
@export var interactionIndicator: Node ## A node or control to display when this [InteractionComponent] is within the range of an [InteractionControlComponent].

## An optional short label, name or phrase for the interaction to display in the UI.
## Example: "Open Door" or "Chop Tree".
@export var label: String:
	set(newValue):
		if newValue != label:
			label = newValue
			setLabel()

## An optional detailed description of the interaction to display in the UI.
## Example: "Chopping a tree requires an Axe and grants 2 Wood"
@export var description: String

@export var isEnabled := true
#endregion


#region Signals
signal didEnterInteractionArea(entity: Entity, interactionControlComponent: InteractionControlComponent)
signal didExitInteractionArea(entity: Entity, interactionControlComponent: InteractionControlComponent)
signal willBeginInteraction(interactorEntity: Entity)
signal didDenyInteraction(interactorEntity: Entity)
#region endregion


func _ready():
	if interactionIndicator:
		interactionIndicator.visible = false
		setLabel()


func onArea_entered(area: Area2D) -> void:
	var interactionControlComponent: InteractionControlComponent = area.get_node(".") as InteractionControlComponent # HACK: TODO: Find better way to cast
	if not interactionControlComponent: return

	# Display the indicators and labels, if any.
	if interactionIndicator:
		setLabel()
		interactionIndicator.visible = true

	didEnterInteractionArea.emit(interactionControlComponent.parentEntity, interactionControlComponent)


func onArea_exited(area: Area2D) -> void:
	var interactionControlComponent: InteractionControlComponent = area.get_node(".") as InteractionControlComponent # HACK: TODO: Find better way to cast
	if not interactionControlComponent: return

	# Hide the indicators and labels.
	if interactionIndicator:
		interactionIndicator.visible = false

	didExitInteractionArea.emit(interactionControlComponent.parentEntity, interactionControlComponent)


## Called by an [InteractionControlComponent].
## When the player presses the Interact button, the [InteractionControlComponent] checks its conditions then calls this method on the [InteractionComponent](s) in range.
## Then this [InteractionComponent] checks its own conditions (such as whether the player has key to open a door, or an axe to chop a tree).
func requestToInteract(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	if not isEnabled: return false

	var isInteractionApproved := checkInteractionConditions(interactorEntity, interactionControlComponent)

	if isInteractionApproved:
		willBeginInteraction.emit(interactorEntity)
	else:
		didDenyInteraction.emit(interactorEntity)
		return false

	return isInteractionApproved


## If the [interactionIndicator] is a [Label], display our [label] parameter.
func setLabel():
	# TBD: Should this be optional?
	if (not self.label.is_empty()) and interactionIndicator is Label:
		interactionIndicator.text = self.label


#region Virtual Methods

## May be overridden in a subclass to approve or deny an interaction.
## Default: `true`
func checkInteractionConditions(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	# CHECK: Maybe a better name? :p
	return isEnabled


## Must be overriden by a subclass to execute the actual interaction script.
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent):
	pass

#endregion
