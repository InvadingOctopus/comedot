## Uses a [TileBasedPositionComponent] to move the entity based on player input, or randomly.
## Requirements: [TurnBasedEntity], [TileBasedPositionComponent]
## @experimental

class_name TurnBasedTileBasedControlComponent
extends TurnBasedComponent

# TODO: Check for collisions?
# TODO: Better name :')


#region Parameters
@export var randomMovement: bool = false ## Move in a random direction each turn. NOTE: Ignores player input.
#region


#region State

var recentInputVector: Vector2i:
	set(newValue):
		printChange(parentEntity.logName + " recentInputVector", recentInputVector, newValue)
		recentInputVector = newValue

#endregion


#region Dependencies

@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent # TBD: Static or dynamic?

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent]

#endregion


func _input(event: InputEvent) -> void:
	if not isEnabled or randomMovement or not event.is_action_type(): return

	if event.is_action_pressed(GlobalInput.Actions.moveLeft) \
	or event.is_action_pressed(GlobalInput.Actions.moveRight) \
	or event.is_action_pressed(GlobalInput.Actions.moveUp) \
	or event.is_action_pressed(GlobalInput.Actions.moveDown):

		if debugMode: printLog(str(parentEntity.logName, " ", event))

		self.recentInputVector = Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)

		validateMove() # May start the turn


## Calls [method TurnBasedCoordinator.startTurnProcess] if the [TurnBasedCoordinator] is ready to start a new turn and the destination cell is vacant according to [method TileBasedPositionComponent.validateCoordinates].
func validateMove() -> bool:
	if not is_zero_approx(recentInputVector.length()) \
	and TurnBasedCoordinator.isReadyToStartTurn \
	and tileBasedPositionComponent.validateCoordinates(tileBasedPositionComponent.currentCellCoordinates + self.recentInputVector):
		TurnBasedCoordinator.startTurnProcess() # TBD: Should the caller start the turn?
		return true
	else:
		return false


func processTurnBegin() -> void:
	showDebugInfo()


func processTurnUpdate() -> void:
	# if not isEnabled: return # Done in superclass

	if randomMovement:
		self.recentInputVector = Vector2i([-1, 1].pick_random(), [-1, 1].pick_random())

	tileBasedPositionComponent.inputVector = Vector2i(self.recentInputVector)
	tileBasedPositionComponent.processMovementInput()
	showDebugInfo()


func processTurnEnd() -> void:
	self.recentInputVector = Vector2.ZERO
	showDebugInfo()


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList.inputVector = recentInputVector
