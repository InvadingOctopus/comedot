## Allows the player to interact with an [InteractionComponent].
## "Interactions" are similar to "Collectibles"; the difference is that an interaction occurs on a button input instead of automatically on a collision.
## NOTE: To edit the [CooldownTimer], enable "Editable Children" 
## TIP: To perform interactions with the mouse, use [InteractionMouseControlComponent]
## Requirements: This component's node must be an [Area2D]

class_name InteractionControlComponent
extends AreaContactComponent


#region Parameters

## The limit of [InteractionComponent]s in range that may be interacted with in a single interaction.
## ALERT: A low limit may cause behavior that seems like bugs in case of nultiple [InteractionComponent]s with overlapping [Area2D]s.
@export_range(1, 100, 1) var maximumSimultaneousInteractions: int = 1

@export var inputEventName:			StringName = GlobalInput.Actions.interact

## If `true` then there is a short delay in case of a failed interaction, to prevent UI/network spamming etc.
## NOTE: DESIGN: This may start EVEN if the interaction is NOT successful, as this represents the "rest" between "attempts" e.g. pulling a lever to open a door.
@export var shouldCooldownOnFailure:				 bool  = true
@export_range(0.0, 60.0, 0.1) var cooldownOnFailure: float = 0.5

## A [Node2D] or [Control] to display when this [InteractionControlComponent] is within the range of an [InteractionComponent]
## NOTE: This is the indicator for the character that performs the interaction! This may display messages such as "Push Y to Talk" etc.
## [InteractionComponent]s have their own [InteractionComponent.interactionIndicator] to display messages such as "! Quest Available" etc.
@export var interactorIndicator:	CanvasItem

#endregion


#region State

@onready var cooldownTimer: CooldownTimer = $CooldownTimer

var haveInteracionsInRange: bool:
	get: return self.areasInContact.size() >= 1

func setIsEnabled(newValue: bool) -> void:
	super.setIsEnabled(newValue)
	if self.is_node_ready():
		# set_deferred() to avoid Godot error: "Function blocked during in/out signal"
		# UNUSED: Done by AreaCollisionComponent: area.set_deferred(&"monitoring",  isEnabled)
		area.set_deferred(&"monitorable", isEnabled) # Not done by AreaCollisionComponent
		updateIndicator()

#endregion


#region Signals
signal didEnterInteractionArea	(entity: Entity, interactionComponent: InteractionComponent)
signal didExitInteractionArea	(entity: Entity, interactionComponent: InteractionComponent)
signal willPerformInteraction	(entity: Entity, interactionComponent: InteractionComponent)
signal didPerformInteraction	(result: Variant)
#endregion


func _ready() -> void:
	# Some checks to avoid bugrisks just in case the .tscn scene didn't get it right
	if debugMode:
		if self.inputEventName != GlobalInput.Actions.interact:
			printWarning(str("inputEventName: ", inputEventName, " ≠ GlobalInput.Actions.interact: \"", GlobalInput.Actions.interact, "\" ・ Ignore if intendend"))
		if not self.groupToInclude.is_empty() and self.groupToInclude != Global.Groups.interactions: # Ignore empty strings
			printWarning(str("groupToInclude: ", groupToInclude, " ∉ Global.Groups.interactions: \"", Global.Groups.interactions, "\" ・ Ignore if intendend"))

	if interactorIndicator: interactorIndicator.visible = false # Set the initial state of the indicator
		# updateIndicator() will be called by resetContactLists()

	super._ready()


func resetContactLists() -> void:
	super.resetContactLists()
	if interactorIndicator: updateIndicator()


#region Area Collision Events

## Checks if an [Area2D] is an [InteractionComponent]
## Subclasses may override this function to specify different conditions.
## ALERT: PERFORMANCE: The default implementation does NOT check [member shouldMonitorAreas] or [isEnabled] or duplicate areas already in [areasInContact]
func shouldIncludeArea(areaToCheck: Area2D) -> bool:
	# NOTE: Don't check isEnabled so we can still allow exits
	return  is_instance_of(areaToCheck, InteractionComponent) \
			and not (areaToCheck == entity or entity.is_ancestor_of(areaToCheck)) \
			and (groupToInclude.is_empty() or areaToCheck.is_in_group(groupToInclude))


