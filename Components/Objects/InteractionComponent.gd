## Represents an area where an interaction may occur when the player inputs the interaction action.
## The initiator of an interaction is an [Entity]'s [InteractionControlComponent].
## For interactions that have a cooldown and a [Stat] cost on the object's side, use [InteractionWithCostComponent]

class_name InteractionComponent
extends Component


#region Parameters

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		# AVOID: self.visible = isEnabled # Don't hide self in case some child visual effect nodes are present!
		if interactionIndicator: interactionIndicator.visible = isEnabled
		if  selfAsArea:
			# NOTE: Cannot set flags directly because Godot error: "Function blocked during in/out signal"
			selfAsArea.set_deferred(&"monitoring",  isEnabled)
			selfAsArea.set_deferred(&"monitorable", isEnabled)

## The effect of the interaction, where this [InteractionComponent] is passed as the `source` for [method Payload.execute], and the [InteractionControlComponent]'s parent [Entity] is the `target`.
## DESIGN: Interactions may succeed even if there is no payload; this allows special [InteractionControlComponent] subclasses to perform specific effects without a payload.
## See [Payload] for explanation and available options.
@export var payload: Payload

## Initiate an interaction automatically as soon as any [InteractionControlComponent] comes in contact.
## Calls [method InteractionControlComponent.interact] on an [Area2D] collision event.
## Example: Portals or traps etc.
## NOTE: Does not repeat interaction after the cooldown resets.
@export var automatic: bool = false

## If `true` then [InteractionControlComponent]s will not enter a cooldown when they interact with this object.
## TIP: Convenient for implementing NPC dialogs with [TextInteractionComponent] etc. where the cooldown is on the NPC's side.
@export var shouldSkipInteractorCooldown: bool = false


@export_group("UI")

@export var interactionIndicator: CanvasItem ## A [Node2D] or [Control] to display when this [InteractionComponent] is in collisioncontact with an [InteractionControlComponent].

@export var alwaysShowIndicator:  bool ## Always show the indicator even when there is no [InteractionControlComponent] in collision.

## An optional short label, name or phrase for the interaction to display in the UI.
## Example: "Open Door" or "Chop Tree".
@export var labelText: String:
	set(newValue):
		if newValue != labelText:
			labelText = newValue
			if self.is_node_ready(): updateLabel()

## An optional detailed description of the interaction to display in the UI.
## Example: "Chopping a tree requires an Axe and grants 2 Wood"
@export var description: String:
	set(newValue):
		if newValue != description:
			description = newValue
			if interactionIndicator is Control: interactionIndicator.tooltip_text = description

#endregion


#region State
var selfAsArea: Area2D:
	get:
		if not selfAsArea: selfAsArea = self.get_node(^".") as Area2D
		return selfAsArea
#endregion


#region Signals
signal didEnterInteractionArea	(entity: Entity, interactionControlComponent: InteractionControlComponent)
signal didExitInteractionArea	(entity: Entity, interactionControlComponent: InteractionControlComponent)
signal didDenyInteraction		(interactorEntity: Entity)
signal willPerformInteraction	(interactorEntity: Entity)
signal didPerformInteraction	(result: Variant)
#endregion


func _ready() -> void:
	# Set the initial state of the indicator
	if interactionIndicator:
		if interactionIndicator is Control: interactionIndicator.tooltip_text = self.description
		interactionIndicator.visible = alwaysShowIndicator # Start invisible if false

		if interactionIndicator is Label:
			# NOTE: If our `labelText` property is empty, save any existing text as the default, so we can restore it after any temporary modifications such as by [InteractionWithCooldownComponent] etc.
			if self.labelText.is_empty(): self.labelText = interactionIndicator.text
			else: updateLabel() # Otherwise set the UI to our string

	if  selfAsArea: # Apply setter because Godot doesn't on initialization
		selfAsArea.monitoring  = isEnabled
		selfAsArea.monitorable = isEnabled


## If the [interactionIndicator] is a [Label], display our [member labelText] parameter.
func updateLabel() -> void:
	# TBD: Should this be optional?
	if not self.labelText.is_empty() and interactionIndicator is Label:
		interactionIndicator.text = self.labelText


#region Events

func onArea_entered(area: Area2D) -> void:
	if not isEnabled: return
	var interactionControlComponent: InteractionControlComponent = area.get_node(^".") as InteractionControlComponent # HACK: Find better way to cast self?
	if not interactionControlComponent: return

	# Display the indicators and labels, if any.
	if interactionIndicator:
		updateLabel()
		interactionIndicator.visible = true

	didEnterInteractionArea.emit(interactionControlComponent.parentEntity, interactionControlComponent)

	if self.automatic:
		interactionControlComponent.interactAll()


func onArea_exited(area: Area2D) -> void:
	# NOTE: Exits should not check isEnabled to ensure cleanups are always performed.
	var interactionControlComponent: InteractionControlComponent = area.get_node(^".") as InteractionControlComponent # HACK: Find better way to cast self?
	if not interactionControlComponent: return

	# Hide the indicators and labels.
	if interactionIndicator and not alwaysShowIndicator:
		interactionIndicator.visible = false

	didExitInteractionArea.emit(interactionControlComponent.parentEntity, interactionControlComponent)

#endregion


#region Interaction Interface

## Called by an [InteractionControlComponent].
## When the player presses the Interact button, the [InteractionControlComponent] checks its conditions then calls this method on the [InteractionComponent](s) in range.
## Then this [InteractionComponent] checks its own conditions (such as whether the player has key to open a door, or an axe to chop a tree).
## NOTE: If not [member isEnabled] then `false` is returned BUT [signal didDenyInteraction] is NOT emitted; the component is basically dead.
func requestToInteract(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	if not isEnabled: return false

	var isInteractionApproved: bool = checkInteractionConditions(interactorEntity, interactionControlComponent)

	if isInteractionApproved:
		return true
	else:
		didDenyInteraction.emit(interactorEntity)
		return false


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


#region Virtual Methods

## May be overridden in a subclass to approve or deny an interaction.
## NOTE: Remember to check [member isEnabled] in the subclass implementation!
## Default: `true`
func checkInteractionConditions(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	# CHECK: Maybe a better name? :p
	if debugMode: printDebug(str("checkInteractionConditions() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent))
	return isEnabled

#endregion
