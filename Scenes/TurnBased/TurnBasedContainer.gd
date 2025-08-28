## Experimental attempt at implementing multiple [TurnBasedCoordinator] in the same scene..
## Manages turn-based gameplay and only updates the [TurnBasedEntity] nodes which are direct children of this [TurnBasedContainer].
## @experimental

class_name TurnBasedContainer
extends Node2D # TBD: TurnBasedObjectBase?

# DESIGN: TRIEDANDFAILED: Trying to implement multiple TurnBasedCoordinators in the same scene, e.g. to support multiplayer games, is not a good idea;
# because entities often need to be children of different VISUAL nodes, so they cannot always be placed directly under a specific TurnBasedCoordinator.
# For an experimental attempt, see [TurnBasedContainer].


#region Parameters

## To avoid the [Timer] error: "Time should be greater than zero" and other jank from being TOO fast.
## According to Godot documentation, it should be 0.05
const minimumDelay: float = 0.05

## The delay after processing each [TurnBasedEntity] PER PHASE (Begin/Update/End). May be used for aesthetics or debugging.
## NOTE: This delay also occurs even AFTER the LAST entity in the order, even if there is only 1 entity!
## This ensures a delay between multiple moves of the same entity.
@export_range(minimumDelay, 10, 0.05) var delayBetweenEntities: float = 0.5:
	set(newValue):
		newValue = maxf(newValue, minimumDelay)
		delayBetweenEntities = newValue
		if entityTimer: entityTimer.wait_time = newValue

## The delay after each [enum TurnBasedState]. May be used for debugging.
## NOTE: The delay will occur BEFORE the [member currentTurnState] is incremented.
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

## The "phases" of each turn: the Beginning, the Update, and the End.
## The different states allow gameplay components to intercept and modify each other at different moments during the turn update cycle.
## Example: A poison damage-over-time component may apply damage at the END of a character's turn,
## but a healing-over-time component may increase the health at the START of a turn.
## The phases can be thought of as analogous to picking up a chess piece → moving it to a new position → and putting it down.
enum TurnBasedState { # TBD: Should this be renamed to "Phase"?
	turnInvalid	= -1,
	turnBegin	=  0,
	turnUpdate	=  1,
	turnEnd		=  2,
	}


## The number of the current ONGOING turn. The first turn is 1.
## Incremented BEFORE the [signal willBeginTurn] signal and the [method processTurnBegin] method.
@export_storage var currentTurn: int:
	set(newValue):
		if currentTurn == newValue: return
		printChange("currentTurn", currentTurn, newValue)

		# Warnings for abnormal behavior
		if newValue < currentTurn: printWarning("currentTurn decrementing!")
		elif newValue > currentTurn + 1: printWarning("currentTurn incrementing by more than 1!")

		currentTurn = newValue
		showDebugInfo()

@export_storage var currentTurnState: TurnBasedState = TurnBasedState.turnInvalid: # TBD
	set(newValue):
		if currentTurnState == newValue: return
		printChange("currentTurnState", currentTurnState, newValue)

		# Warnings for abnormal behavior
		if newValue > currentTurnState + 1: printWarning("currentTurnState incrementing by more than 1!")
		currentTurnState = newValue

		# Update the state indicator for log messages, only once when the state changes.
		match currentTurnState:
			TurnBasedState.turnBegin:  logStateIndicator = "[color=green]T"
			TurnBasedState.turnUpdate: logStateIndicator = "[color=yellow]T"
			TurnBasedState.turnEnd:    logStateIndicator = "[color=orange]T"
			_: logStateIndicator = "[color=dimgray]T"

		showDebugInfo()

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

## Returns: `true` if the [member currentTurnState] is [constant TurnBasedState.turnBegin], and not [member isProcessingEntities], and neither [member stateTimer] nor [member entityTimer] is running.
var isReadyToStartTurn: bool:
	get: return self.currentTurnState == TurnBasedState.turnBegin \
			and not isProcessingEntities \
			and is_zero_approx(stateTimer.time_left) \
			and is_zero_approx(entityTimer.time_left)

