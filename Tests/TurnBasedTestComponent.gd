## Tests the turn-based system. Uses animations and delays etc. to verify that the [TurnBasedCoordinator] waits for each [TurnBasedEntity] before processing the next entity.
## @experimental

class_name TurnBasedTestComponent
extends TurnBasedComponent


#region State
var tileBasedPositionComponent: TileBasedPositionComponent:
	get:
		if not tileBasedPositionComponent: tileBasedPositionComponent = getCoComponent(TileBasedPositionComponent)
		return tileBasedPositionComponent
#endregion


func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent]


func _ready() -> void:
	self.didUpdateTurn.connect(onDidUpdateTurn)
	self.didEndTurn.connect(onDidEndTurn)
	tileBasedPositionComponent.willStartMovingToNewCell.connect(self.onTileBasedPositionComponent_willStartMovingToNewCell)
	tileBasedPositionComponent.didArriveAtNewCell.connect(self.onTileBasedPositionComponent_didArriveAtNewCell)


func processTurnBegin() -> void:
	$EndStateSprite.visible = false
	$ReadyStateSprite.visible = true

	var randomDuration: float = randf_range(0.5, 3.0)
	$Timer.wait_time = randomDuration
	%WaitLabel.text = str(snappedf(randomDuration, 0.1), " WAITTIME")

	$AnimationPlayer.play(&"turnBegin")
	await $AnimationPlayer.animation_finished

	$Timer.start()
	await $Timer.timeout
	$WaitSprite.visible = false


func onDidUpdateTurn() -> void:
	pass


func processTurnEnd() -> void:
	$ReadyStateSprite.visible = false
	$EndStateSprite.visible = true


func onDidEndTurn() -> void:
	pass #endStateSprite.visible = false


func onTileBasedPositionComponent_willStartMovingToNewCell(_newDestination: Vector2i) -> void:
	# Longest name ever? :')
	$MovingStateSprite.visible = true


func onTileBasedPositionComponent_didArriveAtNewCell(_newDestination: Vector2i) -> void:
	$MovingStateSprite.visible = false


func _process(_delta: float) -> void:
	if shouldShowDebugInfo and $WaitSprite.visible:
		%WaitLabel.text = str("WAIT:", snappedf($Timer.time_left, 0.001))
