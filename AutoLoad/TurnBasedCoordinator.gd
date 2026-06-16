## Manages turn-based gameplay and executes [TurnBasedEntity]s.
## Each turn cycles through the Begin, Execute, and End phases.
## To execute the turn and advance to the next, the game's control system (such as a "Next Turn" button or the player's directional input) must call [method startTurn]
##
## During each phase, the corresponding Begin/Execute/End methods are called on all turn-based entities in order:
## The entities then call the corresponding methods on each of their [TurnBasedComponent]s.
## First, all objects perform the Begin methods, then all objects perform the Execute methods, and so on.
##
## See the documentation for [TurnBasedEntity] and [TurnBasedComponent] for further details.
##
## IMPORTANT: [member Start.isTurnBasedGame] MUST be enabled in your `Start.gd` script for turn-based games!
## PERFORMANCE: To remove [TurnBasedCoordinator], disable [member Start.isTurnBasedGame].

#class_name TurnBasedCoordinator
extends Node # + TurnBasedObjectBase

# PLAN:
# * Each turn has three processing "states" or "phases": Begin, Execute, End
# * Every turn must cycle through all 3 states
# 	This helps game objects to play animations, perform actions, and do any setup/cleanup in the proper order every turn.
# 	NOTE: An Entity must NOT execute Begin → Execute → End all at once before the next Entity is updated;
# 	because that would be effectively just like executing only 1 method per Entity.
# * The TurnBasedCoordinator must call `turnBegin()` on all entities, THEN `turnExecute()` on all entities, THEN `turnEnd()` on all entities (via the processTurn…Signals() proxy/wrapper methods)
# * Each Entity must then call the same order on all its child components.
# * After the `TurnStates.end` phase, the TurnBasedCoordinator must return to `TurnStates.ready`, BUT it must NOT execute the next turn until the game receives the control input to play it.

# TODO: Multiple turn increments and a "delta" for process methods
# TODO: A "TurnBasedContainer" node that calls future TurnBasedCoordinator helper methods to only run [TurnBasedEntity]s within a specific group or parent node.
# TODO: A separate "queue" based system where entities are sorted according to speed or "initiative" that may change dynamically?

# DESIGN: TRIEDANDFAILED: Trying to implement multiple TurnBasedCoordinators in the same scene, e.g. to support multiplayer games, is not a good idea;
# because entities often need to be children of different VISUAL nodes, so they cannot always be placed directly under a specific TurnBasedCoordinator.

# DESIGN: PERFORMANCE: This script doesn't check `if debugMode: printDebug()` to avoid calls because this is for a turn-based system anyway :')


#region Parameters
# TBD: Since this is an Autoload, should these values be flags in Start.gd or let the game's main script decide?

## To avoid the [Timer] error: "Time should be greater than zero" and other jank from being TOO fast.
## According to Godot documentation, it should be 0.05
const minimumDelay: float = 0.05

## The delay after processing each [TurnBasedEntity] PER PHASE (Begin/Execute/End). May be used for aesthetics or debugging.
## NOTE: This delay also occurs even AFTER the LAST entity in the order, even if there is only 1 entity!
## This ensures a delay between multiple moves of the same entity.
@export_range(minimumDelay, 10, 0.05) var delayBetweenEntities: float = 0.5:
	set(newValue):
		newValue = maxf(newValue, minimumDelay)
		delayBetweenEntities = newValue
		if entityTimer: entityTimer.wait_time = newValue

@export var shouldWaitBetweenStates: bool = true ## Enables or disables [member delayBetweenStates].

## The delay after each turn state if [member shouldWaitBetweenStates]: Begin → Execute → End. May be used for aesthetics or debugging.
## NOTE: The delay will occur BEFORE [member stateMachine] transitions to the next state.
## NOTE: This delay also occurs even AFTER the "End" phase! This ensures a delay between the end of the previous turn and the beginning of the next turn.
@export_range(minimumDelay, 10, 0.05) var delayBetweenStates: float = 0.25:
	set(newValue):
		newValue = maxf(newValue, minimumDelay)
		delayBetweenStates = newValue
		if stateTimer: stateTimer.wait_time = newValue

