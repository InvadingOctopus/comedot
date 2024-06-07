## Monitors and stores the player's input axes for other "Control" components to act upon.
## NOTE: To improve performance, small independent control components may do their own input polling. Therefore, this [PlayerInputComponent] makes most sense when a chain of multiple components depend upon it, such as [TurningControlComponent] + [ThrustControlComponent].
## Requirements: Should be BEFORE all "Control" components

class_name PlayerInputComponent
extends Component


#region Parameters
@export var isEnabled: bool = true
#endregion


#region State
var inputDirection:		Vector2
var lastInputDirection:	Vector2

var horizontalInput:	float
var verticalInput:		float
var turnInput:			float ## For the Right Joystick, may be identical to [member horizontalInput]
#endregion


#region Signals
# TBD: Should we add signals for actions like Jump and Fire?
#endregion


func _input(event: InputEvent):
	if not isEnabled: return
	pass # Handle one-shot input events such as jumping or firing.


func _process(delta: float):
	# TBD: Should we do this in [_process] or [_physics_process]?
	if not isEnabled: return

	self.inputDirection		= Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
	self.verticalInput		= Input.get_axis(GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
	self.horizontalInput	= Input.get_axis(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight)
	self.turnInput			= Input.get_axis(GlobalInput.Actions.turnLeft, GlobalInput.Actions.turnRight)

	if inputDirection: lastInputDirection = inputDirection

	# TODO: CHECK: Does this work for joystick input?

	#debugInfo()


func debugInfo():
	Debug.watchList.inputDirection		= inputDirection
	Debug.watchList.lastInputDirection	= lastInputDirection
	Debug.watchList.verticalInput		= verticalInput
	Debug.watchList.horizontalInput		= horizontalInput
