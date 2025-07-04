## Sets the [Entity]'s position directly on player input, without any physics.
## May optionally use the secondary input axis such as the right gamepad joystick, to control the camera or an aiming cursor etc.

class_name PositionControlComponent
extends Component

# TBD: Was this better as a simple standalone component that does not require [InputComponent]?
# TBD: Optional features like inertia for a better feeling of control? 


#region Parameters

@export_range(0.0, 1000.0, 10.0) var speed: float = 200

## If `true` (default), uses the "aim" aka "look" input actions such as [constant GlobalInput.Actions.aimLeft] etc.,
## which default to a secondary input axis such as the right gamepad joystick,
## that may be used to control a camera angle or an targeting cursor etc.
## TIP: If `true` then [member inputComponent.shouldJoystickAimingSuppressMouse] should be on.
## If `false` then [member inputComponent.shouldJoystickMovementSuppressMouse] should be on.
@export var shouldUseSecondaryAxis: bool = false

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled and not self.lastDirection.is_zero_approx())
			Tools.toggleSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput, self.isEnabled)

#endregion


#region State
var lastDirection: Vector2:
	set(newValue):
		if newValue != lastDirection:
			lastDirection = newValue
			self.set_physics_process(isEnabled and not self.lastDirection.is_zero_approx())
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent)

func getRequiredComponents() -> Array[Script]:
	return [InputComponent]
#endregion


func _ready() -> void:
	Tools.toggleSignal(inputComponent.didProcessInput, self.onInputComponent_didProcessInput, self.isEnabled)
	self.set_physics_process(isEnabled and not self.lastDirection.is_zero_approx()) # Apply setter because Godot doesn't on initialization


func onInputComponent_didProcessInput(_event: InputEvent) -> void:
	self.lastDirection = inputComponent.movementDirection if not shouldUseSecondaryAxis else inputComponent.aimDirection


func _process(delta: float) -> void: # TBD: Should this be `_physics_process()` or `_process()`?
	# NOTE: Cannot use _input() because `delta` is needed.
	parentEntity.position += lastDirection * speed * delta
