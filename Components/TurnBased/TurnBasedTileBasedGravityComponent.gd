## Simulates pseudo-gravity in a turn-based game with tile-based positioning. Uses a [Timer] to automatically advance a turn if the entity is in "mid air".
## The [TileMapLayer] cell below the entity is checked if it is vacant according to [method TileBasedPositionComponent.validateCoordinates].
## Requirements: [TurnBasedEntity], [TileBasedPositionComponent]
## @experimental

class_name TurnBasedTileBasedGravityComponent
extends TurnBasedComponent

# TODO: Don't fall while jumping


#region Parameters
# The turn phase to process gravity in.
# IGNORE: Godot error: "Cannot use simple "@export" annotation because the type of the initialized value can't be inferred." because TurnBasedCoordinator is an AutoLoad?
# TBD: @export_enum("Begin:1", "Update:2", "End:3")
@export var phaseToProcessIn: TurnBasedCoordinator.TurnBasedState = TurnBasedCoordinator.TurnBasedState.turnBegin
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
	if debugMode: printDebug(str("Starting GravityTimer: ", gravityTimer.wait_time))
	gravityTimer.start()


func onGravityTimer_timeout() -> void:
	# If we should fall, advance the turn, but let the actual fall occur during the turn phase process.
	if checkForFall(): TurnBasedCoordinator.startTurnProcess()


## Returns `true` if the entity should fall to the [TileMapLayer] cell below the current position.
## Uses [method TileBasedPositionComponent.validateCoordinates].
## @experimental
func checkForFall() -> bool:
	# TODO: Don't fall while jumping

	var currentPosition: Vector2i = tileBasedPositionComponent.currentCellCoordinates

	# Is there a floor below us?
	var cellBelow: Vector2i = Vector2i(currentPosition.x, currentPosition.y + 1)
	var shouldFall: bool = tileBasedPositionComponent.validateCoordinates(cellBelow)
	
	if debugMode: printDebug(str("shouldFall: ", shouldFall, " → ", cellBelow))
	return shouldFall


func fall() -> void:
	# NOTE: Get and modify the current DESTINATION, in case a [TurnBasedTileBasedControlComponent] is also moving the entity.
	var coordinates: Vector2i = tileBasedPositionComponent.destinationCellCoordinates

	# Apply gravity
	coordinates.y += 1 # Y increases downwards

	tileBasedPositionComponent.setDestinationCellCoordinates(coordinates)
	self.didFall.emit()


func processTurnBegin() -> void:
	if self.phaseToProcessIn == TurnBasedCoordinator.TurnBasedState.turnBegin and checkForFall():
		fall()


func processTurnUPdate() -> void:
	if self.phaseToProcessIn == TurnBasedCoordinator.TurnBasedState.turnUpdate and checkForFall():
		fall()


func processTurnEnd() -> void:
	if self.phaseToProcessIn == TurnBasedCoordinator.TurnBasedState.turnEnd and checkForFall():
		fall()

	startTimer()