## NOTE: Disabling this flag also disables `_process()` to avoid calling it each frame and wasting performance,
## because `_process()` is only used to update debug info.
@export var debugMode: bool = false:
	set(newValue):
		if newValue != debugMode:
			debugMode = newValue
			self.set_process(debugMode)

#region


#region State: Turns

## The "phases" of each turn: the Ready state, the Beginning, the Execution, and the End.
## The different states allow gameplay components to intercept and modify each other at different moments during the turn execution cycle.
## Example: A poison damage-over-time component may apply damage at the END of a character's turn,
## but a healing-over-time component may increase the health at the START of a turn.
## The phases can be thought of as analogous to picking up a chess piece → moving it to a new position → and putting it down.
class TurnStates:
	const ready		:= &"turnReady"		## The state when the turn-based system is ready to start a new turn.
	const begin		:= &"turnBegin"		## The beginning of a turn. EXAMPLE: Picking a chess piece up from its current square, before moving it.
	const execute	:= &"turnExecute"	## The actual gameplay action. EXAMPLE: Moving a chess piece to a different square.
	const end		:= &"turnEnd"		## The end or closure of a turn. EXAMPLE: Putting a chess piece down on a new square, after moving it.
	# TBD: Should we have an additional "wait" state for when a turn-based entity or object is UNABLE to start a new turn, such as while a scene is loading or multiplayer sync etc.?


## The number of the current ONGOING turn. The first turn is 1.
## Incremented BEFORE the [signal willBeginTurn] signal and the [method processTurnBegin] method.
@export_storage var currentTurn: int:
	set(newValue):
		if currentTurn == newValue: return
		printChange("currentTurn", currentTurn, newValue)

		# Warnings for abnormal behavior
		if   newValue < currentTurn: printWarning("currentTurn decrementing!")
		elif newValue > currentTurn + 1: printWarning("currentTurn incrementing by more than 1!")

		currentTurn = newValue
		showDebugInfo()

@export_storage var stateMachine: StateMachine = preload("res://Resources/TurnState.tres")

## The total count of turns that have been processed.
## Incremented BEFORE the [signal didEndTurn] signal but AFTER the [method processTurnEnd] method.
@export_storage var turnsProcessed: int:
	set(newValue):
		if turnsProcessed == newValue: return
		printChange("turnsProcessed", turnsProcessed, newValue)

		# Warnings for abnormal behavior
		if newValue < turnsProcessed: printWarning("turnsProcessed decrementing!")
		elif newValue > turnsProcessed + 1: printWarning("turnsProcessed incrementing by more than 1!")

		turnsProcessed = newValue
		showDebugInfo()

## Returns: `true` if the [member stateMachine] is enabled and in [constant TurnStates.ready], and not [member isProcessingEntities], and neither [member stateTimer] nor [member entityTimer] is running.
var canStartTurn: bool:
	get: return self.stateMachine.currentState == TurnStates.ready \
			and stateMachine.isEnabled \
			and not self.isProcessingEntities \
			and is_zero_approx(self.stateTimer.time_left) \
			and is_zero_approx(self.entityTimer.time_left)

#endregion


#region State: Entities

## NOTE: This depends on [TurnBasedEntity]s to add & remove themselves in [method TurnBasedEntity._enter_tree] & [method TurnBasedEntity._exit_tree]
@export_storage var turnBasedEntities:	Array[TurnBasedEntity]

## This flag helps decide [member canStartTurn], because the [TurnBasedCoordinator] may be `await`ing on [TurnBasedEntity]s to finish animations etc. while still in [constant TurnStates.begin]
@export_storage var isProcessingEntities: bool

## The index in the [member turnBasedEntities] of the entity that is currently being processed
## NOTE: The value will be -1 (an invalid index) if there is no ongoing turn process loop.
@export_storage var currentEntityIndex:	int = -1

## The index in the [member turnBasedEntities] of the entity that was most recently processed.
## May be equal to [member currentEntityIndex] only during an ongoing turn process loop.
@export_storage var recentEntityIndex:	int = -1

