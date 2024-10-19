## Provides player input to a [TileBasedPositionComponent].
## Requirements: [TileBasedPositionComponent]

class_name TileBasedControlComponent
extends Component

# TODO: Allow movement on input `is_just_released`


#region Parameters
@export var isEnabled:				bool = true
@export var shouldAllowDiagonals:	bool = false
@export var shouldMoveContinuously:	bool = true
#endregion


#region State
var recentInputVector: Vector2i:
	set(newValue): printChange("recentInputVector", recentInputVector, newValue); recentInputVector = newValue # DEBUG

@onready var timer: Timer = $Timer
@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent # TBD: Static or dynamic?
#endregion


func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent]


func _input(event: InputEvent) -> void:
	if not isEnabled or not event.is_action_type(): return

	if GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveLeft) \
	or GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveRight) \
	or GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveUp) \
	or GlobalInput.hasActionTransitioned(GlobalInput.Actions.moveDown):

		var inputVectorFloat: Vector2 = Input.get_vector(
			GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, \
			GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)

		if shouldAllowDiagonals:
			self.recentInputVector = Vector2i(int(signf(inputVectorFloat.x)), int(signf(inputVectorFloat.y))) # IGNORE: Godot Warning; `float` to `int` conversion is obvious.
		else: # Fractional axis values will get zeroed in the conversion to integers.
			self.recentInputVector = Vector2i(inputVectorFloat)

		move()



func _physics_process(_delta: float) -> void:
	if not isEnabled or not shouldMoveContinuously: return
	move()


## Tells the [TileBasedPositionComponent] to move to the [member recentInputVector].
## Uses a [Timer] to add a delay between each step.
## NOTE: Does not depend on [member isEnabled]
func move() -> void:
	if is_zero_approx(recentInputVector.length()) or not is_zero_approx(timer.time_left):
		return

	tileBasedPositionComponent.inputVector = self.recentInputVector
	tileBasedPositionComponent.processMovementInput()
	timer.start()
