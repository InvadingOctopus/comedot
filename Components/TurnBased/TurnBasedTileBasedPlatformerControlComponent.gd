## Provides platformer pseudo-"physics" for a turn-based game with tile-based positioning.
## TIP: Use [TurnBasedTileBasedGravityComponent] for gravity.
## Requirements: [TurnBasedEntity], [TileBasedPositionComponent]
## @experimental

class_name TurnBasedTileBasedPlatformerControlComponent
extends TurnBasedTileBasedControlComponent

# TODO: Use InputComponent
# TBD: A better name...?


#region Parameters
#endregion


#region State
#endregion


#region Signals
#endregion


## @experimental
func _input(event: InputEvent) -> void:
	if not isEnabled or not event.is_action_type(): return

	# NOTE: Only accept horizontal move input; only allow vertical movement via jumps and gravity.

	if event.is_action_pressed(GlobalInput.Actions.moveLeft) \
	or event.is_action_pressed(GlobalInput.Actions.moveRight):

		if debugMode: printLog(str(entity.logName, " ", event))

		self.queuedMovementDirection = Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
		self.queuedMovementDirection.y = 0 # NOTE: Negate the direct Y input; only allow vertical movement via jumps and gravity.

		if validateMove(): startTurn()