var currentEntityProcessing:	TurnBasedEntity: ## Returns `null` if there is no ongoing turn process loop.
	get: return turnBasedEntities[currentEntityIndex] if currentEntityIndex >= 0 and currentEntityIndex < turnBasedEntities.size() else null

var recentEntityProcessed:		TurnBasedEntity:
	get: return turnBasedEntities[recentEntityIndex]  if recentEntityIndex >= 0  and recentEntityIndex < turnBasedEntities.size()  else null

var nextEntityIndex: int: ## Returns the next entity in the turn order, or the first entry if the current entity is the last one.
	get: return currentEntityIndex + 1 if (currentEntityIndex + 1) < turnBasedEntities.size() else 0

var nextEntityToProcess:		TurnBasedEntity:
	get:
		if not turnBasedEntities.is_empty() and nextEntityIndex < turnBasedEntities.size():
			return turnBasedEntities[nextEntityIndex]
		else:
			return null

#endregion


#region State: Timers
# DESIGN: There are separate timers because a game may choose have no delay between entities but want a delay between states, or vice versa.

@onready var stateTimer:  Timer = $StateTimer
@onready var entityTimer: Timer = $EntityTimer

@export_storage var functionToCallOnStateTimer:  Callable ## @experimental
@export_storage var functionToCallOnEntityTimer: Callable ## @experimental

#endregion


#region Signals

# NOTE: DESIGN: Why so many signals? These may help turn-based components intercept each other,
# to serve as the insertion point for "injecting" buff/debuff effects and other modifications at specific points in the turn cycle.
# For example, a poison effect may cause damage at the END of a turn, while a healing effect may increase health at the BEGINNING of a turn.

## Emitted when the [TurnBasedCoordinator] can accept player/AI input or calls to start a new turn and transition the [member stateMachine] into [const TurnStates.begin]
signal isReadyToStartTurn # TBD: Should this be "didReadyToStartTurn" for consistency? but awkward..

signal willBeginTurn
signal didBeginTurn

signal willExecuteTurn
signal didExecuteTurn

signal willEndTurn
signal didEndTurn

@warning_ignore_start("unused_signal")
signal didAddEntity(entity:		 TurnBasedEntity) ## Emitted by [TurnBasedEntity]
signal didRemoveEntity(entity:	 TurnBasedEntity) ## Emitted by [TurnBasedEntity]
signal willProcessEntity(entity: TurnBasedEntity)
signal didProcessEntity(entity:  TurnBasedEntity) ## NOTE: Emitted BEFORE the [member entityTimer] delay BETWEEN entities.

signal willStartDelay(timer: Timer) ## Emitted when one of the timers between each state or entity is about to start.

#endregion


#region Life Cycle

func _notification(what: int) -> void: # This happens earlier than _enter_tree()
	if what != NOTIFICATION_PARENTED: return
	Debug.printAutoLoadLog("NOTIFICATION_PARENTED")


func _ready() -> void:
	Debug.printAutoLoadLog("_ready()")

	if not stateMachine:
		Debug.printError("Missing stateMachine", self)
		return

	initStateMachine()

	entityTimer.wait_time = delayBetweenEntities
	stateTimer.wait_time  = delayBetweenStates
	clearTimerFunctions()
	showDebugInfo()

	self.set_process(false) # TBD: Disable the _process() method because we don't need per-frame updates until the turn cycle starts in the `Begin` phase.

	if canStartTurn:
		printDebug("isReadyToStartTurn")
		isReadyToStartTurn.emit()
	else:
		# NOTE: Allow starting a turn after the initialization has completed
		stateMachine.isEnabled = true
		# Defer until everything else in the scene tree is also ready
		if stateMachine.currentState == TurnStates.ready: self.isReadyToStartTurn.emit.call_deferred()
		else: stateMachine.call_deferred(&"transitionToState", TurnStates.ready)


