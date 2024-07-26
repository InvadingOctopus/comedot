## Base class for all turn-based components.
## Each turn, the parent [TurnBasedEntity] calls the [method processTurnBegin], [method processTurn] and [method processTurnEnd] methods in order.
## NOTE: These methods MUST be overridden by subclasses to perform the game-specific actions every turn.

class_name TurnBasedComponent
extends Component # + TurnBasedObjectBase

## NOTE: DESIGN: This class is almost identical to [TurnBasedEntity] and there is a lot of code duplication
## because classes can't have multiple inheritance; it would need to extend both [Component] and [TurnBased] :')


#region Parameters
@export var isEnabled: bool = true
@export var shouldShowDebugInfo: bool = false
#endregion


#region State

## The number of the current turn (first turn is 1). 
## Incremented BEFORE the [willBeginTurn] signal and the [processTurnBegin] method.
var currentTurn: int:
	set(newValue):
		if currentTurn == newValue: return
		if shouldShowDebugInfo: printDebug(str("currentTurn: ", currentTurn, " → ", newValue))
		currentTurn = newValue


var currentTurnState: TurnBasedCoordinator.TurnBasedState = TurnBasedCoordinator.currentTurnState: # TBD
	set(newValue):
		if currentTurnState == newValue: return
		if shouldShowDebugInfo: printDebug(str("currentTurnState: ", currentTurnState, " → ", newValue))
		currentTurnState = newValue


## The total count of turns that have been processed. 
## Incremented BEFORE the [didEndTurn] signal but AFTER the [processTurnEnd] method.
var turnsProcessed: int:
	set(newValue):
		if turnsProcessed == newValue: return
		if shouldShowDebugInfo: printDebug(str("turnsProcessed: ", turnsProcessed, " → ", newValue))
		turnsProcessed = newValue

#endregion


#region Signals
signal willBeginTurn
signal didBeginTurn

signal willUpdateTurn
signal didUpdateTurn

signal willEndTurn
signal didEndTurn
#endregion


func _enter_tree() -> void:
	super._enter_tree()
	self.add_to_group(Global.Groups.turnBased, true)


#region Turn Update Signals

## Called by the parent [TurnBasedEntity] and calls [processTurnBegin].
## WARNING: Do NOT override in subclass.
func processTurnBeginSignals() -> void:
	if not isEnabled: return
	if shouldShowDebugInfo: printLog(str("processTurnBeginSignals() currentTurn → ", currentTurn + 1))
	
	currentTurn += 1 # NOTE: Must be incremented BEFORE [willBeginTurn] so the first turn would be 1
	currentTurnState = TurnBasedCoordinator.TurnBasedState.turnBegin
	
	willBeginTurn.emit()
	self.processTurnBegin()
	didBeginTurn.emit()


## Called by the parent [TurnBasedEntity] and calls [processTurnUpdate].
## WARNING: Do NOT override in subclass.
func processTurnUpdateSignals() -> void:
	if not isEnabled: return
	if shouldShowDebugInfo: printLog(str("processTurnUpdateSignals() currentTurn: ", currentTurn))
	
	currentTurnState = TurnBasedCoordinator.TurnBasedState.turnUpdate
	
	willUpdateTurn.emit()
	self.processTurnUpdate()
	didUpdateTurn.emit()


## Called by the parent [TurnBasedEntity] and calls [processTurnEnd].
## WARNING: Do NOT override in subclass.
func processTurnEndSignals() -> void:
	if not isEnabled: return
	if shouldShowDebugInfo: printLog(str("processTurnEndSignals() currentTurn: ", currentTurn))
	
	currentTurnState = TurnBasedCoordinator.TurnBasedState.turnEnd
	
	willEndTurn.emit()
	self.processTurnEnd()
	
	turnsProcessed += 1 # NOTE: Must be incremented AFTER [processTurnEnd] but BEFORE [didEndTurn]
	didEndTurn.emit()

#endregion


#region Abstract Turn Update Methods

## Any "pre-turn" activity that happens BEFORE the main activity, such as animations, messages or any other preparation.
## Abstract; Must be overridden by subclasses.
func processTurnBegin() -> void:
	pass


## The actual actions which occur every turn, such as movement or combat.
## Abstract; Must be overridden by subclasses.
func processTurnUpdate() -> void:
	pass


## Any "post-turn" activity that happens AFTER the main activity, such as animations, log messages, or cleanup.
## Abstract; Must be overridden by subclasses.
func processTurnEnd() -> void:
	pass

#endregion
