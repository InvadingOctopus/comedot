## Extends [TileBasedControlComponent] to do random movement only.
## Requirements: [TileBasedPositionComponent]

class_name TileBasedRandomMovementComponent
extends TileBasedControlComponent


#region Parameters

## A list of horizontal steps to choose from randomly on every [signal Timer.timeout] of the [member randomStepTimer].
@export var horizontalMovesSet: Array[int] = [-1, 0, 1]

## A list of vertical steps to choose from randomly on every [signal Timer.timeout] of the [member randomStepTimer].
@export var verticalMovesSet: Array[int] = [-1, 0, 1]

## If `true` (default), try random directions for [member maximumTries] times until a vacant [TileMapLayer] cell is found.
@export var shouldKeepTryingUntilValidMove: bool = true

## If [member shouldKeepTryingUntilValidMove], the number of times to try random directions until a vacant [TileMapLayer] cell is found.
const maximumTries: int = 10

#endregion


#region State
@onready var randomStepTimer: Timer = $RandomStepTimer
#endregion


func _ready() -> void:
	# Suppress TileBasedControlComponent
	self.set_physics_process(false)
	self.set_process_input(false)
	self.set_process_unhandled_input(false)

	tileBasedPositionComponent.didArriveAtNewCell.connect(self.onTileBasedPositionComponent_didArriveAtNewCell)


#region Random Movement

func onRandomStepTimer_timeout() -> void:
	if not isEnabled: return
	moveRandomly()


func moveRandomly() -> void:
	self.recentInputVector = getRandomVector()

	# Should we keep rerolling until we find a vacant tile to move to?

	var tries: int = 0

	if shouldKeepTryingUntilValidMove:
		while not tileBasedPositionComponent.validateCoordinates(tileBasedPositionComponent.currentCellCoordinates + self.recentInputVector) \
		or tries < maximumTries:
			self.recentInputVector = getRandomVector()
			tries += 1

	self.move()


func getRandomVector() -> Vector2i:
	return Vector2i(horizontalMovesSet.pick_random(), verticalMovesSet.pick_random())

#endregion


#region Suppress Superclass

func _input(_event: InputEvent) -> void:
	pass # Suppress TileBasedControlComponent


func _unhandled_input(_event: InputEvent) -> void:
	pass # Suppress TileBasedControlComponent


func _physics_process(_delta: float) -> void:
	pass # Suppress TileBasedControlComponent

#endregion


func onTileBasedPositionComponent_didArriveAtNewCell(_newDestination: Vector2i) -> void:
	if not isEnabled: return
	pass #randomStepTimer.start() # Unneeded if Timer is not `one_shot`