#endregion


#region State: Entities

## NOTE: This depends on [TurnBasedEntity]s to add & remove themselves in [method TurnBasedEntity._enter_tree] & [method TurnBasedEntity._exit_tree]
@export_storage var turnBasedEntities: Array[TurnBasedEntity]

## This flag helps decide [member isReadyToStartTurn], because some the Coordiantor may be `await`ing on an Entities while still in the `turnBegin` state.
@export_storage var isProcessingEntities: bool

## The index in the [member turnBasedEntities] of the entity that is currently being processed
## NOTE: The value will be -1 (an invalid index) if there is no ongoing turn process loop.
@export_storage var currentEntityIndex: int

## The index in the [member turnBasedEntities] of the entity that was most recently processed.
## May be equal to [member currentEntityIndex] only during an ongoing turn process loop.
@export_storage var recentEntityIndex: int

var currentEntityProcessing: TurnBasedEntity: ## Returns `null` if there is no ongoing turn process loop.
	get: return turnBasedEntities[currentEntityIndex] if currentEntityIndex >= 0 and currentEntityIndex < turnBasedEntities.size() else null

var recentEntityProcessed: TurnBasedEntity:
	get: return turnBasedEntities[recentEntityIndex]

var nextEntityIndex: int: ## Returns the next entity in the turn order, or the first entry if the current entity is the last one.
	get: return currentEntityIndex + 1 if (currentEntityIndex + 1) < turnBasedEntities.size() else 0

var nextEntityToProcess: TurnBasedEntity:
	get:
		if not turnBasedEntities.is_empty() and nextEntityIndex < turnBasedEntities.size():
			return turnBasedEntities[nextEntityIndex]
		else:
			return null

var shouldRebuildEntityList: bool = true

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

@warning_ignore("unused_signal")
signal didAddEntity(entity: TurnBasedEntity) ## Emitted by [TurnBasedEntity]

@warning_ignore("unused_signal")
signal didRemoveEntity(entity: TurnBasedEntity) ## Emitted by [TurnBasedEntity]

signal didReadyToStartTurn

signal willBeginTurn
signal didBeginTurn

signal willUpdateTurn
signal didUpdateTurn

signal willEndTurn
signal didEndTurn

signal willProcessEntity(entity: TurnBasedEntity)
signal didProcessEntity(entity: TurnBasedEntity) ## NOTE: Emitted BEFORE the [member entityTimer] delay BETWEEN entities.

signal willStartDelay(timer: Timer) ## Emitted when one of the timers between each state or entity is about to start.

#endregion


#region Life Cycle

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_CHILD_ORDER_CHANGED: # Received when child nodes are added, moved or removed.
			shouldRebuildEntityList = true


func _enter_tree() -> void:
	printLog("_enter_tree()")
	connectSignals()


## WARNING: When overriding in a subclass, call `super.connectSignals()`,
## but do NOT call [method TurnBasedContainer.connectSignals] manually from [method _enter_tree] or [method _ready], to ensure that all signals are connected and ONLY ONCE.
func connectSignals() -> void:
	printDebug("connectSignals()")
	Tools.connectSignal(self.child_entered_tree, self.onChildEnteredTree)
	Tools.connectSignal(self.child_exiting_tree, self.onChildExitingTree)


func _ready() -> void:
	Debug.printLog("_ready()", self.get_script().resource_path.get_file(), "", "WHITE")

	currentTurnState = TurnBasedState.turnBegin
	entityTimer.wait_time = delayBetweenEntities
	stateTimer.wait_time  = delayBetweenStates
	clearTimerFunctions()
	showDebugInfo()

	self.set_process(false) # TBD: Disable the `_process` method because we don't need per-frame updates until the turn cycle starts in the `Begin` phase.
	if isReadyToStartTurn:
		printDebug("didReadyToStartTurn")
		didReadyToStartTurn.emit()

#endregion


#region Coordinator External Interface