func shouldIncludeBody(_bodyToCheck: Node2D) -> bool:
	return false # We don't deal in [PhysicsBody2D] or [TileMapLayer] collisions


## Handles collisions with [InteractionComponent]
func onCollide(collidingNode: Node2D) -> void:
	var interactionComponent: InteractionComponent = collidingNode.get_node(^".") as InteractionComponent # HACK: Find better way to cast self?
	if not interactionComponent: return
	if debugMode: printDebug(str("onCollide(): ", collidingNode, ", interactionComponent: ", interactionComponent.logNameWithEntity, ", isAutomatic: ", interactionComponent.isAutomatic))

	updateIndicator()
	didEnterInteractionArea.emit(interactionComponent.entity, interactionComponent)


## Handles collisions with [InteractionComponent]
func onExit(exitingNode: Node2D) -> void:
	# NOTE: Exits should not check isEnabled to ensure cleanups are always performed.
	var interactionComponent: InteractionComponent = exitingNode.get_node(^".") as InteractionComponent # HACK: Find better way to cast self?
	if not interactionComponent: return
	if debugMode: printDebug(str("onCollide(): ", exitingNode, ", interactionComponent: ", interactionComponent.logNameWithEntity, ", isAutomatic: ", interactionComponent.isAutomatic))

	updateIndicator()
	didExitInteractionArea.emit(interactionComponent.entity, interactionComponent)


func updateIndicator() -> void:
	if  interactorIndicator:
		interactorIndicator.visible = isEnabled and haveInteracionsInRange

#endregion


#region Control

func _unhandled_input(_event: InputEvent) -> void: # TBD: _unhandled_input() or _input()?
	# TBD: Use InputComponent?
	if not isEnabled or cooldownTimer.isOnCooldown or not haveInteracionsInRange: return

	if Input.is_action_just_pressed(inputEventName): # TBD: Interact on PRESS or RELEASE?
		interactAll()
		self.get_viewport().set_input_as_handled()


## Interacts with all [InteractionComponent]s in collision contact, and starts the cooldown if any interaction succeeded,
## or the [member cooldownOnFailure] if no interaction succeeded.
## "Success" is determined by [method Tools.checkResult] i.e. not `null`, not `false`, not `empty`
## If [param continueOnFailure] is `false` then the first failure prevents the remaining interactions from being performed.
## TIP: To interact with a single [InteractionComponent], call [method interact].
## ALERT: BUGRISK: If an interaction moves the entity, like [PortalInteractionComponent], this method will continue interacting with all the interactions from the previous location!
## Returns: Number of successful interactions.
func interactAll(continueOnFailure: bool = true) -> int:
	# NOTE: TBD: If there are multiple interactions within range,
	# should they all be processed within a single cooldown?
	# Or should the first one start the cooldown, causing the other interactions to fail?

	if not isEnabled or cooldownTimer.isOnCooldown: return 0

	var count:		int = 0
	var successes:	int = 0
	var cooldowns:	int = 0 # The number of InteractionComponent with `shouldSkipInteractorCooldown`
	var failureCooldowns: int = 0

	for interactionComponent in self.areasInContact: # TBD: Keep updating `areasInContact` after each interaction in case an interaction moves the entity, like PortalInteractionComponent?
		if not is_instance_of(interactionComponent, InteractionComponent): continue # Just in case

		# Ask each interaction if it's ready and ok with us
		if interactionComponent.requestToInteract(self.entity, self):
			if debugMode: printDebug(str("interact() ", count + 1, " of ", maximumSimultaneousInteractions))

			self.willPerformInteraction.emit(interactionComponent.entity, interactionComponent)
			var result: Variant = interactionComponent.performInteraction(self.entity, self)

			count += 1 # TBD: Increase counter at start or end?
			self.didPerformInteraction.emit(result) # NOTE: Always emit the raw result even on failures

			if Tools.checkResult(result): # TODO: Add shouldSucceedIfNoPayload for "reactions" or whatever
				successes += 1
				if not interactionComponent.shouldSkipInteractorCooldown: cooldowns += 1
			else:
				if not interactionComponent.shouldSkipInteractorCooldown: failureCooldowns += 1 # Did we fail and the interaction allows cooldown? Then it's a `cooldownOnFailure`
				if not continueOnFailure: break

			if count >= maximumSimultaneousInteractions:
				# NOTE: Log skips in case `maximumSimultaneousInteractions` causes unexpected behavior that seems like bugs!
				if debugMode: printLog(str("BREAK: Performed ", count, " >= maximumSimultaneousInteractions: ", maximumSimultaneousInteractions, ", areasInContact: ", areasInContact.size(), ", SKIPPING ", areasInContact.size() - count))
				break

		elif not interactionComponent.shouldSkipInteractorCooldown: # TBD: Treat a rejection as a failure too?
				failureCooldowns += 1
				if not continueOnFailure: break

	if debugMode: printDebug(str("successes: ", successes, ", cooldowns: ", cooldowns, ", failureCooldowns: ", failureCooldowns))

	# NOTE: If there is ANY success, enter the "full" cooldown.
	# If there are no successes and any "failure cooldown" flags, start the "failure" cooldown (which should normally be shorter).

	if cooldowns > 0: cooldownTimer.startCooldown()
	elif shouldCooldownOnFailure and failureCooldowns > 0: cooldownTimer.startCooldown(cooldownOnFailure) # NOTE: Add a SHORT cooldown on a failed interaction, to prevent UI/network spamming etc.
	return successes


