## Extends [TileBasedControlComponent] to do random movement only.
## Requirements: Same as [TileBasedControlComponent]

class_name TileBasedRandomMovementComponent
extends TileBasedControlComponent


#region Parameters
## An array of steps to take from randomly on every [signal TImer.timeout] of the [member timer].
@export var horizontalMovesSet: Array[int] = [-1, 0, 1]

## An array of steps to take from randomly on every [signal TImer.timeout] of the [member timer].
@export var verticalMovesSet: Array[int] = [-1, 0, 1]
#endregion


#region State
@onready var stepTimer: Timer = $StepTimer
#endregion


func _ready() -> void:
	tileBasedPositionComponent.didArriveAtNewTile.connect(self.onTileBasedPositionComponent_didArriveAtNewTile)


func _input(event: InputEvent) -> void:
	pass # Supress TileBasedControlComponent


func _physics_process(delta: float) -> void:
	pass # Supress TileBasedControlComponent


func onTileBasedPositionComponent_didArriveAtNewTile(newDestination: Vector2i):
	if not isEnabled: return
	pass #stepTimer.start() # Unneeded if Timer is not `one_shot`


func onStepTimer_timeout() -> void:
	if not isEnabled: return
	self.recentInputVector = Vector2i(horizontalMovesSet.pick_random(), verticalMovesSet.pick_random())
	self.move()
