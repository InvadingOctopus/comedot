## Represents an area where an interaction may occur when the player inputs the interaction action.
## The initiator of an interaction is an [Entity]'s [InteractionControlComponent].

class_name InteractionComponent
extends Component


#region Parameters

## The effect of the interaction, where this [InteractionComponent] is passed as the `source` for [method Payload.execute], and the [InteractionControlComponent]'s parent [Entity] is the `target`.
## See [Payload] for explanation and available options.
@export var payload: Payload

@export var interactionIndicator: Node ## A [Node2D] or [Control] to display when this [InteractionComponent] is in collision with an [InteractionControlComponent].

@export var alwaysShowIndicator:  bool ## Always show the indicator even when there is no [InteractionControlComponent] in collision.

## An optional short label, name or phrase for the interaction to display in the UI.
## Example: "Open Door" or "Chop Tree".
@export var label: String:
	set(newValue):
		if newValue != label:
			label = newValue
			updateLabel()

## An optional detailed description of the interaction to display in the UI.
## Example: "Chopping a tree requires an Axe and grants 2 Wood"
@export var description: String:
	set(newValue):
		if newValue != description:
			description = newValue
			if interactionIndicator is Control: interactionIndicator.tooltip_text = description

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		if selfAsArea:
			selfAsArea.monitorable = isEnabled
			selfAsArea.monitoring  = isEnabled

#endregion


#region State

var selfAsArea: Area2D:
	get:
		if not selfAsArea: selfAsArea = self.get_node(^".") as Area2D
		return selfAsArea

#endregion


#region Signals
signal didEnterInteractionArea(entity: Entity, interactionControlComponent: InteractionControlComponent)
signal didExitInteractionArea(entity: Entity, interactionControlComponent: InteractionControlComponent)
signal didDenyInteraction(interactorEntity: Entity)
signal willPerformInteraction(interactorEntity: Entity)
signal didPerformInteraction(result: Variant)
#region endregion


func _ready() -> void:
	# Set the initial state of the indicator
	if interactionIndicator:
		updateLabel()
		if interactionIndicator is Control: interactionIndicator.tooltip_text = self.description
		interactionIndicator.visible = alwaysShowIndicator # Start invisible if false


func onArea_entered(area: Area2D) -> void:
	var interactionControlComponent: InteractionControlComponent = area.get_node(^".") as InteractionControlComponent # HACK: Find better way to cast self?
	if not interactionControlComponent: return

	# Display the indicators and labels, if any.
	if interactionIndicator:
		updateLabel()
		interactionIndicator.visible = true

	didEnterInteractionArea.emit(interactionControlComponent.parentEntity, interactionControlComponent)


func onArea_exited(area: Area2D) -> void:
	var interactionControlComponent: InteractionControlComponent = area.get_node(^".") as InteractionControlComponent # HACK: Find better way to cast self?
	if not interactionControlComponent: return

	# Hide the indicators and labels.
	if interactionIndicator and not alwaysShowIndicator:
		interactionIndicator.visible = false

	didExitInteractionArea.emit(interactionControlComponent.parentEntity, interactionControlComponent)


## Called by an [InteractionControlComponent].
## When the player presses the Interact button, the [InteractionControlComponent] checks its conditions then calls this method on the [InteractionComponent](s) in range.
## Then this [InteractionComponent] checks its own conditions (such as whether the player has key to open a door, or an axe to chop a tree).
func requestToInteract(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	if not isEnabled: return false

	var isInteractionApproved: bool = checkInteractionConditions(interactorEntity, interactionControlComponent)

	if isInteractionApproved:
		return true
	else:
		didDenyInteraction.emit(interactorEntity)
		return false


## If the [interactionIndicator] is a [Label], display our [label] parameter.
func updateLabel() -> void:
	# TBD: Should this be optional?
	if (not self.label.is_empty()) and interactionIndicator is Label:
		interactionIndicator.text = self.label
		# Also apply the color
		interactionIndicator.modulate = self.modulate


#region Virtual Methods

## May be overridden in a subclass to approve or deny an interaction.
## NOTE: Remember to check [member isEnabled] in the subclass implementation!
## Default: `true`
func checkInteractionConditions(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	# CHECK: Maybe a better name? :p
	if debugMode: printDebug(str("checkInteractionConditions() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent))
	return isEnabled


## Executes the [member payload], passing this [InteractionComponent] as the `source` of the [Payload], and the [param interactorEntity] as the `target`.
## May be overridden by a subclass to perform custom actions.
## Returns: The result of [method Payload.execute] or `false` if the [member payload] is missing.
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> Variant:
	if debugMode: printDebug(str("performInteraction() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent, ", isEnabled: ", isEnabled))
	if not isEnabled: return false

	self.willPerformInteraction.emit(interactorEntity)
	var result: Variant = payload.execute(self, interactorEntity) if payload else false
	self.didPerformInteraction.emit(result)

	return result

#endregion
