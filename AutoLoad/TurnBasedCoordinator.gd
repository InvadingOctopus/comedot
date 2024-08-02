## Manages turn-based gameplay and updates [TurnBasedEntity]s.
## Each turn has 3 phases: Begin, Update, End.
## To execute the turn and advance to the next, the game's control system (such as a "Next Turn" button or the player's directional input) must call [method startTurnProcess].
##
## During each phase, the corresponding Begin/Update/End methods are called on all turn-based entities in order:
## The entities then call the corresponding methods on each of their [TurnBasedComponent]s.
## First, all objects perform the Begin methods, then all objects perform the Update methods, and so on.
##
## See the documentation for [TurnBasedEntity] and [TurnBasedComponent] for further details.

#class_name TurnBasedCoordinator
extends Node # + TurnBasedObjectBase

# PLAN:
# * Each turn has three "states" or "phases": Begin, Update, End
# * Every turn must cycle through all 3 states
# 	This helps game objects to play animations, perform actions, and do any setup/cleanup in the proper order every turn.
# 	NOTE: An Entity must NOT execute Begin → Update → End all at once before the next Entity is updated; 
	# because that would be effectively just like executing only 1 method per Entity.
# * The Coordinator must call `turnBegin()` on all entities, THEN `turnUpdate()` on all entities, THEN `turnEnd()` on all entities.
# * Each Entity must then call the same order on all its child components.
# * After the `turnEnd` phase, the Coordinator must increment the turn counter and return to the `turnBegin` phase again, BUT it must NOT be executed until the game receives the control input to play the next turn.

# TODO: Verify Entity-side animation delays etc.
# TODO: A cleaner, simplified, reliable implementation? :')
# TODO: Support for multiple TurnBasedCoordinators in the same scene, e.g. to support multiplayer games.


#region Constants

## The "phases" of each turn: the Beginning, the Update, and the End.
## The different states allow gameplay components to intercept and modify each other at different points during the turn update cycle.
## For example, a poison damage-over-time component may apply damage at the END of a character's turn,
## but a healing-over-time component may increase the health at the START of a turn.
enum TurnBasedState { # TBD: Should this be renamed to "Phase"?
	turnInvalid	= -1,
	turnBegin	= 0,
	turnUpdate	= 1,
	turnEnd		= 2}
	
#endregion


#region Parameters

## The delay after updating each [TurnBasedEntity]. May be used for aesthetics or debugging.
@export var delayBetweenEntities: float = 1: # TODO: Make this a flag in Start.gd
	set(newValue):
		delayBetweenEntities = newValue
		if entityTimer: entityTimer.wait_time = newValue

## The delay after each [enum TurnBasedState]. May be used for debugging.
## NOTE: The delay will occur BEFORE the [member currentTurnState] is incremented.
@export var delayBetweenStates: float = 0.1: # TODO: Make this a flag in Start.gd
	set(newValue):
		delayBetweenStates = newValue
		if stateTimer: stateTimer.wait_time = newValue

@export var shouldShowDebugInfo: bool = false # TODO: Make this a flag in Start.gd

#region


#region State

@onready var stateTimer:  Timer = $StateTimer
@onready var entityTimer: Timer = $EntityTimer

## NOTE: This depends on [TurnBasedEntity]s to add & remove themselves in [method TurnBasedEntity._enter_tree] & [method TurnBasedEntity._exit_tree]
@export_storage var turnBasedEntities: Array[TurnBasedEntity]

## The number of the current ONGOING turn. The first turn is 1.
## Incremented BEFORE the [signal willBeginTurn] signal and the [method processTurnBegin] method.
@export_storage var currentTurn: int:
	set(newValue):
		if currentTurn == newValue: return
		if shouldShowDebugInfo: Debug.printDebug(str("currentTurn: ", currentTurn, " → ", newValue), str(self))
		
		# Warnings for abnormal behavior
		if newValue < currentTurn: Debug.printWarning("currentTurn decrementing!", "", str(self))
		elif newValue > currentTurn + 1: Debug.printWarning("currentTurn incrementing by more than 1!", "", str(self))
		
		currentTurn = newValue
		showDebugInfo()