func initStateMachine() -> void:
	# Recreate the shared `TurnState` Resource to make sure it's the same as TurnBasedCoordinator's state lists,
	# so this script can be "the source of truth" for turn-based gameplay.

	stateMachine.states.clear()
	# TBD: PERFORMANCE: Use [Array] of [StringName] instead of [PackedStringArray]?
	stateMachine.states[TurnStates.ready]	= PackedStringArray([TurnStates.begin])
	stateMachine.states[TurnStates.begin]	= PackedStringArray([TurnStates.execute])
	stateMachine.states[TurnStates.execute]	= PackedStringArray([TurnStates.end])
	stateMachine.states[TurnStates.end]		= PackedStringArray([TurnStates.ready, TurnStates.begin])

	stateMachine.debugMode		= self.debugMode
	stateMachine.initialState	= TurnStates.ready # ALERT: DESIGN: We are NOT actually ready to start a turn yet, but we don't want to over-model setup as a turn state.
	stateMachine.resetState()
	stateMachine.isEnabled		= false # NOTE: Lock transitions until initialization is complete and a gameplay scene is loaded.

	Tools.connectSignal(stateMachine.didRejectTransition,	self.onStateMachine_didRejectTransition)
	Tools.connectSignal(stateMachine.willTransition,		self.onStateMachine_willTransition)
	Tools.connectSignal(stateMachine.didTransition,			self.onStateMachine_didTransition)

#endregion


#region State Machine Events

func onStateMachine_didRejectTransition(_sourceState: StringName, _rejectedState: StringName) -> void:
	pass


func onStateMachine_willTransition(_outgoingState: StringName, _incomingState: StringName) -> void:
	pass


func onStateMachine_didTransition(_previousState: StringName, newState: StringName) -> void:
	match newState:
		TurnStates.ready:	self.isReadyToStartTurn.emit()

		TurnStates.begin, TurnStates.execute, TurnStates.end:

			## NOTE: Temporarily disable transitions to other states while we are waiting on entities & components to finish their turns,
			## to prevent reentrancy & races etc.
			stateMachine.isEnabled = false

			await self.processState(newState) # `await` for Entity animations & delays etc.
			await waitForStateTimer()

			stateMachine.isEnabled = true
			if stateMachine.currentState == newState: # JIC: Make sure processState() didn't muck up the state machine
				transitionToNextState()

		_: Debug.printWarning(str("onStateMachine_didTransition() to invalid state: ", newState), self) # TBD: Should this be an Error or Warning?

#endregion


#region Coordinator External Interface

## Begins the processing of 1 full turn, by transitioning the [member stateMachine] into [const TurnStates.begin] which then leads to cycling through each of the 3 states: Begin → Execute → End
## May only be called while the current state is [const TurnStates.begin]
## Called by the game-specific control system, such as player movement input or a "Next Turn" button.
## TIP: Call this method with `await` and set [param awaitForTurnEnd] to `true` to wait for the [signal didEndTurn] and ensure a full turn cycle.
## TIP: Await for the [signal isReadyToStartTurn] signal to start the next turn.
func startTurn(awaitForTurnEnd: bool = false) -> bool:
	if debugMode: printLog(str("[color=white][b]startTurn() currentTurn: ", currentTurn))

	# Ensure that this function should only be called at start of a turn, during the `Begin` state.

	if not self.canStartTurn:
		if debugMode: printWarning("startTurn() called when not canStartTurn") # Not an important warning
		return false

	# TBD: Should timers be reset here? How to handle game pauses during the timer?
	if stateMachine.transitionToState(TurnStates.begin):
		if awaitForTurnEnd: await self.didEndTurn
		return true
	else:
		printWarning("startTurn(): stateMachine.transitionToState() failed to transition to TurnStates.begin")
		return false


## @experimental
func pause() -> void:
	# TODO: Implement more reliable pause/unpause
	stateMachine.isEnabled	= false
	stateTimer.paused		= true
	entityTimer.paused		= true


## @experimental
func unpause() -> void:
	# TODO: Implement more reliable pause/unpause
	stateMachine.isEnabled	= true
	stateTimer.paused		= false
	entityTimer.paused		= false

#endregion


