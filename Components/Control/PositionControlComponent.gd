## Sets the [Entity]'s position directly on player input, without any physics.
## May optionally use the secondary input axis such as the right gamepad joystick, to control the camera or an aiming cursor etc.
## TIP: For collision-aware movement, use physics components such as [OverheadPhysicsComponent] that update velocity through [CharacterBodyComponent]

class_name PositionControlComponent
extends Component

# TBD: Was this better as a simple standalone component that does not require [InputComponent]?
# TBD: Optional features like inertia for a better feeling of control? 


#region Parameters

@export_range(0, 1000, 8) var speed: float = 200

## If `true` (default), uses the "aim" aka "look" input actions such as [constant GlobalInput.Actions.aimLeft] etc.,
## which default to a secondary input axis such as the right gamepad joystick,
## that may be used to control a camera angle or an targeting cursor etc.
## TIP: If `true` then [member inputComponent.shouldJoystickAimingSuppressMouse] should be on.
## If `false` then [member inputComponent.shouldJoystickMovementSuppressMouse] should be on.
@export var shouldUseSecondaryAxis: bool = false:
	set(newValue):
		if newValue != shouldUseSecondaryAxis:
			shouldUseSecondaryAxis = newValue
			if self.is_node_ready():
				toggleInputSignals()
				syncInput()

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_process(isEnabled and not self.lastDirection.is_zero_approx())
			toggleInputSignals()

#endregion


#region State
var lastDirection: Vector2:
	set(newValue):
		if newValue != lastDirection:
			lastDirection = newValue
			self.set_process(isEnabled and not self.lastDirection.is_zero_approx())
#endregion


#region Dependencies
@onready var inputComponent: InputComponent = getCoComponent(InputComponent, true) # findSubclasses

func getRequiredComponents() -> Array[Script]:
	return [InputComponent]
#endregion


func _ready() -> void:
	toggleInputSignals()
	syncInput()
	self.set_process(isEnabled and not self.lastDirection.is_zero_approx()) # Apply setter because Godot doesn't on _ready()


func toggleInputSignals() -> void:
	Tools.toggleSignal(inputComponent.didUpdateMovementDirection, self.onInputComponent_didUpdateMovementDirection, self.isEnabled and not self.shouldUseSecondaryAxis)
	Tools.toggleSignal(inputComponent.didUpdateAimDirection,      self.onInputComponent_didUpdateAimDirection,      self.isEnabled and self.shouldUseSecondaryAxis)


func onInputComponent_didUpdateMovementDirection(movementDirection: Vector2, _difference: Vector2) -> void:
	# `shouldUseSecondaryAxis` checked by toggleInputSignals()
	self.lastDirection = movementDirection


func onInputComponent_didUpdateAimDirection(aimDirection: Vector2, _difference: Vector2) -> void:
	# `shouldUseSecondaryAxis` checked by toggleInputSignals()
	self.lastDirection = aimDirection


## Syncs [member lastDirection] with [member InputComponent.movementDirection] or [member InputComponent.aimDirection] depending on [member shouldUseSecondaryAxis]
func syncInput() -> void:
	self.lastDirection = inputComponent.movementDirection if not shouldUseSecondaryAxis else inputComponent.aimDirection


func _process(delta: float) -> void:
	# DESIGN: Use _process() instead of _physics_process() because this component directly changes visual position (e.g. for cursors) without CharacterBody2D physics etc.
	# NOTE: Cannot use _input() because `delta` is needed.
	entity.position += lastDirection * speed * delta
