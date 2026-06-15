## Provides platformer pseudo-"physics" for a turn-based game with tile-based positioning.
## TIP: Use [TurnBasedTileBasedGravityComponent] for gravity.
## Requirements: [TurnBasedEntity], [TileBasedPositionComponent]. BEFORE [InputComponent]
## @experimental

class_name TurnBasedTileBasedPlatformerControlComponent
extends TurnBasedTileBasedControlComponent

# TBD: A better name...?


#region Parameters
#endregion


#region State
#endregion


#region Signals
#endregion


#region Input
# NOTE: Only accept horizontal "walk" input; only allow vertical movement via jumps and gravity.


func onInputComponent_didUpdateMovementDirection(movementDirection: Vector2, difference: Vector2) -> void:
	# Accept only changes on the horizontal axis, to avoid moves if just the vertical axis changes.
	var previousHorizontalDirection: int = int(signf((movementDirection - difference).x))
	var currentHorizontalDirection:  int = int(signf( movementDirection.x))
	if  currentHorizontalDirection == previousHorizontalDirection: return

	if canAcceptMove: processHorizontalInput()


func repeatMovement() -> bool:
	if shouldRepeatOnHeldInput and canAcceptMove:
		return processHorizontalInput()
	else:
		return false


func processHorizontalInput() -> bool:
	var requestedDirection: Vector2i = Vector2i(int(signf(inputComponent.horizontalInput)), 0)
	if  requestedDirection.x != 0 and validateMove(requestedDirection):
		self.queuedMovementDirection = requestedDirection
		if shouldStartTurnOnMove and canStartTurn: startTurn()
		return true
	else:
		return false

#endregion