## The beginning of processing 1 full turn and its 3 states.
## Called by the game-specific control system, such as player movement input or a "Next Turn" button.
func startTurnProcess() -> void:
	if debugMode: printLog(str("[color=white][b]startTurnProcess() currentTurn: ", currentTurn))

	# Ensure that this function should only be called at start of a turn, during the `Begin` state.

	if not self.isReadyToStartTurn:
		if debugMode: printWarning("startTurnProcess() called when not isReadyToStartTurn") # Not an important warning
		return

	# NOTE: Ensure that any destroyed turn-based children are no longer processed
	# and existing turn-based children are processed in the correct order, in case their order changed.
	if shouldRebuildEntityList: rebuildEntityList()

	# TBD: Should timers be reset here? How to handle game pauses during the timer?
	cycleStatesUntilNextTurn()


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

#endregion


#region Coordinator State Cycle

## Cycles through all the [enum TurnBasedState]s until the next turn's [constant TurnBasedState.turnBegin].
func cycleStatesUntilNextTurn() -> void:
	# TODO: A less complex/ambiguous implementation
	printDebug("cycleStatesUntilNextTurn()")

	# If we're already at `turnBegin`, advance the state once.
	if self.currentTurnState == TurnBasedState.turnBegin:
		await self.processState()
		await self.waitForStateTimer()
		self.incrementState()

	# Cycle through the states until we're at `turnBegin` again
	while self.currentTurnState != TurnBasedState.turnBegin:
		await self.processState()
		await self.waitForStateTimer() # NOTE: Delay even if it's the last entity/state in the loop, because there should be a delay before the 1st entity/state of the NEXT turn too!
		self.incrementState()

	if isReadyToStartTurn:
		printDebug("didReadyToStartTurn")
		didReadyToStartTurn.emit()


## Calls one of the signals processing methods based on the [member currentTurnState].
func processState() -> void:
	printDebug(str("processState(): ", getStateLogText()))

	match currentTurnState:
		# `await` for Entity delays & animations etc.
		TurnBasedState.turnBegin:	await processTurnBeginSignals()
		TurnBasedState.turnUpdate:	await processTurnUpdateSignals()
		TurnBasedState.turnEnd:		await processTurnEndSignals()
		_:							Debug.printError("Invalid State!", self) # TBD: Should this be an Error or Warning?


## Increments the [member currentTurnState], warping to `turnBegin` after the `turnEnd` state.
## Stops the [member stateTimer] before returning to `turnBegin`
## Returns: The new state
func incrementState() -> TurnBasedState:
	printDebug("incrementState()")
	if currentTurnState < TurnBasedState.turnEnd:
		@warning_ignore("int_as_enum_without_cast")
		currentTurnState += 1 # IGNORE Godot Warning; How else to increment an enum?
	elif currentTurnState >= TurnBasedState.turnEnd:
		stateTimer.stop()
		currentTurnState = TurnBasedState.turnBegin
	return currentTurnState

#endregion


#region Signals Cycle

## Called by [method processState] and calls [method processTurnBegin].
## WARNING: Do NOT override in subclass.
func processTurnBeginSignals() -> void:
	printDebug(str("processTurnBeginSignals() currentTurn → ", currentTurn + 1, ", ", turnBasedEntities.size(), " entities: ", getEntityNames()))

	currentTurn += 1 # NOTE: Must be incremented BEFORE [willBeginTurn] so the first turn would be 1
	currentTurnState = TurnBasedState.turnBegin

	self.set_process(true) # TBD: Enable the `_process` method so it can perform per-frame updates and display the debug info.

	willBeginTurn.emit()
	@warning_ignore("redundant_await")
	await self.processTurnBegin() # `await` for Entity animations & delays etc.
	didBeginTurn.emit()