@export_storage var currentTurnState: TurnBasedState = TurnBasedState.turnInvalid: # TBD
	set(newValue):
		if currentTurnState == newValue: return
		if shouldShowDebugInfo: Debug.printDebug(str("currentTurnState: ", currentTurnState, " → ", newValue), str(self))
		
		# Warnings for abnormal behavior
		if newValue > currentTurnState + 1: Debug.printWarning("currentTurnState incrementing by more than 1!", "", str(self))
		
		currentTurnState = newValue
		showDebugInfo()

## The total count of turns that have been processed. 
## Incremented BEFORE the [signal didEndTurn] signal but AFTER the [method processTurnEnd] method.
@export_storage var turnsProcessed: int:
	set(newValue):
		if turnsProcessed == newValue: return
		if shouldShowDebugInfo: Debug.printDebug(str("turnsProcessed: ", turnsProcessed, " → ", newValue), str(self))
		
		# Warnings for abnormal behavior
		if newValue < turnsProcessed: Debug.printWarning("turnsProcessed decrementing!", "", str(self))
		elif newValue > turnsProcessed + 1: Debug.printWarning("turnsProcessed incrementing by more than 1!", "", str(self))
		
		turnsProcessed = newValue
		showDebugInfo()

## This flag helps decide [member isReadyToStartTurn], because some the Coordiantor may be `await`ing on an Entities while still in the `turnBegin` state.
@export_storage var isProcessingEntities: bool

## Returns: `true` if the [member currentTurnState] is [constant TurnBasedState.turnBegin], and not [member isProcessingEntities], and neither [member stateTimer] nor [member entityTimer] is running.
var isReadyToStartTurn: bool:
	get: return self.currentTurnState == TurnBasedState.turnBegin \
			and not isProcessingEntities \
			and is_zero_approx(stateTimer.time_left) \
			and is_zero_approx(entityTimer.time_left)

@export_storage var functionToCallOnStateTimer:  Callable ## @experimental
@export_storage var functionToCallOnEntityTimer: Callable ## @experimental

#endregion


#region Signals

# NOTE: DESIGN: Why so many signals? These may help turn-based components intercept each other,
# to serve as the insertion point for "injecting" buff/debuff effects and other modifications at specific points in the turn cycle.
# For example, a poison effect may cause damage at the END of a turn, while a healing effect may increase health at the BEGINNING of a turn.

signal willBeginTurn
signal didBeginTurn

signal willUpdateTurn
signal didUpdateTurn

signal willEndTurn
signal didEndTurn

#endregion


func _ready() -> void:
	if shouldShowDebugInfo: Debug.printLog("_ready()", "white", str(self))
	currentTurnState = TurnBasedState.turnBegin
	entityTimer.wait_time = delayBetweenEntities
	stateTimer.wait_time  = delayBetweenStates
	clearTimerFunctions()
	showDebugInfo()
	
	self.set_process(false) # TBD: Disable the `_process` method because we don't need per-frame updates until the turn cycle starts in the `Begin` phase.


func getStateName(state: TurnBasedState = self.currentTurnState) -> StringName:
	if state >= TurnBasedState.turnBegin and state <= TurnBasedState.turnEnd:
		return [&"begin", &"update", &"end"][state]
	else:
		return &"invalid"


#region Coordinator Management

## @experimental
func pause() -> void:
	# TODO: Implement more reliable pause/unpause
	stateTimer.paused  = true
	entityTimer.paused = true


## @experimental
func unpause() -> void:
	# TODO: Implement more reliable pause/unpause
	stateTimer.paused  = false
	entityTimer.paused = false


## @experimental
func clearTimerFunctions() -> void:
	functionToCallOnStateTimer  = dummyTimerFunction
	functionToCallOnEntityTimer = dummyTimerFunction


## @experimental
func dummyTimerFunction() -> void:
	return

#endregion


#region Coordinator State Cycle

## The beginning of processing 1 full turn and its 3 states.
## Called by the game-specific control system, such as player movement input or a "Next Turn" button.
func startTurnProcess() -> void:
	if shouldShowDebugInfo: Debug.printLog(str("startTurnProcess() currentTurn: ", currentTurn), "white", str(self))
	
	# Ensure that this function should only be called at start of a turn, during the `Begin` state.
	
	if not self.isReadyToStartTurn:
		if shouldShowDebugInfo: Debug.printWarning("startTurnProcess() called when not isReadyToStartTurn", "", str(self))
		return
	
	# TBD: Should timers be reset here? How to handle game pauses during the timer?
	
	cycleStatesUntilNextTurn()


