## Represents an area where an interaction may occur when the player inputs the interaction action.
## The initiator of an interaction is an [Entity]'s [InteractionControlComponent].
## For interactions that have a cooldown and a [Stat] cost on the object's side, use [InteractionWithCostComponent]
## Uses [AreaContactComponent] as a parent class for collision logic and contact-tracking.

class_name InteractionComponent
extends AreaContactComponent

# TODO: Add shouldSucceedIfNoPayload
# TBD: Inherit scene from AreaContactComponent.tscn too?
# CHECK: PERFORMANCE: Will too many inheritance levels impact performance?


#region Parameters

## The effect of the interaction, where this [InteractionComponent] is passed as the `source` for [method Payload.execute], and the [InteractionControlComponent]'s parent [Entity] is the `target`.
## See [Payload] for explanation and available options.
## TIP: Interactions may succeed if [member allowNoPayload] even if there is no Payload; for example [TextInteractionComponent] performs its effects by itself.
@export var payload: Payload

## If `true` then [InteractionControlComponent]s will not enter a cooldown when they interact with this object.
## TIP: Convenient for implementing NPC dialogs with [TextInteractionComponent] etc. where the cooldown is on the NPC's side.
@export var shouldSkipInteractorCooldown: bool = false

## Initiate an interaction automatically as soon as any [InteractionControlComponent] comes in contact.
## Calls [method InteractionControlComponent.interact] on an [Area2D] collision event.
## Example: Portals or traps etc.
## ALERT: [InteractionControlComponent] may skip if on cooldown; Does not repeat interaction attempt after the cooldown resets.
@export var isAutomatic:	bool = false

## Allows [method performInteraction] to return `true` if [member payload] is missing.
## This allows components like [TextInteractionComponent] be their own payload.
@export var allowNoPayload:	bool


@export_group("UI")

## A [Node2D] or [Control] such as [Label] to display when this [InteractionComponent] is in collision contact with an [InteractionControlComponent].
# ALERT: If multiple InteractionComponents use the same indicator, the most recent component to run [method updateIndicator] will modify this label.
@export var interactionIndicator: CanvasItem

@export var shouldAlwaysShowIndicator:  bool ## Always show the indicator even when there is no [InteractionControlComponent] in collision.

## An optional short label, name or phrase to display in the UI for this interaction.
## Example: "Open Door" or "Chop Tree".
## Used by [method updateIndicator] to automatically update the [member interactionIndicator] if it's a [Label].
@export var text: String:
	set(newValue):
		if newValue != text:
			text = newValue
			if self.is_node_ready() and interactionIndicator is Label: updateIndicator()

## An optional detailed description of the interaction to display in the UI.
## Example: "Chopping a tree requires an Axe and grants 2 Wood"
## If the [member interactionIndicator] is a [Control] then it's [member Control.tooltip_text] is also set to this string.
@export var description: String:
	set(newValue):
		if newValue != description:
			description = newValue
			if interactionIndicator is Control: interactionIndicator.tooltip_text = description

#endregion


#region State
## The number of InteractionControlComponent in collision contact.
var controllersInContactCount: int:
	get: return areasInContact.size()
#endregion


#region Signals
signal didEnterInteractionArea	(entity: Entity, interactionControlComponent: InteractionControlComponent)
signal didExitInteractionArea	(entity: Entity, interactionControlComponent: InteractionControlComponent)
signal didDenyInteraction		(interactorEntity: Entity)
signal willPerformInteraction	(interactorEntity: Entity)
signal didPerformInteraction	(interactorEntity: Entity, result: Variant) ## Contains the result of the [Payload] or `null` if no Payload.
#endregion


#region Property Get/Set
func setIsEnabled(newValue: bool) -> void:
	# TBD: Toggle `Area2D.monitoring`?
	super.setIsEnabled(newValue)
	updateIndicator()
#endregion


func _ready() -> void:
	self.shouldMonitorBodies = false # TBD: Just let it be customizable from the scene?

	super._ready() # Prep the AreaContactComponent stuff

	# Set the initial state of the indicator
	# NOTE: Update content even if not `isEnabled` and hidden, just in case
	if interactionIndicator:
		if interactionIndicator is Control: interactionIndicator.tooltip_text = self.description
		interactionIndicator.visible = isEnabled and (shouldAlwaysShowIndicator or controllersInContactCount > 0) # Start invisible if false

		if interactionIndicator is Label:
			# NOTE: If our `text` property is empty, save any existing text as the default, so we can restore it after any temporary modifications such as by [InteractionWithCooldownComponent] etc.
			if self.text.is_empty(): self.text = interactionIndicator.text
			else: updateIndicator() # Otherwise set the UI to our string


## IMPORTANT: Subclasses that override this method to add extra functionality MUST also update the visibility or call super
func updateIndicator() -> void:
	# TBD: Check if any InteractionControlComponent is in contact before showing the indicator? but get_overlapping_areas() may be too expensive..
	if not interactionIndicator: return

	interactionIndicator.visible = isEnabled and (shouldAlwaysShowIndicator or controllersInContactCount > 0)

	## If the [interactionIndicator] is a [Label], display our [member text]
	## NOTE: Do not check text.is_empty() so an empty string may be used to clear the UI
	## IMPORTANT: Update the text whether it's visible or not, in case it's needed elsewhere
	if  interactionIndicator is Label:
		interactionIndicator.text = self.text


