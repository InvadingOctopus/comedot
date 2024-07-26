## Base class for turn-based entities. Performs actions by issuing commands to [TurnBasedComponent]s.

class_name TurnBasedEntity
extends Entity # + TurnBasedObjectBase

## NOTE: DESIGN: This class is almost identical to [TurnBasedComponent] and there is a lot of code duplication 
## because classes can't have multiple inheritance; it would need to extend both [Entity] and [TurnBased] :')


#region Parameters
@export var isEnabled: bool = true
@export var shouldShowDebugInfo: bool = false
#endregion


#region State

var turnBasedComponents: Array[TurnBasedComponent]

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


## The total count of turns that have already been processed.
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


#region Turn Update Cycle

## Called by the [TurnBasedCoordinator] and calls [processTurnBegin].
## WARNING: Do NOT override in subclass.
func processTurnBeginSignals() -> void:
	if not isEnabled: return
	if shouldShowDebugInfo: 
		printLog(str("processTurnBeginSignals() currentTurn → ", currentTurn + 1))
		TextBubble.create(self, str("turnBegin ", currentTurn + 1))
	
	currentTurn += 1 # NOTE: Must be incremented BEFORE [willBeginTurn] so the first turn would be 1
	currentTurnState = TurnBasedCoordinator.TurnBasedState.turnBegin
	
	willBeginTurn.emit()
	self.processTurnBegin()
	didBeginTurn.emit()


## Called by the [TurnBasedCoordinator].
## WARNING: Do NOT override in subclass.
func processTurnUpdateSignals() -> void:
	if not isEnabled: return
	if shouldShowDebugInfo: 
		printLog(str("processTurnUpdateSignals() currentTurn: ", currentTurn))
		TextBubble.create(self, str("turnUpdate ", currentTurn))
	
	currentTurnState = TurnBasedCoordinator.TurnBasedState.turnUpdate
	
	willUpdateTurn.emit()
	self.processTurnUpdate()
	didUpdateTurn.emit()


## Called by the [TurnBasedCoordinator].
## WARNING: Do NOT override in subclass.
func processTurnEndSignals() -> void:
	if not isEnabled: return
	if shouldShowDebugInfo: 
		printLog(str("processTurnEndSignals() currentTurn: ", currentTurn))
		TextBubble.create(self, str("turnEnd ", currentTurn))
	
	currentTurnState = TurnBasedCoordinator.TurnBasedState.turnEnd
	
	willEndTurn.emit()
	self.processTurnEnd()
	
	turnsProcessed += 1 # NOTE: Must be incremented AFTER [processTurnEnd] but BEFORE [didEndTurn]
	didEndTurn.emit()

#endregion Turn Update Cycle


#endregion Child Component Turn Update Cycle

## Calls [processTurnBeginSignals] on all child components.
func processTurnBegin() -> void:
	if not self.isEnabled: return
	for turnBasedComponent in self.turnBasedComponents:
		turnBasedComponent.processTurnBeginSignals()


## Calls [processTurnUpdateSignals] on all child components.
func processTurnUpdate() -> void:
	if not self.isEnabled: return
	for turnBasedComponent in self.turnBasedComponents:
		turnBasedComponent.processTurnUpdateSignals()


## Calls [processTurnEndSignals] on all child components.
func processTurnEnd() -> void:
	if not self.isEnabled: return
	for turnBasedComponent in self.turnBasedComponents:
		turnBasedComponent.processTurnEndSignals()

#endregion


#region Component Management

func registerComponent(newComponent: Component) -> void:
	super.registerComponent(newComponent)
	# Also register the component in our array if it is turn-based
	if is_instance_of(newComponent, TurnBasedComponent):
		self.turnBasedComponents.append(newComponent)


func unregisterComponent(componentToRemove: Component) -> void:
	super.unregisterComponent(componentToRemove)
	# Also remove the component from our array if it is turn-based
	if is_instance_of(componentToRemove, TurnBasedComponent):
		self.turnBasedComponents.erase(componentToRemove)


## Searches all children and returns an array of all nodes that extend [TurnBasedComponent].
## NOTE: May be slow. Use the [member TurnBasedEntity.turnBasedComponents] array instead.
func findTurnBasedComponents() -> Array[TurnBasedComponent]:
	return self.findChildrenOfType(TurnBasedComponent)
	
#endregion


func showDebugInfo() -> void:
	if not shouldShowDebugInfo: return
	Debug.watchList.turnsProcessed	= turnsProcessed
	Debug.watchList.currentTurn		= currentTurn
	Debug.watchList.currentTurnState= currentTurnState