## Cycles through all the [enum TurnBasedState]s until the next turn's [constant TurnBasedState.turnBegin].
func cycleStatesUntilNextTurn() -> void:
	# TODO: A less complex/ambiguous implementation 
	if shouldShowDebugInfo: Debug.printLog("cycleStatesUntilNextTurn()", "", str(self))
	
	# If we're already at `turnBegin`, advance the state once.
	if self.currentTurnState == TurnBasedState.turnBegin:
		await self.processState()
		if not is_zero_approx(delayBetweenStates): 
			stateTimer.start()
			await stateTimer.timeout
		self.incrementState()
		
	# Cycle through the states until we're at `turnBegin` again
	while self.currentTurnState != TurnBasedState.turnBegin:
		await self.processState()
		if not is_zero_approx(delayBetweenStates): 
			stateTimer.start()
			await stateTimer.timeout
		self.incrementState()


func onStateTimer_timeout() -> void:
	if shouldShowDebugInfo: Debug.printLog(str("onStateTimer_timeout() toCall: ", functionToCallOnStateTimer), "", str(self))
	functionToCallOnStateTimer.call()
	functionToCallOnStateTimer = dummyTimerFunction # TBD: Reset this Callable on every timeout?


## Calls one of the signals processing methods based on the [member currentTurnState].
func processState() -> void:
	if shouldShowDebugInfo: Debug.printLog(str("processState(): ", currentTurnState), "", str(self))
	
	match currentTurnState:
		# `await` for Entity delays & animations etc.
		TurnBasedState.turnBegin:	await processTurnBeginSignals()
		TurnBasedState.turnUpdate:	await processTurnUpdateSignals()
		TurnBasedState.turnEnd:		await processTurnEndSignals()
		_:							Debug.printError("Invalid State!", "", str(self)) # TBD: Should this be an Error or Warning?


## Increments the [member currentTurnState], warping to `turnBegin` after the `turnEnd` state.
## Stops the [member stateTimer] before returning to `turnBegin`
## Returns: The new state
func incrementState() -> TurnBasedState:
	if shouldShowDebugInfo: Debug.printLog("incrementState()", "", str(self))
	if currentTurnState < TurnBasedState.turnEnd:
		currentTurnState += 1
	elif currentTurnState >= TurnBasedState.turnEnd:
		stateTimer.stop()
		currentTurnState = TurnBasedState.turnBegin
	return currentTurnState

#endregion


#region Signals Cycle

## Called by [method processState] and calls [method processTurnBegin].
## WARNING: Do NOT override in subclass.
func processTurnBeginSignals() -> void:
	if shouldShowDebugInfo: Debug.printLog(str("processTurnBeginSignals() currentTurn → ", currentTurn + 1, ", entities: ", turnBasedEntities.size()), "", str(self))
	
	currentTurn += 1 # NOTE: Must be incremented BEFORE [willBeginTurn] so the first turn would be 1
	currentTurnState = TurnBasedState.turnBegin
	
	self.set_process(true) # TBD: Enable the `_process` method so it can perform per-frame updates and display the debug info.
	
	willBeginTurn.emit()
	await self.processTurnBegin() # `await` for Entity delays & animations etc.
	didBeginTurn.emit()


## Called by [method processState] and calls [method processTurnUpdate].
## WARNING: Do NOT override in subclass.
func processTurnUpdateSignals() -> void:
	if shouldShowDebugInfo: Debug.printLog(str("processTurnUpdateSignals() currentTurn: ", currentTurn, ", entities: ", turnBasedEntities.size()), "", str(self))
	
	currentTurnState = TurnBasedState.turnUpdate
	
	willUpdateTurn.emit()
	await self.processTurnUpdate() # `await` for Entity delays & animations etc.
	didUpdateTurn.emit()


## Called by [method processState] and calls [method processTurnEnd].
## WARNING: Do NOT override in subclass.
func processTurnEndSignals() -> void:
	if shouldShowDebugInfo: Debug.printLog(str("processTurnEndSignals() currentTurn: ", currentTurn, ", entities: ", turnBasedEntities.size()), "", str(self))
	
	currentTurnState = TurnBasedState.turnEnd
	
	willEndTurn.emit()
	await self.processTurnEnd() # `await` for Entity delays & animations etc.
	
	self.set_process(false) # TBD: Disable the `_process` method because we don't need per-frame updates anymore.
		
	turnsProcessed += 1 # NOTE: Must be incremented AFTER [processTurnEnd] but BEFORE [didEndTurn]
	didEndTurn.emit()