## Called by [method processState] and calls [method processTurnUpdate].
## WARNING: Do NOT override in subclass.
func processTurnUpdateSignals() -> void:
	printDebug(str("processTurnUpdateSignals() currentTurn: ", currentTurn, ", ", turnBasedEntities.size(), " entities: ", getEntityNames()))

	currentTurnState = TurnBasedState.turnUpdate

	willUpdateTurn.emit()
	@warning_ignore("redundant_await")
	await self.processTurnUpdate() # `await` for Entity animations & delays etc.
	didUpdateTurn.emit()


## Called by [method processState] and calls [method processTurnEnd].
## WARNING: Do NOT override in subclass.
func processTurnEndSignals() -> void:
	printDebug(str("processTurnEndSignals() currentTurn: ", currentTurn, ", ", turnBasedEntities.size(), " entities: ", getEntityNames()))

	currentTurnState = TurnBasedState.turnEnd

	willEndTurn.emit()
	@warning_ignore("redundant_await")
	await self.processTurnEnd() # `await` for Entity animations & delays etc.

	self.set_process(false) # TBD: Disable the `_process` method because we don't need per-frame updates anymore.

	turnsProcessed += 1 # NOTE: Must be incremented AFTER [processTurnEnd] but BEFORE [didEndTurn]
	didEndTurn.emit()

#endregion


#region Entity Management


## Enables [member shouldRebuildEntityList] if a new [TurnBasedEntity] child node is added.
@warning_ignore("unused_parameter")
func onChildEnteredTree(node: Node) -> void:
	# NOTE: A child node will `_enter_tree()` even when the parent node (this [TurnBasedContainer]) is added to the SCENE,
	# so this method does NOT necessarily mean that a child was added to the PARENT.
	if node is TurnBasedEntity:
		self.shouldRebuildEntityList = true


## Removes disowned [TurnBasedEntity] nodes from [member turnBasedEntities].
## NOTE: A child node will [method Node._exit_tree] even when the parent (this [TurnBasedContainer]) is removed from the SCENE,
## so this method does NOT necessarily mean that a child was removed from the PARENT.
@warning_ignore("unused_parameter")
func onChildExitingTree(node: Node) -> void:
	if node is TurnBasedEntity:
		self.turnBasedEntities.erase(node)


## Inserts a [TurnBasedEntity] into the [member turnBasedEntities] array.
## Returns the entity's index in the array, or -1 if the insertion fails.
## IMPORTANT: Use this method to add entities instead of modifying the [member turnBasedEntities] array directly!
func addEntity(entity: TurnBasedEntity) -> int:
	if not turnBasedEntities.has(entity): # Add only if the entity not already in the array!
		entity.add_to_group(Global.Groups.turnBased, true) # Just in case, even though it should be already done by TurnBasedEntity. IMPORTANT: May be required by functions which operate on this group.
		self.turnBasedEntities.append(entity)
		self.didAddEntity.emit(entity)
		return turnBasedEntities.size()
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


## Clears and rebuilds the [member turnBasedEntities] array if [member shouldRebuildEntityList],
## by scanning all the immediate child nodes of this [TurnBasedContainer] and adding any [TurnBasedEntity] nodes found.
## Returns: The new size of [member turnBasedEntities].
## ALERT: "Nested" children are NOT detected (nodes that are subchildren of this node's children).
## ALERT: Does NOT emit [signal didAddEntity] or [signal didRemoveEntity] signals.
## TIP: To search for ALL [TurnBasedEntity] nodes in the entire Scene Tree, call [method findTurnBasedEntities].
func rebuildEntityList() -> int:
	printLog(str("rebuildEntityList(): ", shouldRebuildEntityList))
	if shouldRebuildEntityList:
		self.turnBasedEntities.clear()
		for child in self.get_children():
			if is_instance_of(child, TurnBasedEntity):
				self.turnBasedEntities.append(child)

	shouldRebuildEntityList = false
	return self.turnBasedEntities.size()


