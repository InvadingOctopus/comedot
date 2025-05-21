## Extends [TileBasedControlComponent] to do random movement only.
## Requirements: Same as [TileBasedControlComponent]

class_name TileBasedRandomMovementComponent
extends TileBasedControlComponent


#region Parameters
## An array of steps to take from randomly on every [signal TImer.timeout] of the [member timer].
@export var horizontalMovesSet: Array[int] = [-1, 0, 1]

## An array of steps to take from randomly on every [signal TImer.timeout] of the [member timer].
@export var verticalMovesSet: Array[int] = [-1, 0, 1]

@export var shouldKeepTryingUntilValidMove: bool = true

const maximumTries: int = 10

#endregion


#region State
@onready var stepTimer: Timer = $StepTimer
#endregion


func _ready() -> void:
	# Suppress TileBasedControlComponent
	self.set_physics_process(false)
	self.set_process_input(false)
	self.set_process_unhandled_input(false)

	tileBasedPositionComponent.didArriveAtNewCell.connect(self.onTileBasedPositionComponent_didArriveAtNewCell)


func _input(_event: InputEvent) -> void:
	pass # Suppress TileBasedControlComponent


func _unhandled_input(_event: InputEvent) -> void:
	pass # Suppress TileBasedControlComponent


func _physics_process(_delta: float) -> void:
	pass # Suppress TileBasedControlComponent


func onTileBasedPositionComponent_didArriveAtNewCell(_newDestination: Vector2i) -> void:
	if not isEnabled: return
	pass #stepTimer.start() # Unneeded if Timer is not `one_shot`


func onStepTimer_timeout() -> void:
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