#endregion


#region Entity Update Cycle

func waitForEntityTimer() -> void:
	if not is_zero_approx(delayBetweenEntities): 
		entityTimer.start()
		await entityTimer.timeout


func onEntityTimer_timeout() -> void:
	if shouldShowDebugInfo: Debug.printLog(str("onEntityTimer_timeout() toCall: ", functionToCallOnEntityTimer), "", str(self))
	functionToCallOnEntityTimer.call()
	functionToCallOnEntityTimer = dummyTimerFunction # TBD: Reset this Callable on every timeout?


# NOTE: TBD: Ensure that `await` waits for Entity delays & animations etc.
# NOTE: Do NOT `await turnBasedEntity.did…` signals, because they are emitted within `turnBasedEntity.process…`, before the following `await`

# NOTE: The `isProcessingEntities` flag affects the `isReadyToStartTurn` flag, 
# because some the Coordiantor may be `await`ing on an Entities while still in the `turnBegin` state.
# TBD: Should `isProcessingEntities` be set at a higher scope to ensure no "leaks"? e.g. starting multiple turns.

## Calls [method TurnBasedEntity.processTurnBeginSignals] on all turn-based entities.
func processTurnBegin() -> void:
	self.isProcessingEntities = true
	for turnBasedEntity in self.turnBasedEntities:
		if shouldShowDebugInfo: Debug.printDebug(turnBasedEntity.logName, str(self))
		await turnBasedEntity.processTurnBeginSignals()
		await waitForEntityTimer()
	self.isProcessingEntities = false


## Calls [method TurnBasedEntity.processTurnUpdateSignals] on all turn-based entities.
func processTurnUpdate() -> void:
	self.isProcessingEntities = true
	for turnBasedEntity in self.turnBasedEntities:
		if shouldShowDebugInfo: Debug.printDebug(turnBasedEntity.logName, str(self))
		await turnBasedEntity.processTurnUpdateSignals()
		await waitForEntityTimer()
	self.isProcessingEntities = false


## Calls [method TurnBasedEntity.processTurnEndSignals] on all turn-based entities.
func processTurnEnd() -> void:
	self.isProcessingEntities = true
	for turnBasedEntity in self.turnBasedEntities:
		if shouldShowDebugInfo: Debug.printDebug(turnBasedEntity.logName, str(self))
		await turnBasedEntity.processTurnEndSignals()
		await waitForEntityTimer()
	self.isProcessingEntities = false

#endregion


#region Entity Management

## Returns an array of all [TurnBasedEntity] nodes in the `turnBased` group.
## NOTE: May be slow. Use the [member turnBasedEntities] array instead.
## WARNING: This method relies on entities adding themselves to the `entities` and `turnBased` groups.
func findTurnBasedEntities() -> Array[TurnBasedEntity]:
	var turnBasedEntitiesFound: Array[TurnBasedEntity]
	
	# NOTE: The number of ndoes in the `entities` group will be fewer than the `turnBased` group (which also includes components),
	# so we start with that first.
	
	# TODO: Search within children so this code may be used for multiple [TurnBasedCoordinator] parent nodes in the future.
	
	var entities: Array[Node] = self.get_tree().get_nodes_in_group(Global.Groups.entities)
	
	for node in entities:
		if is_instance_of(node, TurnBasedEntity):
			# TBD: Should we check if it's already in the array?
			turnBasedEntitiesFound.append(node)
	
	return turnBasedEntitiesFound

#endregion


func _process(_delta: float) -> void: # DEBUG
	showDebugInfo()


func showDebugInfo() -> void:
	if not shouldShowDebugInfo: return
	Debug.watchList.turnsProcessed	= turnsProcessed
	Debug.watchList.currentTurn		= currentTurn
	Debug.watchList.currentTurnState= currentTurnState
	Debug.watchList.stateTimer		= stateTimer.time_left
	Debug.watchList.entityTimer		= entityTimer.time_left
