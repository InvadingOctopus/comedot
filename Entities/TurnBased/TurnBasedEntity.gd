## Base class for turn-based entities. Performs actions by issuing commands to its child [TurnBasedComponent]s.
## Each turn, the [TurnBasedCoordinator] calls the [method processTurnBegin], [method processTurn] and [method processTurnEnd] methods on each entity in order.
##
## NOTE: The begin/update/end methods are NOT executed at once for a single entity:
## First, all entities perform the "Begin" phase: Entity1.processTurnBegin → Entity2.processTurnBegin ...
## THEN all entities perform "Update" phase, and so on.
##
## NOTE: A [TurnBasedEntity] should not manage turn-coordination state; that is the job of the [TurnBasedCoordinator].
## An entity should only call manage components and call their methods to perform the actual game actions.

class_name TurnBasedEntity
extends Entity # + TurnBasedObjectBase

# NOTE: DESIGN: This class is almost identical to [TurnBasedComponent] and there is a lot of code duplication
# because classes can't have multiple inheritance; it would need to extend both [Entity] and [TurnBased] :')


#region Parameters
@export var isEnabled: bool = true

## The turn-based "speed" of this entity: How many game turns it takes for this entity to "move" or play 1 turn.
## Example: If [member turnRatio] is 2, then this entity is at "half speed": It plays 1 turn every 2 game turns.
## NOTE: Changing this value does NOT automatically update [member turnsToSkip]!
@export_range(1, 100, 1, "or_greater") var turnRatio: int = 1:
	set(newValue):
		if newValue < 1: newValue = 1
		if newValue != turnRatio:
			if debugMode: Debug.printChange("turnRatio", turnRatio, newValue, false) # not logAsTrace
			turnRatio = newValue
			# TBD: Update `turnsToSkip`?

#endregion


#region State

@export_storage var turnBasedComponents: Array[TurnBasedComponent]

## Returns: [TurnBasedCoordinator.currentTurn]
var currentTurn: int:
	get: return TurnBasedCoordinator.currentTurn
	set(newValue): printError("currentTurn should not be set; use TurnBasedCoordinator") # TEMP: To catch bugs

## Returns: [TurnBasedCoordinator.currentTurnState]
var currentTurnState: TurnBasedCoordinator.TurnBasedState:
	get: return TurnBasedCoordinator.currentTurnState
	set(newValue): printError("currentTurnState should not be set; use TurnBasedCoordinator") # TEMP: To catch bugs

## Returns: [TurnBasedCoordinator.turnsProcessed]
var turnsProcessed: int:
	get: return TurnBasedCoordinator.turnsProcessed
	set(newValue): printError("turnsProcessed should not be set; use TurnBasedCoordinator") # TEMP: To catch bugs

## This entity may only play a turn when this value is 0,
## otherwise it skips [method processTurnBeginSignals], [method processTurnUpdateSignals], and [method processTurnEndSignals].
## Decremented by 1 at the start of every [method processTurnEndSignals] call.
## Reset to the [member turnRatio] at the end of [method processTurnEndSignals], if the ratio is higher than 1, which means a slower turn "speed" for this entity.
@export_storage var turnsToSkip: int = self.turnRatio - 1: # -1 because if the turn "speed" is 1, then 0 turns to skip.
	set(newValue):
		if newValue < 0: newValue = 0
		if newValue != turnsToSkip:
			if debugMode: Debug.printChange("turnsToSkip", turnsToSkip, newValue, false) # not logAsTrace
			turnsToSkip = newValue

#endregion


#region Signals
# See [TurnBasedCoordinator] comments for explanation of signals.
# TBD: didSkipTurn?

signal willBeginTurn
signal didBeginTurn

signal willUpdateTurn
signal didUpdateTurn

signal willEndTurn
signal didEndTurn
#endregion


func _enter_tree() -> void:
	super._enter_tree()
	self.resetSkipCounter()
	self.add_to_group(Global.Groups.turnBased, true) # IMPORTANT: Add to turn-based group BEFORE calling `TurnBasedCoordinator.addEntity()` in case the coordinator operates on that group.
	TurnBasedCoordinator.addEntity(self)


func _exit_tree() -> void:
	TurnBasedCoordinator.removeEntity(self)
	super._exit_tree()


#region Turn State Cycle

# `await` on `self.processTurn…` ensures animations and any other delays are properly processed in order.

## Called by the [TurnBasedCoordinator] and calls [method processTurnBegin].
## Skipped if [member turnsToSkip] > 0.
## WARNING: Do NOT override in subclass.
func processTurnBeginSignals() -> void:
	if not isEnabled or not checkSkipCounter("willBeginTurn"): return
	if debugMode:
		printLog(str("processTurnBeginSignals() willBeginTurn ", currentTurn))
		TextBubble.create(str("turnBegin ", currentTurn), self)

	willBeginTurn.emit()
	await self.processTurnBegin()

	if debugMode: printLog("didBeginTurn")
	didBeginTurn.emit()


## Called by the [TurnBasedCoordinator] and calls [method processTurnUpdate].
## Skipped if [member turnsToSkip] > 0.
## WARNING: Do NOT override in subclass.
func processTurnUpdateSignals() -> void:
	if not isEnabled or not checkSkipCounter("willUpdateTurn"): return
	if debugMode:
		printLog(str("processTurnUpdateSignals() willUpdateTurn ", currentTurn))
		TextBubble.create(str("turnUpdate ", currentTurn), self)

	willUpdateTurn.emit()
	await self.processTurnUpdate()

	if debugMode: printLog("didUpdateTurn")
	didUpdateTurn.emit()