#region Area Collision Events

## Checks if an [Area2D] is an [InteractionControlComponent]
## Subclasses may override this function to specify different conditions.
## ALERT: PERFORMANCE: The default implementation does NOT check [member shouldMonitorAreas] or [isEnabled] or duplicate areas already in [areasInContact]
func shouldIncludeArea(areaToCheck: Area2D) -> bool:
	# NOTE: Don't check isEnabled so we can still allow exits
	return  is_instance_of(areaToCheck, InteractionControlComponent) \
			and not (areaToCheck == entity or entity.is_ancestor_of(areaToCheck)) \
			and (groupToInclude.is_empty() or areaToCheck.is_in_group(groupToInclude))


func shouldIncludeBody(_bodyToCheck: Node2D) -> bool:
	return false # We don't deal in [PhysicsBody2D] or [TileMapLayer] collisions


## Handles collisions with [InteractionControlComponent]
func onCollide(collidingNode: Node2D) -> void:
	var interactionControlComponent: InteractionControlComponent = collidingNode.get_node(^".") as InteractionControlComponent # HACK: Find better way to cast self?
	if not interactionControlComponent: return
	if debugMode: printDebug(str("onCollide(): ", collidingNode, ", interactionControlComponent: ", interactionControlComponent.logNameWithEntity, ", isAutomatic: ", isAutomatic))
	
	if self.interactionIndicator: updateIndicator() # Display the indicators and labels, if any
	didEnterInteractionArea.emit(interactionControlComponent.entity, interactionControlComponent)
	if self.isAutomatic: performAutomaticInteraction(interactionControlComponent) # Separate method so subclasses may override it


## Handles collisions with [InteractionControlComponent]
func onExit(exitingNode: Node2D) -> void:
	# NOTE: Exits should not check isEnabled to ensure cleanups are always performed.
	var interactionControlComponent: InteractionControlComponent = exitingNode.get_node(^".") as InteractionControlComponent # HACK: Find better way to cast self?
	if not interactionControlComponent: return
	if debugMode: printDebug(str("onExit(): ", exitingNode, ", interactionControlComponent: ", interactionControlComponent.logNameWithEntity))

	if self.interactionIndicator: updateIndicator() # Hide the indicators and labels.
	didExitInteractionArea.emit(interactionControlComponent.entity, interactionControlComponent)

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


## Executes the [member payload], passing this [InteractionComponent] as the `source` parameter of the [Payload], and the [param interactorEntity] as the `target`.
## May be overridden by a subclass to perform custom actions.
## NOTE: The return value of this method may be different than the "raw" result of the Payload included in [signal didPerformInteraction]
## Returns: The result of [method Payload.execute] or `null` if the [member payload] is missing, or `true` if no Payload but [member allowNoPayload] is enabled.
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> Variant:
	if debugMode: printDebug(str("performInteraction() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent, ", payload: ", (payload.logName if payload else "null"), ", isEnabled: ", isEnabled, ", allowNoPayload: ", allowNoPayload))
	if not isEnabled: return false

	# DESIGN: The value in the signal and this function's return value are not the same thing;
	# the signal contains the "raw" result of the Payload;
	# but this function may be the result, `true` if missing & `allowNoPayload`, or `null`
	var payloadResult: Variant = null

	if payload or allowNoPayload: # TBD: Emit signals even if no `payload` & no `allowNoPayload`?
		self.willPerformInteraction.emit(interactorEntity)
		# TBD: Add an executePayload() hook here for subclasses?
		payloadResult = payload.execute(self, interactorEntity) if payload else null # NOTE: Keep `null` and NOT `true`; the `true` is for the function result if `allowNoPayload`
		self.didPerformInteraction.emit(interactorEntity, payloadResult) # TBD: Make it the same as the function result, i.e. `true` if missing & `allowNoPayload`?

	# DESIGN: Return `true` if missing & allowNoPayload, to let components like [TextInteractionComponent] be their own payload.
	if   payload:		 return payloadResult
	elif allowNoPayload: return true
	else:				 return null # TBD: Return `false` if missing? `null` makes more sense; non-existence or "not-even-wrong"


## Called by [method onArea_entered] if [member isAutomatic].
## Implemented as a separate method so that subclasses mat override it.
## NOTE: Does NOT check [member isAutomatic]; must be checked by caller.
## NOTE: HEADSUP: Remember to set [member previousInteractor] = [member interactionControlComponent] if using [method startCooldown].
func performAutomaticInteraction(interactionControlComponent: InteractionControlComponent) -> void:
	# TODO: Handle InteractionControlComponent cooldown
	# NOTE: If InteractionComponent.onArea_entered() runs before InteractionControlComponent's collision events,
	# then the InteractionControlComponent will not have this component in `areasInContact` yet
	# so we must set `ignoreRange` when calling interact()
	interactionControlComponent.interact(self, true) # ignoreRange # Interact only with me senpai!

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