## Returns an array of ALL [TurnBasedEntity] nodes in the `turnBased` group, even nodes that are NOT children of this [TurnBasedContainer].
## TIP: To only scan children and rebuild the [member turnBasedEntities] list, call [method rebuildEntityList] if [member shouldRebuildEntityList].
## PERFORMANCE: May be slow.
## IMPORTANT: This method relies on entities adding themselves to the `entities` and `turnBased` groups.
func findTurnBasedEntities() -> Array[TurnBasedEntity]:
	var turnBasedEntitiesFound: Array[TurnBasedEntity]

	# NOTE: The number of nodes in the `entities` group will be fewer than the `turnBased` group (which also includes components),
	# so we start with that first.

	# TODO: Search within children so this code may be used for multiple [TurnBasedContainer] parent nodes in the future.
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

# NOTE: The `isProcessingEntities` flag affects the `isReadyToStartTurn` flag,
# because some the Coordinator may be `await`ing on an Entities while still in the `turnBegin` state.
# TBD: Should `isProcessingEntities` be set at a higher scope to ensure no "leaks"? e.g. starting multiple turns.


## Calls [method TurnBasedEntity.processTurnBeginSignals] on all turn-based entities.
func processTurnBegin() -> void:
	await processEntities(TurnBasedState.turnBegin)


## Calls [method TurnBasedEntity.processTurnUpdateSignals] on all turn-based entities.
func processTurnUpdate() -> void:
	await processEntities(TurnBasedState.turnUpdate)


## Calls [method TurnBasedEntity.processTurnEndSignals] on all turn-based entities.
func processTurnEnd() -> void:
	await processEntities(TurnBasedState.turnEnd)


## Calls one of the "processTurn…" methods on all turn-based entities based on the [param state].
func processEntities(state: TurnBasedState) -> void:
	# TBD: Check for invalid states?
	self.currentEntityIndex = -1 # Let the loop start from 0
	self.isProcessingEntities = true

	for turnBasedEntity in self.turnBasedEntities:
		self.currentEntityIndex += 1
		recentEntityIndex = currentEntityIndex

		printDebug(str("processEntities(): #", currentEntityIndex, " ", turnBasedEntity.logName, " S", getStateLogText(state)))

		self.willProcessEntity.emit(turnBasedEntity)

		match state:
			TurnBasedState.turnBegin:	await turnBasedEntity.processTurnBeginSignals()
			TurnBasedState.turnUpdate:	await turnBasedEntity.processTurnUpdateSignals()
			TurnBasedState.turnEnd:		await turnBasedEntity.processTurnEndSignals()

		self.didProcessEntity.emit(turnBasedEntity) # NOTE: Emit this signal BEFORE the delay BETWEEN entities.

		# Start the delay between entities
		# NOTE: Delay even if it's the last entity in the loop, because there should be a delay before the 1st entity of the NEXT turn too!
		await waitForEntityTimer()

	currentEntityIndex = -1 # NOTE: Set an invalid index to specify that no entity is currently being processed.
	self.isProcessingEntities = false

#endregion


#region Timers

func waitForStateTimer() -> void:
	if not is_zero_approx(delayBetweenStates):
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

var logStateIndicator: String ## Text appended to log entries to indicate the current turn and state/phase.

var logName: String: ## Customizes logs for the turn-based system to include the turn+phase, because it's not related to frames.
	get: return str("TurnBasedContainer ", self, logStateIndicator, currentTurn)


## Returns a readable name for the [param state].
func getStateLogText(state: TurnBasedState = self.currentTurnState) -> String:
	return Tools.getEnumText(TurnBasedState, state)


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
	# because this is a "master"/controller node.
	if debugMode: Debug.printLog(message, logName, "", "white")


func printWarning(message: String) -> void:
	Debug.printWarning(message, logName)


func printChange(variableName: String, previousValue: Variant, newValue: Variant) -> void:
	if debugMode: Debug.printChange(str("[color=white]", self, " [color=gray]", variableName), previousValue, newValue)


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.addCombinedWatchList("TurnBasedContainer", {
		turnsProcessed	= turnsProcessed,
		currentTurn		= currentTurn,
		currentTurnState= currentTurnState,
		stateTimer		= stateTimer.time_left,
		entityTimer		= entityTimer.time_left,
		})

#endregion
