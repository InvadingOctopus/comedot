## Uses a [TileBasedPositionComponent] to move the entity based on player input, or randomly.
## Requirements: [TurnBasedEntity], [TileBasedPositionComponent]. BEFORE [InputComponent]
## @experimental

class_name TurnBasedTileBasedControlComponent
extends TurnBasedComponent

# TODO: Check for collisions?
# TODO: Better name :')
# TBD:  Allow diagonal movement? or is that not necessary in turn-based gameplay?


#region Parameters
@export var shouldMoveContinuously:	bool = true  ## If `true` then the entity keeps moving as long as the input direction is pressed. If `false` then the input must be released before moving again.
@export var shouldMoveRandomly:		bool = false ## Move in a random direction each turn. NOTE: Ignores player input.
#region


#region State
var recentInputVector: Vector2i:
	set(newValue):
		printChange(parentEntity.logName + " recentInputVector", recentInputVector, newValue)
		recentInputVector = newValue
#endregion


#region Dependencies
@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent # TBD: Static or dynamic?
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent)

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent, InputComponent]
#endregion


func _ready() -> void:
	Tools.connectSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput)
	# NOTE: Connect `TurnBasedCoordinator.didReadyToStartTurn` AFTER processTurnEnd()


func onInputComponent_didProcessInput(event: InputEvent) -> void:
	if not isEnabled or shouldMoveRandomly or not event.is_action_type(): return

	if event.is_action_pressed(GlobalInput.Actions.moveLeft) \
	or event.is_action_pressed(GlobalInput.Actions.moveRight) \
	or event.is_action_pressed(GlobalInput.Actions.moveUp) \
	or event.is_action_pressed(GlobalInput.Actions.moveDown):
		self.recentInputVector = inputComponent.movementDirection # CHECK: No need to explicitly cast float Vector2 to Vector2i, right?
		validateMove() # May start the turn


## Calls [method TurnBasedCoordinator.startTurnProcess] if the [TurnBasedCoordinator] is ready to start a new turn and the destination cell is vacant according to [method TileBasedPositionComponent.validateCoordinates].
func validateMove() -> bool:
	# PERFORMANCE: length_squared() is faster than length() CHECK: Does this cause any false positives?
	if recentInputVector.length_squared() != 0  \
	and TurnBasedCoordinator.isReadyToStartTurn \
	and tileBasedPositionComponent.validateCoordinates(tileBasedPositionComponent.currentCellCoordinates + self.recentInputVector):
		TurnBasedCoordinator.startTurnProcess() # TBD: Should the caller start the turn?
		return true
	else:
		return false


func onTurnBasedCoordinator_didReadyToStartTurn() -> void:
	if shouldMoveContinuously:
		if debugMode: printDebug("onTurnBasedCoordinator_didReadyToStartTurn(): shouldMoveContinuously")
		self.recentInputVector = inputComponent.movementDirection
		self.validateMove()


func processTurnBegin() -> void:
	if debugMode: showDebugInfo()


func processTurnUpdate() -> void:
	# if not isEnabled: return # Done in superclass

	if shouldMoveRandomly:
		self.recentInputVector = Vector2i([-1, 1].pick_random(), [-1, 1].pick_random())

	tileBasedPositionComponent.inputVector = Vector2i(self.recentInputVector)
	tileBasedPositionComponent.processMovementInput()
	if debugMode: showDebugInfo()


func processTurnEnd() -> void:
	if not shouldMoveContinuously: recentInputVector = Vector2.ZERO
	# NOTE: Connect `TurnBasedCoordinator.didReadyToStartTurn` AFTER processTurnEnd()
	# so that we can react to changes to `shouldMoveContinuously` during runtime
	Tools.toggleSignal(TurnBasedCoordinator.didReadyToStartTurn, self.onTurnBasedCoordinator_didReadyToStartTurn, self.shouldMoveContinuously)
	if debugMode: showDebugInfo()


func showDebugInfo() -> void:
	# if not debugMode: return # Checked by caller
	Debug.watchList.inputVector = recentInputVector
