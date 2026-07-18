## Extends [TileBasedControlComponentBase] to do random movement only and moves automatically on [Timer] ticks.
## TIP: For a more flexible "lower-level" way of generating random input for other components, see [RandomInputComponent]
## Requirements: [TileBasedPositionComponent]

class_name TileBasedRandomMovementComponent
extends TileBasedControlComponentBase


#region Parameters
# TRIED: PERFORMANCE: Using "weighted" [Dictionary]s & Tools.pickRandomFromWeightsDictionary() is slower than Array.pick_random()

## A list of horizontal steps to choose randomly from.
## Sampled independently from [member verticalMovesSet]. If both produce 0, the entity "pauses" or "rests" for a "tick".
@export var horizontalMovesSet:	Array[int]  = [-1, 0, 1]

## A list of vertical steps to choose randomly from.
## Sampled independently from [member horizontalMovesSet]. If both produce 0, the entity "pauses" or "rests" for a "tick".
@export var verticalMovesSet:	Array[int]  = [-1, 0, 1]

## If `true` (default) and the initial move is blocked, retry random directions for [member maxRetries] times until a vacant [TileMapLayer] cell is found.
## ALERT: This does NOT include a "pause" resulting from randomly choosing 0 from both [member horizontalMovesSet] & [member verticalMovesSet]
## NOTE: This is NOT "asynchronous"; this component does not wait for the state of the map to change during a single [method moveRandomly] call.
@export var shouldRetryUntilValidMove: bool = true

## If [member shouldRetryUntilValidMove], this is the number of times to retry random directions after the initial attempt fails,
## until a vacant [TileMapLayer] cell is found.
@export_range(0, 100, 1) var maxRetries: int = 10

#endregion


#region State
## Calls [method moveRandomly] on [signal Timer.timeout]
## NOTE: This is NOT the same as a "cooldown" [Timer]
@onready var randomStepTimer: Timer = $RandomStepTimer
#endregion


#region Random Movement

func onRandomStepTimer_timeout() -> void:
	if not isEnabled: return
	moveRandomly()


## Checks [member isEnabled] & [method isReadyToMove] then calls [method getRandomVector] → [method setMovementVector]
func moveRandomly() -> void:
	# NOTE: Check isReadyToMove() here too in case the `randomStepTimer` fired before we were ready
	if not isEnabled or not isReadyToMove() \
	or (horizontalMovesSet.is_empty() and verticalMovesSet.is_empty()):
		return

	var attemptedVector: Vector2i = getRandomVector()

	# Should we keep rerolling until we find a vacant tile to move to?
	if shouldRetryUntilValidMove:
		var tries: int = 0

		while tries < maxRetries \
		and not tileBasedPositionComponent.validateCoordinates(tileBasedPositionComponent.currentCoordinates + attemptedVector):
			attemptedVector = getRandomVector()
			tries += 1

	self.setMovementVector(attemptedVector)


## Returns a [Vector2i] constructed with a random value each from [member horizontalMovesSet] & [member verticalMovesSet]
func getRandomVector() -> Vector2i:
	# TBD: Use GameState.randomNumberGenerator?
	# TBD: Maybe random movement should be allowed to be different after each Load of a Saved state...
	return Vector2i(horizontalMovesSet.pick_random() if not horizontalMovesSet.is_empty() else 0,
					verticalMovesSet.pick_random()   if not verticalMovesSet.is_empty() else 0)


## Suppresses [member shouldRepeatOnHeldInput] to only generate moves on [member randomStepTimer] ticks.
func getRepeatedMovementVector() -> Vector2i:
	return Vector2i.ZERO

#endregion
