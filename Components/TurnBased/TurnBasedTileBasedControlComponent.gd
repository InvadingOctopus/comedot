## Uses a [TileBasedPositionComponent] to move the entity based on player input, or randomly.
## Requirements: [TileBasedPositionComponent]
## @experimental

class_name TurnBasedTileBasedControlComponent
extends TurnBasedComponent

# TODO: Check for collisions?
# TODO: Better name :')


#region Parameters
## Move in a random direction each turn.
@export var randomMovement: bool = false
#region 

#region State

var tileBasedPositionComponent: TileBasedPositionComponent:
	get: 
		if not tileBasedPositionComponent: tileBasedPositionComponent = self.getCoComponent(TileBasedPositionComponent)
		return tileBasedPositionComponent

var recentInputVector: Vector2i:
	set(newValue):
		if shouldShowDebugInfo: printLog(str(parentEntity.logName, " recentInputVector: ", recentInputVector, " → ", newValue))
		recentInputVector = newValue

#endregion


func _input(event: InputEvent) -> void:
	if not isEnabled or not event.is_action_type(): return
	
	if event.is_action_pressed(GlobalInput.Actions.moveLeft) \
	or event.is_action_pressed(GlobalInput.Actions.moveRight) \
	or event.is_action_pressed(GlobalInput.Actions.moveUp) \
	or event.is_action_pressed(GlobalInput.Actions.moveDown):
		
		if shouldShowDebugInfo: printLog(str(parentEntity.logName, " ", event))
		
		self.recentInputVector = Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
		
		if not is_zero_approx(recentInputVector.length()) and TurnBasedCoordinator.isReadyToStartTurn:
			TurnBasedCoordinator.startTurnProcess()


func processTurnBegin() -> void:
	showDebugInfo()


func processTurnUpdate() -> void:
	# if not isEnabled: return # Done in superclass
	
	if randomMovement:
		self.recentInputVector = Vector2i([-1, 1].pick_random(), [-1, 1].pick_random())
	
	tileBasedPositionComponent.inputVector = Vector2i(self.recentInputVector)
	tileBasedPositionComponent.processMovementInput()
	showDebugInfo()


func processTurnEnd() -> void:
	self.recentInputVector = Vector2.ZERO
	showDebugInfo()


func showDebugInfo() -> void:
	if not shouldShowDebugInfo: return
	Debug.watchList.inputVector = recentInputVector
