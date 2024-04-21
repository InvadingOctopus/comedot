## Manages [TurnBasedEntity]s.

extends Node


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
func processTurnBeginSignals():
	self.currentTurn += 1 # NOTE: Must be incremented BEFORE [willBeginTurn]
	willBeginTurn.emit()
	self.processTurnBegin()
	didBeginTurn.emit()


## Any "pre-turn" activity that happens BEFORE the main activity, such as animations or messages.
func processTurnBegin():
	for turnBasedEntity in findTurnBasedEntities():
		turnBasedEntity.processTurnBeginSignals()
		# DESIGN: turnBasedComponent.isEnabled is checked in [TurnBasedComponent]


## Called by the [TurnBasedCoordinator].
## NOTE: Do NOT override in subclass.
func processTurnUpdateSignals():
	willUpdateTurn.emit()
	self.processTurnUpdate()
	didUpdateTurn.emit()


## The actual actions which occur every turn, such as movement or combat.
func processTurnUpdate():
	for turnBasedEntity in findTurnBasedEntities():
		turnBasedEntity.processTurnUpdateSignals()
		# DESIGN: turnBasedComponent.isEnabled is checked in [TurnBasedComponent]


## Called by the [TurnBasedCoordinator].
## NOTE: Do NOT override in subclass.
func processTurnEndSignals():
	willEndTurn.emit()
	self.processTurnEnd()
	turnsProcessed += 1 # NOTE: Must be incremented AFTER [processTurnEnd] but BEFORE [didEndTurn]
	didEndTurn.emit()


## Any "post-turn" activity that happens BEFORE the main activity, such as animations or messages.
func processTurnEnd():
	for turnBasedEntity in findTurnBasedEntities():
		turnBasedEntity.processTurnEndSignals()
		# DESIGN: turnBasedComponent.isEnabled is checked in [TurnBasedComponent]


func findTurnBasedEntities() -> Array[TurnBasedEntity]:
	var turnBasedEntities: Array[TurnBasedEntity]

	for node in get_tree().current_scene.get_children(true): # NOTE: Scan internal sub-children.
		if is_instance_of(node, TurnBasedEntity):
			# TBD: Should we check if it's already in the array?
			turnBasedEntities.append(node)

	return turnBasedEntities
