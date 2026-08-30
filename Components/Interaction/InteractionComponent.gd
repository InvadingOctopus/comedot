## Represents an area where an interaction may occur when the player inputs the interaction action.
## The initiator of an interaction is an [Entity]'s [InteractionControlComponent].
## For interactions that have a cooldown and a [Stat] cost on the object's side, use [InteractionWithCostComponent]
## Uses [AreaContactComponent] as a parent class for collision logic and contact-tracking.

class_name InteractionComponent
extends AreaContactComponent

# TBD: Inherit scene from AreaContactComponent.tscn too?
# CHECK: PERFORMANCE: Will too many inheritance levels impact performance?


#region Parameters

## The effect of the interaction, where this [InteractionComponent] is passed as the `source` for [method Payload.execute], and the [InteractionControlComponent]'s parent [Entity] is the `target`
## See [Payload] for explanation and available options.
## TIP: Interactions may succeed if [member allowNoPayload] even if there is no Payload; for example [TextInteractionComponent] performs its effects by itself.
@export var payload: Payload

## If `true` then [InteractionControlComponent]s will not enter a cooldown when they interact with this object.
## TIP: Convenient for implementing NPC dialogs with [TextInteractionComponent] etc. where the cooldown is on the NPC's side.
@export var shouldSkipInteractorCooldown: bool = false

## Initiate an interaction automatically as soon as any [InteractionControlComponent] comes in contact.
## Calls [method InteractionControlComponent.interact] on an [Area2D] collision event.
## TIP: May be used for portals or traps etc.
## ALERT: [InteractionControlComponent] may skip if on cooldown; Does not repeat interaction attempt after the cooldown resets.
@export var isAutomatic:	bool = false

## Allows [method performInteraction] to continue and return `true` even if [member payload] is missing.
## This allows components like [TextInteractionComponent] to be their own payload.
## Other subclasses may still require a valid [Payload] or ignore this flag.
@export var allowNoPayload:	bool


@export_group("UI")

## A [Node2D] or [Control] such as [Label] to display when this [InteractionComponent] is in collision contact with an [InteractionControlComponent]
## ALERT: If multiple InteractionComponents use the same indicator, the most recent component to run [method updateIndicator] will modify this label.
## NOTE:  This is the indicator for the entity that will be interacted with, such as a door or an NPC. This may display messages such as "Locked" or "! Quest available" etc.
## [InteractionControlComponent]s have their own [InteractionControlComponent.interactorIndicator] to display messages such as "Push Y to Talk" etc.
@export var interactionIndicator: CanvasItem

@export var shouldAlwaysShowIndicator:  bool ## Always show the indicator even when there is no [InteractionControlComponent] in collision.

## An optional short label, name or phrase to display in the UI for this interaction.
## Example: "Open Door" or "Chop Tree".
## Used by [method updateIndicator] to automatically update the [member interactionIndicator] if it's a [Label]
## TIP: For more detailed instructions, use [member description]
@export var text: String:
	set = setText # Use a separate function for the setter to let subclasses override it

## An optional detailed description of the interaction to display in the UI, different from the [member text]
## Example: "Chopping a tree requires an Axe and grants 2 Wood"
## If the [member interactionIndicator] is a [Control] then its [member Control.tooltip_text] is also set to this string.
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

## Emitted by [method performInteraction] containing the result of [method executePayload]
## NOTE: NOT emitted if not [member isEnabled] or if [member payload] is missing and not [member allowNoPayload]
## TIP: Connect to [signal Payload.didExecute] etc. to monitor the [member payload]
signal didPerformInteraction	(interactorEntity: Entity, result: Variant)
#endregion


#region Property Get/Set

func setIsEnabled(newValue: bool) -> void:
	# TBD: Toggle `Area2D.monitoring`?
	super.setIsEnabled(newValue)
	updateIndicator()

## Sets [member text] and updates the [member interactionIndicator] if this component is ready.
## May be overridden by subclasses to customize how their text is displayed.
func setText(newValue: String) -> void:
	if newValue != text:
		text = newValue
		if self.is_node_ready() and interactionIndicator is Label: updateIndicator()

#endregion


func _ready() -> void:
	self.shouldMonitorBodies = false # TBD: Just let it be customizable from the scene?
	super._ready() # Prep the [AreaContactComponent] stuff
	initializeIndicator()


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