#region Coordinator State Cycle

## Calls one of the signal processing methods based on [member stateMachine]'s current state,
## to let [TurnBasedEntity]s make their moves.
func processState(state: StringName = stateMachine.currentState) -> void:
	printDebug("processState(): " + stateMachine.currentState)

	# TBD: Also set `stateMachine.isEnabled = false` here or only in onStateMachine_didTransition()?

	match state:
		# `await` for Entity animations & delays etc.
		TurnStates.begin:	await processTurnBeginSignals()
		TurnStates.execute:	await processTurnExecuteSignals()
		TurnStates.end:		await processTurnEndSignals()
	


## Transitions [member stateMachine] to the next default turn state.
## Stops the [member stateTimer] before returning to [constant TurnStates.ready].
## Returns: `true` if the state transition succeeded.
func transitionToNextState() -> bool:
	printDebug("transitionToNextState()")
	match stateMachine.currentState:
		TurnStates.ready:	return stateMachine.transitionToState(TurnStates.begin)
		TurnStates.begin:	return stateMachine.transitionToState(TurnStates.execute)
		TurnStates.execute:	return stateMachine.transitionToState(TurnStates.end)
		TurnStates.end:
			stateTimer.stop()
			return stateMachine.transitionToState(TurnStates.ready)
		_:
			Debug.printWarning(str("transitionToNextState() invalid state: ", stateMachine.currentState), self)
			return false

#endregion


#region Signals Cycle

## Called by [method processState] and calls [method processTurnBegin].
## WARNING: Do NOT override in subclass.
func processTurnBeginSignals() -> void:
	printDebug(str("processTurnBeginSignals() currentTurn → ", currentTurn + 1, ", ", turnBasedEntities.size(), " entities: ", getEntityNames()))

	currentTurn += 1 # NOTE: Must be incremented BEFORE [willBeginTurn] so the first turn would be 1

	self.set_process(debugMode) # Enable the `_process` method so it can perform per-frame updates and display the debug info.

	willBeginTurn.emit()
	@warning_ignore("redundant_await")
	await self.processTurnBegin() # `await` for Entity animations & delays etc.
	didBeginTurn.emit()


## Called by [method processState] and calls [method processTurnExecute].
## WARNING: Do NOT override in subclass.
func processTurnExecuteSignals() -> void:
	printDebug(str("processTurnExecuteSignals() currentTurn: ", currentTurn, ", ", turnBasedEntities.size(), " entities: ", getEntityNames()))

	willExecuteTurn.emit()
	@warning_ignore("redundant_await")
	await self.processTurnExecute() # `await` for Entity animations & delays etc.
	didExecuteTurn.emit()


## Called by [method processState] and calls [method processTurnEnd].
## WARNING: Do NOT override in subclass.
func processTurnEndSignals() -> void:
	printDebug(str("processTurnEndSignals() currentTurn: ", currentTurn, ", ", turnBasedEntities.size(), " entities: ", getEntityNames()))

	willEndTurn.emit()
	@warning_ignore("redundant_await")
	await self.processTurnEnd() # `await` for Entity animations & delays etc.

	self.set_process(false) # TBD: Disable the `_process` method because we don't need per-frame updates anymore.

	turnsProcessed += 1 # NOTE: Must be incremented AFTER [processTurnEnd] but BEFORE [didEndTurn]
	didEndTurn.emit()

#endregion


#region Entity Management

## Inserts a [TurnBasedEntity] into the [member turnBasedEntities] array.
## Returns the entity's index in the array (normally the array size-1), or -1 if the insertion fails.
## IMPORTANT: Use this method to add entities instead of modifying the [member turnBasedEntities] array directly!
func addEntity(entity: TurnBasedEntity) -> int:
	if not turnBasedEntities.has(entity): # Add only if the entity not already in the array!
		entity.add_to_group(Global.Groups.turnBased, true) # Just in case, even though it should be already done by TurnBasedEntity. IMPORTANT: May be required by functions which operate on this group.
		self.turnBasedEntities.append(entity)
		self.didAddEntity.emit(entity)
		return turnBasedEntities.size() - 1 # NOTE: Return the INDEX of the last item!
	else:
		printWarning(str("addEntity(): Entity already in turnBasedEntities: ", entity))
		return -1


