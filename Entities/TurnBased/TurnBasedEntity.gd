## Base class for turn-based entities. Performs actions by issuing commands to [TurnBasedComponent]s.

class_name TurnBasedEntity
extends Entity


#region Parameters
@export var isEnabled := true
#endregion


#region State
## The number of the current turn. Incremented BEFORE the [signal willBeginTurn] signal and the [method processTurnBegin] method.
var currentTurn: int

## The total count of turns that have been processed. Incremented BEFORE the [signal didEndTurn] signal and AFTER the [method processTurnEnd] method.
var turnsProcessed: int
#endregion


#region Signals
# TBD: DESIGN: Why so many signals? Maybe they'll help with buff/debuff effects, modifiers etc.

signal willBeginTurn
signal didBeginTurn

signal willUpdateTurn
signal didUpdateTurn

signal willEndTurn
signal didEndTurn
#endregion


## Called by the [TurnBasedCoordinator].
## NOTE: Do NOT override in subclass.
func processTurnBeginSignals() -> void:
	if not isEnabled: return
	self.currentTurn += 1 # NOTE: Must be incremented BEFORE [willBeginTurn]
	willBeginTurn.emit()
	self.processTurnBegin()
	didBeginTurn.emit()


## Any "pre-turn" activity that happens BEFORE the main activity, such as animations or messages.
func processTurnBegin() -> void:
	for turnBasedComponent in findTurnBasedComponents():
		turnBasedComponent.processTurnBeginSignals()
		# DESIGN: turnBasedComponent.isEnabled is checked in [TurnBasedComponent]


## Called by the [TurnBasedCoordinator].
## NOTE: Do NOT override in subclass.
func processTurnUpdateSignals() -> void:
	if not isEnabled: return
	willUpdateTurn.emit()
	self.processTurnUpdate()
	didUpdateTurn.emit()


## The actual actions which occur every turn, such as movement or combat.
func processTurnUpdate() -> void:
	for turnBasedComponent in findTurnBasedComponents():
		turnBasedComponent.processTurnUpdateSignals()
		# DESIGN: turnBasedComponent.isEnabled is checked in [TurnBasedComponent]


## Called by the [TurnBasedCoordinator].
## NOTE: Do NOT override in subclass.
func processTurnEndSignals() -> void:
	if not isEnabled: return
	willEndTurn.emit()
	self.processTurnEnd()
	turnsProcessed += 1 # NOTE: Must be incremented AFTER [processTurnEnd] but BEFORE [didEndTurn]
	didEndTurn.emit()


## Any "post-turn" activity that happens BEFORE the main activity, such as animations or messages.
func processTurnEnd() -> void:
	for turnBasedComponent in findTurnBasedComponents():
		turnBasedComponent.processTurnEndSignals()
		# DESIGN: turnBasedComponent.isEnabled is checked in [TurnBasedComponent]


func findTurnBasedComponents() -> Array[TurnBasedComponent]:
	return self.findChildrenOfType(TurnBasedComponent)