## Called by an [InteractionControlComponent] before calling [method performInteraction]
## When the player presses the Interact button, the [InteractionControlComponent] checks its own conditions then calls this method on the [InteractionComponent](s) in range.
## Then this [InteractionComponent] calls [method checkInteractionConditions] to check the interaction's conditions,
## such as whether the player has a key to open a door, or an axe to chop a tree.
## NOTE: Returns `false` if not [member isEnabled] BUT [signal didDenyInteraction] is NOT emitted; a disabled component is basically treated as non-existent.
## ALERT: BUGRISK: [signal didDenyInteraction] + a `false` return report the SAME rejection; callers & signal handlers must not count them as 2 separate failures.
## ALERT: This method should generally NOT be overridden by subclasses;
## TIP: Override [method checkInteractionConditions] to add subclass-specific conditions.
func requestToInteract(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	if not isEnabled: return false
	if checkInteractionConditions(interactorEntity, interactionControlComponent):
		return true
	else:
		didDenyInteraction.emit(interactorEntity)
		return false


## Calls and returns the result of [method executePayload], passing this [InteractionComponent] as the `source` argument for the [Payload], and the [param interactorEntity] as the `target`
## Returns `false` if not [member isEnabled]
## Returns `null` if there is no [member payload] & not [member allowNoPayload]
## DESIGN: [method performInteraction] does NOT recheck all the game-specific conditions verified by [method requestToInteract] & [method checkInteractionConditions]; only [member isEnabled] and [Payload] validation is done here.
## ALERT: This method should generally NOT be overridden by game-specific subclasses;
## TIP: Override [method executePayload] to perform custom actions.
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> Variant:
	if debugMode:
		printDebug(str("performInteraction() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent, ", payload: ", (payload.logName if payload else "null"), ", isEnabled: ", isEnabled, ", allowNoPayload: ", allowNoPayload))
		if interactionControlComponent.entity != interactorEntity: printWarning(str("interactorEntity: ", interactorEntity, " != interactionControlComponent.entity: ", interactionControlComponent.entity))
	if not isEnabled: return false
	if not payload and not allowNoPayload: return null

	self.willPerformInteraction.emit(interactorEntity)
	var  result: Variant = self.executePayload(interactorEntity, interactionControlComponent)
	self.didPerformInteraction.emit(interactorEntity, result)

	return result


## Executes the [member payload], passing this [InteractionComponent] as the `source` parameter of the [Payload], and the [param interactorEntity] as the `target`
## Returns the result of [method Payload.execute] if there is a [member payload],
## or returns `true` if there is no [member payload] but [member allowNoPayload] is set, to allow for custom/signal-driven interactions etc.
## otherwise returns `false`
## TIP: May be overridden by a subclass to perform custom actions.
## NOTE: The return value of this method may be different than the "raw" result of the [member payload]
@warning_ignore("unused_parameter")
func executePayload(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> Variant:
	# DESIGN: Return `true` if missing & `allowNoPayload`
	# to let components like [TextInteractionComponent] be their own payload.
	return payload.execute(self, interactorEntity) if payload else allowNoPayload


## Called by [method onCollide] if [member isAutomatic]
## Implemented as a separate method so that subclasses may override it.
## NOTE: Does NOT check [member isAutomatic]; must be checked by caller.
func performAutomaticInteraction(interactionControlComponent: InteractionControlComponent) -> void:
	# TODO: Handle InteractionControlComponent cooldown
	# NOTE: If InteractionComponent.onCollide() runs before InteractionControlComponent's collision events,
	# then the InteractionControlComponent will not have this component in `areasInContact` yet
	# so we must set `ignoreRange` when calling interact()
	interactionControlComponent.interact(self, true) # ignoreRange # Interact only with me senpai!

#endregion


#region Indicator

## Sets the initial state & content of the [member interactionIndicator]
## May be customized by subclasses.
## IMPORTANT: Overrides MUST call `super.initializeIndicator()`
func initializeIndicator() -> void:
	if not interactionIndicator: return

	# NOTE: Update content even if not `isEnabled` and hidden, just in case
	if interactionIndicator is Control: interactionIndicator.tooltip_text = self.description
	interactionIndicator.visible = isEnabled and (shouldAlwaysShowIndicator or controllersInContactCount > 0) # Start invisible if false

	if  interactionIndicator is Label:
		# NOTE: If our `text` property is empty, save any existing text as the default, so we can restore it after any temporary modifications such as by [InteractionWithCooldownComponent] etc.
		if self.text.is_empty(): self.text = interactionIndicator.text
		else: updateIndicator() # Otherwise set the UI to our string


## IMPORTANT: Subclasses that override this method to add extra functionality MUST also update the visibility or call super
func updateIndicator() -> void:
	if not interactionIndicator: return

	# Check if any [InteractionControlComponent] is in contact before showing the indicator
	interactionIndicator.visible = isEnabled and (shouldAlwaysShowIndicator or controllersInContactCount > 0)

	## If the [interactionIndicator] is a [Label], display our [member text]
	## NOTE: Do not check text.is_empty() so an empty string may be used to clear the UI
	## IMPORTANT: Update the text whether it's visible or not, in case it's needed elsewhere
	if  interactionIndicator is Label:
		interactionIndicator.text = self.text

#endregion


#region Virtual Methods

## May be overridden in a subclass to approve or deny an interaction.
## Returns: [member isEnabled] by default.
func checkInteractionConditions(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	# TBD: Maybe a better name? :p
	if debugMode: printDebug(str("checkInteractionConditions() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent))
	return isEnabled

#endregion
