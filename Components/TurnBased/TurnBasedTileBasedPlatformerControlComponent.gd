## Provides platformer pseudo-"physics" for a turn-based game with tile-based positioning.
## TIP: Use [TurnBasedTileBasedGravityComponent] for gravity.
## Requirements: [TurnBasedEntity], [TileBasedPositionComponent]. BEFORE [InputComponent]
## @experimental

class_name TurnBasedTileBasedPlatformerControlComponent
extends TurnBasedTileBasedControlComponent

# TODO: Extract horizontal movement from diagonal inputs instead of truncating
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
	# NOTE: Record changes on the horizontal axis, to avoid movement if only the vertical axis changes.
	var previousHorizontalDirection: int = int(signf((movementDirection - difference).x))
	var currentHorizontalDirection:  int = int(signf( movementDirection.x))
	if  currentHorizontalDirection == previousHorizontalDirection: return

	## Process input events outside processTurnBegin() only if this component can start a new turn
	if not isEnabled or not shouldStartTurnOnMove or not canStartTurn: return
	processHorizontalInput()


## Sets [member queuedMovementDirection] from the horizontal input axis only, if [method validateMove] approves.
## NOTE: Does NOT check [member canAcceptMove]
func processHorizontalInput() -> bool:
	var requestedDirection: Vector2i = Vector2i(int(signf(inputComponent.horizontalInput)), 0)
	if  requestedDirection.x != 0 and validateMove(requestedDirection):
		self.queuedMovementDirection = requestedDirection
		if shouldStartTurnOnMove and canStartTurn: startTurn()
		return true
	else:
		return false

#endregion


#region Turn Cycle

func processTurnBegin() -> void:
	# Allow automation to inject moves at the start of a turn, while preserving platformer horizontal-only movement.
	# EXAMPLE: Connecting `TurnBasedEntity.willBeginTurn` to RandomInputComponent.performRandomAction()
	if isEnabled and canAcceptMove: processHorizontalInput()

#endregion


#region Repeated Movement

## Reapplies [member inputComponent.horizontalInput] to [member queuedMovementDirection] if [member shouldRepeatOnHeldInput],
## and starts a new turn if [member shouldStartTurnOnMove] and [member canStartTurn]
## TIP: May be used to implement "Roguelike" control.
func repeatMovement() -> bool:
	if not shouldRepeatOnHeldInput or not shouldStartTurnOnMove: return false
	else: return processHorizontalInput()

#endregion