## Removes a [TurnBasedEntity] from the [member turnBasedEntities] array.
## Returns the array's new size, or -1 if the removal fails.
## IMPORTANT: Use this method to remove entities instead of modifying the [member turnBasedEntities] array directly!
func removeEntity(entity: TurnBasedEntity) -> int:
	if turnBasedEntities.has(entity):
		self.turnBasedEntities.erase(entity)
		self.didRemoveEntity.emit(entity)
		return turnBasedEntities.size()
	else:
		printWarning(str("removeEntity(): Entity not in turnBasedEntities: ", entity))
		return -1


## Returns an array of all [TurnBasedEntity] nodes in the `turnBased` group.
## NOTE: May be slow. Use the [member turnBasedEntities] array instead.
## WARNING: This method relies on entities adding themselves to the `entities` and `turnBased` groups.
func findTurnBasedEntities() -> Array[TurnBasedEntity]:
	var turnBasedEntitiesFound: Array[TurnBasedEntity]

	# NOTE: The number of nodes in the `entities` group will be fewer than the `turnBased` group (which also includes components),
	# so we start with that first.

	# TODO: Search within children so this code may be used for multiple [TurnBasedCoordinator] parent nodes in the future.
	# NOTE: Cannot search in more than 1 group at once, but there will be more nodes in the "turnBased" than in the "entities" group,
	# because of components, so get the smaller "entities" group then iterate over it.

	var entities: Array[Node] = self.get_tree().get_nodes_in_group(Global.Groups.entities)

	for node in entities:
		if is_instance_of(node, TurnBasedEntity):
			# TBD: Should we check if it's already in the array?
			turnBasedEntitiesFound.append(node)

	return turnBasedEntitiesFound

#endregion


#region Entity Process Cycle

# NOTE: TBD: Ensure that `await` waits for Entity delays & animations etc.
# NOTE: Do NOT `await turnBasedEntity.did…` signals, because they are emitted within `turnBasedEntity.process…`, before the following `await`

# NOTE: The `isProcessingEntities` flag affects the `canStartTurn` flag,
# because the TurnBasedCoordinator may be `await`ing entities while still in [constant TurnStates.begin].
# TBD: Should `isProcessingEntities` be set at a higher scope to ensure no "leaks"? e.g. starting multiple turns.


## Calls [method TurnBasedEntity.processTurnBeginSignals] on all turn-based entities.
func processTurnBegin() -> void:
	await processEntities(TurnStates.begin)


## Calls [method TurnBasedEntity.processTurnExecuteSignals] on all turn-based entities.
func processTurnExecute() -> void:
	await processEntities(TurnStates.execute)


## Calls [method TurnBasedEntity.processTurnEndSignals] on all turn-based entities.
func processTurnEnd() -> void:
	await processEntities(TurnStates.end)


## Calls one of the "processTurn…" methods on all turn-based entities based on the [param state].
func processEntities(state: StringName) -> void:
	# TBD: Check for invalid states?
	self.currentEntityIndex = -1 # Let the loop start from 0
	self.isProcessingEntities = true

	for turnBasedEntity in self.turnBasedEntities: # TBD: BUGRISK: Use .duplicate() and is_instance_valid() to avoid mutation-during-iteration etc. bugs?
		self.currentEntityIndex += 1
		recentEntityIndex = currentEntityIndex

		printDebug(str("processEntities(): #", currentEntityIndex, " ", turnBasedEntity.logName, " S", state))

		self.willProcessEntity.emit(turnBasedEntity)

		match state:
			TurnStates.begin:	await turnBasedEntity.processTurnBeginSignals()
			TurnStates.execute:	await turnBasedEntity.processTurnExecuteSignals()
			TurnStates.end:		await turnBasedEntity.processTurnEndSignals()

		self.didProcessEntity.emit(turnBasedEntity) # NOTE: Emit this signal BEFORE the delay BETWEEN entities.

		# Start the delay between entities
		# NOTE: Delay even if it's the last entity in the loop, because there should be a delay before the 1st entity of the NEXT turn too!
		await waitForEntityTimer()

	currentEntityIndex = -1 # NOTE: Set an invalid index to specify that no entity is currently being processed.
	self.isProcessingEntities = false

