## Simulates pseudo-gravity in a turn-based game with tile-based positioning. Uses a [Timer] to automatically advance a turn if the entity is in "mid air".
## The [TileMapLayer] cell below the entity is checked if it is vacant according to [method Tools.checkTileVacancy].
## Requirements: [TurnBasedEntity], [TileBasedPositionComponent]
## @experimental

class_name TurnBasedTileBasedGravityComponent
extends TurnBasedComponent

# TODO: Don't fall while jumping


#region Parameters
#endregion


#region State
#endregion


#region Signals
signal didFall
#endregion


#region Dependencies

@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent # TBD: Static or dynamic?
@onready var gravityTimer: Timer = $GravityTimer

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent]

#endregion


func _ready() -> void:
	startTimer()


func startTimer() -> void:
	if shouldShowDebugInfo: printDebug(str("Starting GravityTimer: ", gravityTimer.wait_time))
	gravityTimer.start()


func onGravityTimer_timeout() -> void:
	if checkForFall(): TurnBasedCoordinator.startTurnProcess()


## Returns `true` if the entity should fall to the TileMap cell below.
## @experimental
func checkForFall() -> bool:
	# TODO: Don't fall while jumping

	var tileMap: TileMapLayerWithCustomCellData = tileBasedPositionComponent.tileMap
	var currentPosition: Vector2i = tileBasedPositionComponent.currentCellCoordinates

	# Is there a floor below us?
	var cellBelow: Vector2i = Vector2i(currentPosition.x, currentPosition.y + 1)
	var shouldFall: bool = Tools.checkTileVacancy(tileMap, cellBelow, self.parentEntity)

	if shouldShowDebugInfo: printDebug(str("shouldFall: ", shouldFall, " → ", cellBelow))
	return shouldFall


func fall() -> void:
	# NOTE: Get and modify the current DESTINATION, in case a [TurnBasedTileBasedControlComponent] is also moving the entity.
	var coordinates: Vector2i = tileBasedPositionComponent.destinationCellCoordinates

	# Apply gravity
	coordinates.y += 1 # Y increases downwards

	tileBasedPositionComponent.setDestinationCellCoordinates(coordinates)
	self.didFall.emit()


func processTurnBegin() -> void:
	if checkForFall(): fall()


func processTurnEnd() -> void:
	startTimer()
