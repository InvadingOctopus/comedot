## Allows the player to interact with an [InteractionComponent].
## "Interactions" are similar to "Collectibles"; the difference is that an interaction occurs on a button input instead of automatically on a collision.
## TIP: To perform interactions with the mouse, use [InteractionMouseControlComponent].
## Requirements: This component's node must be an [Area2D]

class_name InteractionControlComponent
extends CooldownComponent

# TODO: Update indicator only on collision events.
# TBD:  Check interaction success?

#region Parameters

## The limit of [InteractionComponent]s in range that may be interacted with in a single interaction.
## ALERT: A low limit may cause behavior that seems like bugs in case of nultiple [InteractionComponent]s with overlapping [Area2D]s.
@export_range(1, 100, 1) var maximumSimultaneousInteractions: int = 1

@export var inputEventName: StringName = GlobalInput.Actions.interact

@export var shouldCooldownOnFailure: bool = true ## If `true` then there is a short delay in case of a failed interaction, to prevent UI/network spamming etc.
@export_range(0.0, 60.0, 0.1) var cooldownOnFailure: float = 0.5

@export var interactionIndicator: Node ## A [Node2D] or [Control] to display when this [InteractionControlComponent] is within the range of an [InteractionComponent].

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue
		# AVOID: self.visible = isEnabled # Don't hide self in case some child visual effect nodes are present!
		if  selfAsArea:
			# NOTE: Cannot set flags directly because Godot error: "Function blocked during in/out signal"
			selfAsArea.set_deferred(&"monitoring",  isEnabled)
			selfAsArea.set_deferred(&"monitorable", isEnabled)
		updateIndicator()

#endregion


#region State

var interactionsInRange: Array[InteractionComponent]

var haveInteracionsInRange: bool:
	get: return self.interactionsInRange.size() >= 1

var selfAsArea: Area2D:
	get:
		if not selfAsArea: selfAsArea = self.get_node(^".") as Area2D
		return selfAsArea

#endregion


#region Signals
signal didEnterInteractionArea	(entity: Entity, interactionComponent: InteractionComponent)
signal didExitInteractionArea	(entity: Entity, interactionComponent: InteractionComponent)
signal willPerformInteraction	(entity: Entity, interactionComponent: InteractionComponent)
signal didPerformInteraction	(result: Variant)
#endregion


func _ready() -> void:
	# Set the initial state of the indicator
	if interactionIndicator:
		interactionIndicator.visible = false
		updateIndicator()
	if  selfAsArea: # Apply setter because Godot doesn't on initialization
		selfAsArea.monitoring  = isEnabled
		selfAsArea.monitorable = isEnabled


#region Area Collision Events

func onArea_entered(area: Area2D) -> void:
	if not isEnabled: return
	var interactionComponent: InteractionComponent = area.get_node(^".") as InteractionComponent # HACK: Find better way to cast self?
	if not interactionComponent: return

	printDebug(self.logName + " onArea_entered: " + str(interactionComponent))

	self.interactionsInRange.append(interactionComponent)
	updateIndicator()
	didEnterInteractionArea.emit(interactionComponent.parentEntity, interactionComponent)


func onArea_exited(area: Area2D) -> void:
	# NOTE: Exits should not check isEnabled to ensure cleanups are always performed.
	var interactionComponent: InteractionComponent = area.get_node(^".") as InteractionComponent # HACK: Find better way to cast self?
	if not interactionComponent: return

	printDebug(self.logName + " onArea_exited: " + str(interactionComponent))

	self.interactionsInRange.erase(interactionComponent)
	updateIndicator()
	didExitInteractionArea.emit(interactionComponent.parentEntity, interactionComponent)


func updateIndicator() -> void:
	if interactionIndicator: 
		interactionIndicator.visible = isEnabled and haveInteracionsInRange

#endregion


#region Control

func _unhandled_input(_event: InputEvent) -> void: # TBD: _unhandled_input() or _input()?
	# TBD: Use InputComponent?
	if not isEnabled or not hasCooldownCompleted or not haveInteracionsInRange: return

	if Input.is_action_just_pressed(inputEventName):
		interactAll()
		self.get_viewport().set_input_as_handled()


