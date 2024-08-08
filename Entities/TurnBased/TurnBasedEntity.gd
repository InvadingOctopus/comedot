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

#endregion


#region Signals
# See [TurnBasedCoordinator] comments for explanation of signals.

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
	TurnBasedCoordinator.turnBasedEntities.append(self)


func _exit_tree() -> void:
	TurnBasedCoordinator.turnBasedEntities.erase(self)


#region Turn State Cycle

# `await` on `self.processTurn…` ensures animations and any other delays are properly processed in order.

## Called by the [TurnBasedCoordinator] and calls [method processTurnBegin].
## WARNING: Do NOT override in subclass.
func processTurnBeginSignals() -> void:
	if not isEnabled: return
	if shouldShowDebugInfo:
		printLog(str("processTurnBeginSignals() currentTurn: ", currentTurn))
		TextBubble.create(self, str("turnBegin ", currentTurn))

	willBeginTurn.emit()
	await self.processTurnBegin()
	if shouldShowDebugInfo: printLog("didBeginTurn")
	didBeginTurn.emit()


## Called by the [TurnBasedCoordinator] and calls [method processTurnUpdate].
## WARNING: Do NOT override in subclass.
func processTurnUpdateSignals() -> void:
	if not isEnabled: return
	if shouldShowDebugInfo:
		printLog(str("processTurnUpdateSignals() currentTurn: ", currentTurn))
		TextBubble.create(self, str("turnUpdate ", currentTurn))

	willUpdateTurn.emit()
	await self.processTurnUpdate()
	if shouldShowDebugInfo: printLog("didUpdateTurn")
	didUpdateTurn.emit()


## Called by the [TurnBasedCoordinator] and calls [method processTurnEnd].
## WARNING: Do NOT override in subclass.
func processTurnEndSignals() -> void:
	if not isEnabled: return
	if shouldShowDebugInfo:
		printLog(str("processTurnEndSignals() currentTurn: ", currentTurn))
		TextBubble.create(self, str("turnEnd ", currentTurn))

	willEndTurn.emit()
	await self.processTurnEnd()
	if shouldShowDebugInfo: printLog("didEndTurn")
	didEndTurn.emit()

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
## NOTE: May be slow. Use the [member turnBasedComponents] array instead.
func findTurnBasedComponents() -> Array[TurnBasedComponent]:
	return self.findChildrenOfType(TurnBasedComponent)

#endregion


func showDebugInfo() -> void:
	if not shouldShowDebugInfo: return
	Debug.watchList.turnsProcessed	= turnsProcessed
	Debug.watchList.currentTurn		= currentTurn
	Debug.watchList.currentTurnState= currentTurnState