## Interacts with a single specific [InteractionComponent], starts a cooldown, and returns the result.
## TIP: To force an interaction even if its [Area2D] is not in range/physics contact, use [param ignoreRange].
## TIP: To interact with all [InteractionComponent]s in range, call [method interactAll].
func interact(interactionComponent: InteractionComponent, ignoreRange: bool = false) -> Variant:
	if not isEnabled or cooldownTimer.isOnCooldown: return null

	if not ignoreRange and not self.areasInContact.has(interactionComponent):
		printLog(str("Cannot interact, out of range: ", interactionComponent.entity.logFullName, " ", interactionComponent.logFullName))
		return null

	if debugMode: printLog(str("interact() with ", interactionComponent.entity.logFullName, " ", interactionComponent.logFullName))

	if interactionComponent.requestToInteract(self.entity, self):
		self.willPerformInteraction.emit(interactionComponent.entity, interactionComponent)
		var result: Variant = interactionComponent.performInteraction(self.entity, self)

		# Start the regular cooldown or the failure cooldown or neither?
		if not interactionComponent.shouldSkipInteractorCooldown:
			if Tools.checkResult(result): cooldownTimer.startCooldown()
			elif shouldCooldownOnFailure: cooldownTimer.startCooldown(cooldownOnFailure)

		if debugMode: printLog(str("Result: ", result, ", cooldown: ", cooldownTimer.time_left))
		self.didPerformInteraction.emit(result)
		return result

	else:
		if self.shouldCooldownOnFailure and not interactionComponent.shouldSkipInteractorCooldown: cooldownTimer.startCooldown(cooldownOnFailure)
		printLog(str("InteractionComponent: ", interactionComponent, " denied interaction with ", self.entity.logName, ", cooldown: ", cooldownTimer.time_left))

	return null

#endregion


#region Cooldown

## Called by [method CooldownTimer.startCooldown] and updates the [member interactorIndicator]
func onCooldownTimer_didStartCooldown(_time: float) -> void:
	if interactorIndicator: interactorIndicator.modulate.a = 0.1 # Fade while unusable


## Called by [method CooldownTimer.finishCooldown] and updates the [member interactorIndicator]
func onCooldownTimer_didFinishCooldown() -> void:
	if interactorIndicator: interactorIndicator.modulate.a = 1.0 # Fade in # TBD: Remember previous un-faded opacity?

#endregion


# DEBUG: func _process(delta: float) -> void:
	# DEBUG: showDebugInfo()


func showDebugInfo() -> void:
	Debug.watchList.set(str(self, ":Timer"), cooldownTimer.time_left)