## Interacts with all [InteractionComponent]s in collision contact, and starts the cooldown if any interaction succeeded,
## or the [member cooldownOnFailure] if no interaction succeeded.
## "Success" is determined by [method Tools.checkResult] (i.e. not null, not false, not empty)
## TIP: To interact with a single [InteractionComponent], call [method interact].
## Returns: Number of successful interactions.
func interactAll() -> int:
	# NOTE: TBD: If there are multiple interactions within range,
	# should they all be processed within a single cooldown?
	# Or should the first one start the cooldown, causing the other interactions to fail?

	if not isEnabled or not hasCooldownCompleted: return 0

	var count:		int = 0
	var successes:	int = 0
	var cooldowns:	int = 0 # The number of InteractionComponent with shouldSkipInteractorCooldown
	var failureCooldowns: int = 0
	
	for interactionComponent in self.interactionsInRange:
		if interactionComponent.requestToInteract(self.parentEntity, self):
			count += 1 # TBD: Increase counter at start or end?
			if debugMode: printDebug(str("interact() ", count, " of ", maximumSimultaneousInteractions))

			self.willPerformInteraction.emit(interactionComponent.parentEntity, interactionComponent)
			var result: Variant = interactionComponent.performInteraction(self.parentEntity, self)
			
			if Tools.checkResult(result):
				successes += 1
				if not interactionComponent.shouldSkipInteractorCooldown: cooldowns += 1
			elif not interactionComponent.shouldSkipInteractorCooldown: # Did we fail and the Interaction allows cooldown? Then it's a `cooldownOnFailure`
				failureCooldowns += 1

			self.didPerformInteraction.emit(result)
			
			if count >= maximumSimultaneousInteractions:
				# NOTE: Log skips in case `maximumSimultaneousInteractions` causes unexpected behavior that seems like bugs!
				if debugMode: printLog(str("BREAK: Performed ", count, " >= maximumSimultaneousInteractions: ", maximumSimultaneousInteractions, ", interactionsInRange: ", interactionsInRange.size(), ", SKIPPING ", interactionsInRange.size() - count))
				break

	if debugMode: printDebug(str("successes: ", successes, ", cooldowns: ", cooldowns, ", failureCooldowns: ", failureCooldowns))

	# NOTE: If there is ANY success, enter the "full" cooldown.
	# If there are no successes and any "failure cooldown" flags, start the "failure" cooldown (which should normally be shorter).
	
	if cooldowns > 0: startCooldown()
	elif shouldCooldownOnFailure and failureCooldowns > 0: startCooldown(cooldownOnFailure) # NOTE: Add a SHORT cooldown on a failed interaction, to prevent UI/network spamming etc.
	return successes


## Interacts with a single specific [InteractionComponent], starts a cooldown, and returns the result.
## TIP: To force an interaction even if its [Area2D] is not in range/physics contact, use [param ignoreRange].
## TIP: To interact with all [InteractionComponent]s in range, call [method interactAll].
func interact(interactionComponent: InteractionComponent, ignoreRange: bool = false) -> Variant:
	if not isEnabled or not hasCooldownCompleted: return null
	
	if not ignoreRange and not self.interactionsInRange.has(interactionComponent):
		printLog(str("Cannot interact, out of range: ", interactionComponent.parentEntity.logFullName, " ", interactionComponent.logFullName))
		return null

	if debugMode: printLog(str("interact() with ", interactionComponent.parentEntity.logFullName, " ", interactionComponent.logFullName))
	
	if interactionComponent.requestToInteract(self.parentEntity, self):
		self.willPerformInteraction.emit(interactionComponent.parentEntity, interactionComponent)
		var result: Variant = interactionComponent.performInteraction(self.parentEntity, self)
		if debugMode: printLog(str("Result: ", result, ", cooldown: ", self.cooldown if not interactionComponent.shouldSkipInteractorCooldown else 0.0))
		if not interactionComponent.shouldSkipInteractorCooldown: startCooldown()
		self.didPerformInteraction.emit(result)
		return result
	else:
		printLog(str("InteractionComponent: ", interactionComponent, " denied interaction with ", self.parentEntity.logName, ", cooldown: ", self.cooldownOnFailure if not interactionComponent.shouldSkipInteractorCooldown else 0.0))
		if not interactionComponent.shouldSkipInteractorCooldown: startCooldown(cooldownOnFailure)
	return null

#endregion


#region Cooldown

func startCooldown(overrideTime: float = self.cooldown) -> void:
	super.startCooldown(overrideTime)
	# Reduce the alpha
	if interactionIndicator: interactionIndicator.modulate.a = 0.1


func finishCooldown() -> void:
	super.finishCooldown()
	# Restore the alpha
	if interactionIndicator: interactionIndicator.modulate.a = 1.0

#endregion


# DEBUG: func _process(delta: float) -> void:
	# DEBUG: showDebugInfo()


func showDebugInfo() -> void:
	Debug.watchList.set(str(self, ":Timer"), cooldownTimer.time_left)
