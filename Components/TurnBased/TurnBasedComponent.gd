## Base class for all turn-based components.
## Used by a [TurnBasedEntity] which calls the [method processTurnBegin], [method processTurn] and [method processTurnEnd] methods in order.
## These methods must be overridden by subclasses.

class_name TurnBasedComponent
extends Component


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


## Called by the [TurnBasedEntity].
## NOTE: Do NOT override in subclass.
func processTurnBeginSignals() -> void:
	if not isEnabled: return
	self.currentTurn += 1 # NOTE: Must be incremented BEFORE [willBeginTurn]
	willBeginTurn.emit()
	self.processTurnBegin()
	didBeginTurn.emit()


## Called by the [TurnBasedEntity].
## NOTE: Do NOT override in subclass.
func processTurnUpdateSignals() -> void:
	if not isEnabled: return
	willUpdateTurn.emit()
	self.processTurnUpdate()
	didUpdateTurn.emit()


## Called by the [TurnBasedEntity].
## NOTE: Do NOT override in subclass.
func processTurnEndSignals() -> void:
	if not isEnabled: return
	willEndTurn.emit()
	self.processTurnEnd()
	turnsProcessed += 1 # NOTE: Must be incremented AFTER [processTurnEnd] but BEFORE [didEndTurn]
	didEndTurn.emit()


#region Abstract Methods

## Any "pre-turn" activity that happens BEFORE the main activity, such as animations or messages.
## Abstract; Must be overridden by subclasses.
func processTurnBegin() -> void:
	pass


## The actual actions which occur every turn, such as movement or combat.
## Abstract; Must be overridden by subclasses.
func processTurnUpdate() -> void:
	pass


## Any "post-turn" activity that happens BEFORE the main activity, such as animations or messages.
## Abstract; Must be overridden by subclasses.
func processTurnEnd() -> void:
	pass

#endregion
