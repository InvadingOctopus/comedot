## Extends [TileBasedControlComponentBase] to do random movement only.
## TIP: For a lower-level way of generating random input for other components, see [RandomInputComponent]
## Requirements: [TileBasedPositionComponent]

class_name TileBasedRandomMovementComponent
extends TileBasedControlComponentBase


#region Parameters

## A list of horizontal steps to choose from randomly on every [signal Timer.timeout] of the [member randomStepTimer].
@export var horizontalMovesSet:	Array[int] = [-1, 0, 1]

## A list of vertical steps to choose from randomly on every [signal Timer.timeout] of the [member randomStepTimer].
@export var verticalMovesSet:	Array[int] = [-1, 0, 1]

## If `true` (default), try random directions for [member maximumTries] times until a vacant [TileMapLayer] cell is found.
@export var shouldRetryUntilValidMove: bool = true

## If [member shouldRetryUntilValidMove], this is the number of times to try random directions until a vacant [TileMapLayer] cell is found.
const maximumTries: int = 10

#endregion


#region State
## NOTE: This is NOT the same as a "cooldown" [Timer]
@onready var randomStepTimer: Timer = $RandomStepTimer
#endregion


#region Random Movement

func onRandomStepTimer_timeout() -> void:
	if not isEnabled: return
	moveRandomly()


func moveRandomly() -> void:
	if not isEnabled \
	or (horizontalMovesSet.is_empty() and verticalMovesSet.is_empty()):
		return

	var attemptedVector: Vector2i = getRandomVector()

	# Should we keep rerolling until we find a vacant tile to move to?
	if shouldRetryUntilValidMove:
		var tries: int = 0

		while tries < maximumTries \
		and not tileBasedPositionComponent.validateCoordinates(tileBasedPositionComponent.currentCoordinates + attemptedVector):
			attemptedVector = getRandomVector()
			tries += 1

	self.setMovementVector(attemptedVector)


## Returns a [Vector2i] constructed with a random value each from [member horizontalMovesSet] & [member verticalMovesSet]
func getRandomVector() -> Vector2i:
	# TBD: Use GameState.randomNumberGenerator?
	return Vector2i(horizontalMovesSet.pick_random() if not horizontalMovesSet.is_empty() else 0,
					verticalMovesSet.pick_random()   if not verticalMovesSet.is_empty() else 0)


## Suppresses [member shouldRepeatOnHeldInput] to only generate moves on [member randomStepTimer] ticks.
func getRepeatedMovementVector() -> Vector2i:
	return Vector2i.ZERO

#endregion
