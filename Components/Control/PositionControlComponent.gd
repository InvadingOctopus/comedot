## Sets the [Entity]'s position directly on player input, without any physics.
## May optionally use a secondary input axis such as the right gamepad joystick, to control the camera or an aiming cursor etc.

class_name PositionControlComponent
extends Component

# TBD: Optional features like inertia for a better feeling of control? 


#region Parameters

@export_range(0.0, 1000.0, 10.0) var speed: float = 200

## If `true`, uses the "look" input actions such as [const GlobalInput.Actions.lookLeft] etc.,
## which default to a secondary input axis such as the right gamepad joystick,
## that may be used to control a camera angle or an aiming cursor etc.
@export var shouldUseSecondaryAxis: bool = false

@export var isEnabled: bool = true

#endregion


#region State
var lastInput: Vector2 # NOTE: This is a class variable so that subclasses such as [PositionControlComponent] may access it.
#endregion


func _process(delta: float) -> void: # TBD: Should this be `_physics_process()` or `_process()`?
	# NOTE: Cannot use `_input()` because `delta` is needed.
	if not isEnabled: return
	
	if shouldUseSecondaryAxis:
		lastInput = Input.get_vector(
			GlobalInput.Actions.moveLeft,
			GlobalInput.Actions.moveRight,
			GlobalInput.Actions.moveUp,
			GlobalInput.Actions.moveDown)
	else:
		lastInput = Input.get_vector(
			GlobalInput.Actions.lookLeft,
			GlobalInput.Actions.lookRight,
			GlobalInput.Actions.lookUp,
			GlobalInput.Actions.lookDown)

	parentEntity.position += lastInput * speed * delta
