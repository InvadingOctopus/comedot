## Base class for all turn-based components.
## Each turn, the parent [TurnBasedEntity] calls the [method processTurnBegin], [method processTurn] and [method processTurnEnd] methods on each of its component in order.
## NOTE: These methods MUST be overridden by subclasses to perform the game-specific actions every turn.
##
## NOTE: The begin/update/end methods are NOT executed at once for a single component:
## First, all components of an entity perform the "Begin" phase: Entity1.Component1.processTurnBegin → Entity1.Component2.processTurnBegin ...
## THEN all components perform "Update" phase, and so on.
##
## Requirements: [TurnBasedEntity], [AnimatedSprite2D]

class_name TurnBasedComponent
extends Component # + TurnBasedObjectBase

# NOTE: DESIGN: This class is almost identical to [TurnBasedEntity] and there is a lot of code duplication
# because classes can't have multiple inheritance; it would need to extend both [Component] and [TurnBased] :')


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State

## Returns: [TurnBasedCoordinator.currentTurn]
var currentTurn: int:
	get: return TurnBasedCoordinator.currentTurn # TBD: Should it forward to TurnBasedEntity?
	set(newValue): printError("currentTurn should not be set; use TurnBasedCoordinator") # TEMP: To catch bugs

## Returns: [TurnBasedCoordinator.currentTurnState]
var currentTurnState: TurnBasedCoordinator.TurnBasedState:
	get: return TurnBasedCoordinator.currentTurnState # TBD: Should it forward to TurnBasedEntity?
	set(newValue): printError("currentTurnState should not be set; use TurnBasedCoordinator") # TEMP: To catch bugs

## Returns: [TurnBasedCoordinator.turnsProcessed]
var turnsProcessed: int:
	get: return TurnBasedCoordinator.turnsProcessed # TBD: Should it forward to TurnBasedEntity?
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


func registerEntity(newParentEntity: Entity) -> void:
	super.registerEntity(newParentEntity)
	if not is_instance_of(self.parentEntity, TurnBasedEntity):
		printWarning("Parent Entity is not a TurnBasedEntity! " + parentEntity.logFullName)


#region Turn State Cycle

# `await` on `self.processTurn…` ensures animations and any other delays are properly processed in order.

## Called by the parent [TurnBasedEntity] and calls [method processTurnBegin].
## WARNING: Do NOT override in subclass.
func processTurnBeginSignals() -> void:
	if not isEnabled: return
	if debugMode: printLog(str("processTurnBeginSignals() willBeginTurn ", currentTurn))

	willBeginTurn.emit()
	@warning_ignore("redundant_await")
	await self.processTurnBegin() # IGNORE: Godot Warning; `await` is needed for animations etc.

	if debugMode: printLog("didBeginTurn")
	didBeginTurn.emit()


## Called by the parent [TurnBasedEntity] and calls [method processTurnUpdate].
## WARNING: Do NOT override in subclass.
func processTurnUpdateSignals() -> void:
	if not isEnabled: return
	if debugMode: printLog(str("processTurnUpdateSignals() willUpdateTurn ", currentTurn))

	willUpdateTurn.emit()
	@warning_ignore("redundant_await")
	await self.processTurnUpdate() # IGNORE: Godot Warning; `await` is needed for animations etc.

	if debugMode: printLog("didUpdateTurn")
	didUpdateTurn.emit()


## Called by the parent [TurnBasedEntity] and calls [method processTurnEnd].
## WARNING: Do NOT override in subclass.
func processTurnEndSignals() -> void:
	if not isEnabled: return
	if debugMode: printLog(str("processTurnEndSignals() willEndTurn ", currentTurn))

	willEndTurn.emit()
	@warning_ignore("redundant_await")
	await self.processTurnEnd() # IGNORE: Godot Warning; `await` is needed for animations etc.

	if debugMode: printLog("didEndTurn")
	didEndTurn.emit()

#endregion


#region Abstract Turn Process Methods

# NOTE: These methids MUST be overridden by subclasses to perform the actual game-specific actions.

## Any "pre-turn" activity that happens BEFORE the main activity, such as animations, healing-over-time effects or any other setup.
## Abstract; Must be overridden by subclasses.
func processTurnBegin() -> void:
	pass


## The actual actions which occur every turn, such as movement or combat.
## Abstract; Must be overridden by subclasses.
func processTurnUpdate() -> void:
	pass


## Any "post-turn" activity that happens AFTER the main activity, such as animations, damage-over-time effects, log messages, or cleanup.
## Abstract; Must be overridden by subclasses.
func processTurnEnd() -> void:
	pass

#endregion


func printLog(message: String = "", object: Variant = self.logName) -> void:
	if not isLoggingEnabled: return
	# Customize logs for turn-based components to include the turn+phase, because it's not related to frames.
	Debug.printLog(message, str(object, " ", TurnBasedCoordinator.logStateIndicator, self.currentTurn), "lightBlue", "cyan")
