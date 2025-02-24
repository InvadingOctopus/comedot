## Provides platformer pseudo-"physics" for a turn-based game with tile-based positioning.
## TIP: Use [TurnBasedTileBasedGravityComponent] for gravity.
## Requirements: [TurnBasedEntity], [TileBasedPositionComponent]
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


func _input(event: InputEvent) -> void:
	if not isEnabled or not event.is_action_type(): return

	# NOTE: Only accept horizontal move input; only allow vertical movement via jumps and gravity.

	if event.is_action_pressed(GlobalInput.Actions.moveLeft) \
	or event.is_action_pressed(GlobalInput.Actions.moveRight):

		if debugMode: printLog(str(parentEntity.logName, " ", event))

		self.recentInputVector = Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
		self.recentInputVector.y = 0 # NOTE: Negate the direct Y input; only allow vertical movement via jumps and gravity.

		validateMove() # May start the turn