#endregion


#region Timers

func waitForStateTimer() -> void:
	if shouldWaitBetweenStates and not is_zero_approx(delayBetweenStates):
		printDebug(str("[color=dimgray]waitForStateTimer(): ", stateTimer.wait_time))
		self.willStartDelay.emit(stateTimer)
		stateTimer.start()
		await stateTimer.timeout
	elif debugMode:
		printDebug("[color=dimgray]waitForStateTimer(): 0")


func onStateTimer_timeout() -> void:
	printDebug(str("onStateTimer_timeout() toCall: ", functionToCallOnStateTimer))
	functionToCallOnStateTimer.call()
	functionToCallOnStateTimer = dummyTimerFunction # TBD: Reset this Callable on every timeout?


func waitForEntityTimer() -> void:
	if not is_zero_approx(delayBetweenEntities):
		printDebug(str("[color=dimgray]waitForEntityTimer(): ", entityTimer.wait_time))
		self.willStartDelay.emit(entityTimer)
		entityTimer.start()
		await entityTimer.timeout
	elif debugMode:
		printDebug("[color=dimgray]waitForEntityTimer(): 0")


func onEntityTimer_timeout() -> void:
	printDebug(str("onEntityTimer_timeout() toCall: ", functionToCallOnEntityTimer))
	functionToCallOnEntityTimer.call()
	functionToCallOnEntityTimer = dummyTimerFunction # TBD: Reset this Callable on every timeout?


## @experimental
func clearTimerFunctions() -> void:
	functionToCallOnStateTimer  = dummyTimerFunction
	functionToCallOnEntityTimer = dummyTimerFunction


## @experimental
func dummyTimerFunction() -> void:
	return

#endregion


#region Logging & Debugging

var logStateIndicator: String: ## Text appended to log entries to indicate the current turn and state/phase.
	get: # TODO: PERFORMANCE: Change back to cached property
		# Update the state indicator for log messages, only once when the state changes.
		match stateMachine.currentState:
			TurnStates.ready:	return "[color=lightgray]T"
			TurnStates.begin:	return "[color=green]T"
			TurnStates.execute:	return "[color=yellow]T"
			TurnStates.end:		return "[color=orange]T"
			_: return "[color=dimgray]T"

var logName: String: ## Customizes logs for the turn-based system to include the turn+phase, because it's not related to frames.
	get: return str("TurnBasedCoordinator ", logStateIndicator, currentTurn)

func _process(_delta: float) -> void:
	# NOTE: `_process()` is disabled by `set_process()` if `debugMode` is disabled, to avoid wasting performance each frame.
	showDebugInfo()


func getEntityNames() -> String:
	var names: String = ""
	for entity in turnBasedEntities:
		names += entity.name + ", "
	return names.trim_suffix(", ")


func printLog(message: String) -> void:
	Debug.printLog(message, logName, "", "white")


func printDebug(message: String) -> void:
	# Even though the caller requests a "debug" log, use the regular `printLog()` but respect the debug flag,
	# because this is a "master"/controller Autoload.
	if debugMode: Debug.printLog(message, logName, "", "white")


func printWarning(message: String) -> void:
	Debug.printWarning(message, logName)


func printChange(variableName: String, previousValue: Variant, newValue: Variant) -> void:
	if debugMode: Debug.printChange(str("[color=white]", self, " [color=gray]", variableName), previousValue, newValue)


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.addCombinedWatchList("TurnBasedCoordinator", {
		turnsProcessed	= turnsProcessed,
		currentTurn		= currentTurn,
		currentState	= stateMachine.currentState,
		stateTimer		= stateTimer.time_left,
		entityTimer		= entityTimer.time_left,
		})

#endregion
