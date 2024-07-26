## Manages turn-based gameplay and updates [TurnBasedEntity]s.

#class_name TurnBasedCoordinator
extends Node # + TurnBasedObjectBase


#region Constants

enum TurnBasedState {
	turnInvalid	= -1,
	turnBegin	= 0,
	turnUpdate	= 1,
	turnEnd		= 2}
	
#endregion


#region State

## The number of the current turn (first turn is 1). 
## Incremented BEFORE the [willBeginTurn] signal and the [processTurnBegin] method.
var currentTurn: int:
	set(newValue):
		if currentTurn == newValue: return
		if shouldShowDebugInfo: Debug.printDebug(str(self, " currentTurn: ", currentTurn, " → ", newValue))
		currentTurn = newValue
		showDebugInfo()

var currentTurnState: TurnBasedState = TurnBasedState.turnInvalid: # TBD
	set(newValue):
		if currentTurnState == newValue: return
		if shouldShowDebugInfo: Debug.printDebug(str(self, " currentTurnState: ", currentTurnState, " → ", newValue))
		currentTurnState = newValue
		showDebugInfo()

## The total count of turns that have been processed. 
## Incremented BEFORE the [didEndTurn] signal but AFTER the [processTurnEnd] method.
var turnsProcessed: int:
	set(newValue):
		if turnsProcessed == newValue: return
		if shouldShowDebugInfo: Debug.printDebug(str(self, " turnsProcessed: ", turnsProcessed, " → ", newValue))
		turnsProcessed = newValue
		showDebugInfo()

## Add a delay between [TurnBasedState]s. May be helpful for debugging.
var delayBetweenStates: float = 1 # TODO: Make this a flag in Start.gd

var shouldShowDebugInfo: bool = true # TODO: Make this a flag in Start.gd

#endregion


#region Signals
# TBD: DESIGN: Why so many signals? Maybe they'll help with turn-based components intercept each other to apply buff/debuff effects and other modifications etc.

signal willBeginTurn
signal didBeginTurn

signal willUpdateTurn
signal didUpdateTurn

signal willEndTurn
signal didEndTurn

#endregion


func _ready() -> void:
	showDebugInfo()
	currentTurnState = TurnBasedState.turnBegin


#region Turn Update Cycle

## Cycles through all the [TurnBasedState]s until the next turn's [TurnBasedState.turnBegin].
func updateUntilNextTurn() -> void:
	if shouldShowDebugInfo: Debug.printLog(str(self, " updateUntilNextTurn()"))
	
	# If we're already at `turnBegin`, advance the state once.
	if self.currentTurnState == TurnBasedState.turnBegin:
		self.cycleTurnState()
		await waitForDelay()
		
	# Cycle through the states until we're at `turnBegin` again
	while self.currentTurnState != TurnBasedState.turnBegin:
		self.cycleTurnState()
		await waitForDelay()


## Calls one of the turn update methods based on the [currentTurnState] and advances to the next [TurnBasedState].
## Returns: The new state
func cycleTurnState() -> TurnBasedState:
	if shouldShowDebugInfo: Debug.printLog(str(self, " cycleTurnState()"))
	
	match currentTurnState:
		TurnBasedState.turnInvalid:	Debug.printWarning(str(self, " Invalid TurnBasedState!"))
		TurnBasedState.turnBegin:	processTurnBeginSignals()
		TurnBasedState.turnUpdate:	processTurnUpdateSignals()
		TurnBasedState.turnEnd:		processTurnEndSignals()
	
	# Advance and wrap around the state
	
	if currentTurnState < TurnBasedState.turnEnd:
		currentTurnState += 1
	elif currentTurnState >= TurnBasedState.turnEnd:
		currentTurnState = TurnBasedState.turnBegin
	
	return currentTurnState


func waitForDelay() -> void:
	if not is_zero_approx(delayBetweenStates):
		await self.get_tree().create_timer(delayBetweenStates).timeout


## Called by [cycleTurnState] and calls [processTurnBegin].
## WARNING: Do NOT override in subclass.
func processTurnBeginSignals() -> void:
	if shouldShowDebugInfo: Debug.printLog(str(self, " processTurnBeginSignals() currentTurn → ", currentTurn + 1))
	
	currentTurn += 1 # NOTE: Must be incremented BEFORE [willBeginTurn] so the first turn would be 1
	currentTurnState = TurnBasedState.turnBegin
	
	willBeginTurn.emit()
	self.processTurnBegin()
	didBeginTurn.emit()


## Called by [cycleTurnState] and calls [processTurnUpdate].
## WARNING: Do NOT override in subclass.
func processTurnUpdateSignals() -> void:
	if shouldShowDebugInfo: Debug.printLog(str(self, " processTurnUpdateSignals() currentTurn: ", currentTurn))
	
	currentTurnState = TurnBasedState.turnUpdate
	
	willUpdateTurn.emit()
	self.processTurnUpdate()
	didUpdateTurn.emit()


## Called by [cycleTurnState] and calls [processTurnEnd].
## WARNING: Do NOT override in subclass.
func processTurnEndSignals() -> void:
	if shouldShowDebugInfo: Debug.printLog(str(self, " processTurnEndSignals() currentTurn: ", currentTurn))
	
	currentTurnState = TurnBasedState.turnEnd
	
	willEndTurn.emit()
	self.processTurnEnd()
	
	turnsProcessed += 1 # NOTE: Must be incremented AFTER [processTurnEnd] but BEFORE [didEndTurn]
	didEndTurn.emit()

#endregion


#region Child Entity Turn Update Cycle

## Calls [processTurnBeginSignals] on all turn-based entities.
func processTurnBegin() -> void:
	for turnBasedEntity in findTurnBasedEntities():
		turnBasedEntity.processTurnBeginSignals()


## Calls [processTurnUpdateSignals] on all turn-based entities.
func processTurnUpdate() -> void:
	for turnBasedEntity in findTurnBasedEntities():
		turnBasedEntity.processTurnUpdateSignals()


## Calls [processTurnEndSignals] on all turn-based entities.
func processTurnEnd() -> void:
	for turnBasedEntity in findTurnBasedEntities():
		turnBasedEntity.processTurnEndSignals()

#endregion


#region Entity Management

## Returns an array of all [TurnBasedEntity] nodes in the `turnBased` group.
## WARNING: This method relies on entities adding themselves to the `entities` and `turnBased` groups.
func findTurnBasedEntities() -> Array[TurnBasedEntity]:
	var turnBasedEntities: Array[TurnBasedEntity]
	
	# NOTE: The number of ndoes in the `entities` group will be fewer than the `turnBased` group (which also includes components),
	# so we start with that first.
	
	# TODO: Search within children so this code may be used for multiple [TurnBasedCoordinator] parent nodes in the future.
	
	var entities: Array[Node] = self.get_tree().get_nodes_in_group(Global.Groups.entities)
	
	for node in entities:
		if is_instance_of(node, TurnBasedEntity):
			# TBD: Should we check if it's already in the array?
			turnBasedEntities.append(node)
	
	return turnBasedEntities

#endregion


func showDebugInfo() -> void:
	if not shouldShowDebugInfo: return
	Debug.watchList.turnsProcessed	= turnsProcessed
	Debug.watchList.currentTurn		= currentTurn
	Debug.watchList.currentTurnState= currentTurnState