## Called by the [TurnBasedCoordinator] and calls [method processTurnEnd].
## Skipped if [member turnsToSkip] > 0. Decrements or resets [member turnsToSkip].
## WARNING: Do NOT override in subclass.
func processTurnEndSignals() -> void:
	if not isEnabled: return

	# NOTE: If this is a skipped turn, the final phase should also decrement or reset the skip counter,
	# so that the NEXT turn's processTurnBeginSignals() will be able to run.
	if not checkSkipCounter("willEndTurn"):
		updateSkipCounter()
		return

	if debugMode:
		printLog(str("processTurnEndSignals() willEndTurn ", currentTurn))
		TextBubble.create(str("turnEnd ", currentTurn), self)

	willEndTurn.emit()
	await self.processTurnEnd()

	# NOTE: If the "speed" is slower than 1:1, reset the skip counter at the END of a PLAYED turn,
	# to skip the NEXT turn.
	if turnRatio > 1: updateSkipCounter()

	if debugMode: printLog("didEndTurn")
	didEndTurn.emit()


# Turn Speed/Skipping...

## Checks [member turnRatio] and [member turnsToSkip].
## Returns `true` if the entity is ready to take a turn.
func checkSkipCounter(phaseMessage: String = "turn") -> bool:
	if   turnsToSkip <= 0: return true # DESIGN: Do not check `turnRatio` here; it should be used only for setting `turnsToSkip`
	elif turnsToSkip  > 0: printLog(str("checkSkipCounter() turnsToSkip: ", turnsToSkip, ": Skipping ", phaseMessage)) # Log the turn phase from during this function was called.

	return false


## Decrements OR resets [member turnsToSkip] and returns the updated value.
## IMPORTANT: Should be called at the END of a turn, during [method processTurnEndSignals].
func updateSkipCounter() -> int:
	# NOTE:   Do NOT decrement AND reset during the same call!
	# DESIGN: The decrement should happen at the END of a SKIPPED turn,
	# and the reset should happen at the end of a PLAYED turn.

	# If there are any turn skips to skip, decrement the counter,
	# because this function is assumed to be called at the end of an already skipped turn.
	if  turnsToSkip  >= 1:
		turnsToSkip  -= 1 ## TBD: Add an variable decrement step for temporarily modifying the turn-based speed?

	# Otherwise if the counter is at 0, then a countdown already elapsed during the previous turn's End phase.
	# Example: If the `turnRatio` is 2, then this will be true in Turn 2.
	elif turnsToSkip <= 0:
		var previousTurnsToSkip: int = turnsToSkip
		resetSkipCounter() # Reenable the skip counter so the next turn will be skipped.
		printLog(str("updateSkipCounter() Reset turnsToSkip: ", previousTurnsToSkip, " → ", turnsToSkip))

	return turnsToSkip


## Sets [member turnsToSkip] tp [member turnsToSkip] minus 1.
## i.e., because if the turn "speed" is 1, then there are 0 turns to skip.
func resetSkipCounter() -> void:
	turnsToSkip = turnRatio - 1

#endregion


#endregion Component Process Cycle

# NOTE: Use `await` to allow any visual components to perform animations etc.


## Calls [method TurnBasedComponent.processTurnBeginSignals] on all child components.
func processTurnBegin() -> void:
	if not self.isEnabled: return
	for turnBasedComponent in self.turnBasedComponents:
		await turnBasedComponent.processTurnBeginSignals()


## Calls [method TurnBasedComponent.processTurnUpdateSignals] on all child components.
func processTurnUpdate() -> void:
	if not self.isEnabled: return
	for turnBasedComponent in self.turnBasedComponents:
		await turnBasedComponent.processTurnUpdateSignals()


## Calls [method TurnBasedComponent.processTurnEndSignals] on all child components.
func processTurnEnd() -> void:
	if not self.isEnabled: return
	for turnBasedComponent in self.turnBasedComponents:
		await turnBasedComponent.processTurnEndSignals()

#endregion


#region Component Management

func registerComponent(newComponent: Component) -> bool:
	if super.registerComponent(newComponent):
		# Also register the component in our array if it is turn-based
		if is_instance_of(newComponent, TurnBasedComponent):
			self.turnBasedComponents.append(newComponent)
		return true # Return `true` even if a non-turn-based component was registered by the Entity superclass.
	else:
		return false


func unregisterComponent(componentToRemove: Component) -> bool:
	var didUnregister: bool = super.unregisterComponent(componentToRemove)
	# Also remove the component from our array if it is turn-based
	if didUnregister and is_instance_of(componentToRemove, TurnBasedComponent):
		self.turnBasedComponents.erase(componentToRemove)
		return true
	else:
		return didUnregister


## Searches all children and returns an array of all nodes that extend [TurnBasedComponent].
## NOTE: May be slow. Use the [member turnBasedComponents] array instead.
func findTurnBasedComponents() -> Array[TurnBasedComponent]:
	return self.findChildrenOfType(TurnBasedComponent)

#endregion


func printLog(message: String = "", object: Variant = self.logName) -> void:
	if not isLoggingEnabled: return
	# Customize logs for turn-based entities to include the turn+phase, because it's not related to frames.
	Debug.printLog(message, str(object, " ", TurnBasedCoordinator.logStateIndicator, self.currentTurn), "lightGreen", "green")


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList.turnsProcessed	= turnsProcessed
	Debug.watchList.currentTurn		= currentTurn
	Debug.watchList.currentTurnState= currentTurnState
	Debug.watchList.turnRatio		= turnRatio
	Debug.watchList.turnsToSkip		= turnsToSkip
