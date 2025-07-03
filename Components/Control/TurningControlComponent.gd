## Allows the player to rotate a node, such as a gun, with left & right input actions.
## May be combined with the [ThrustControlComponent] to provide "tank-like" controls, similar to Asteroids.
## ALERT: Mutually exclusive with [MouseRotationComponent] etc. Add an [InputComponent] to resolve with mouse-based components.
## Requirements: BEFORE [InputComponent], because input events propagate UPWARD from the BOTTOM of the Scene Tree nodes list.

class_name TurningControlComponent
extends InputDependentComponentBase

# TBD: Add angular friction i.e. slowdown/decay?


#region Parameters
@export_range(0.1, 20, 0.1) var rotationSpeed: float = 5.0

## Override this to rotate a different node instead of the parent [Entity], such as a [GunComponent].
@export var nodeToRotate: Node2D = null

## If `true` then [member InputComponent.aimDirection]'s X component is used for the turn direction, i.e. the Right Joystick.
## If `false` (default) then the [member InputComponent.turnInput] is used, i.e. the Left Joystick.
## TIP: Enable this to rotate a gun with the Right Joystick in dual-sick shoot-em-up games etc.
@export var shouldUseSecondaryAxis: bool = false

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		self.set_physics_process(isEnabled and not is_zero_approx(rotationDirection)) # PERFORMANCE: Set once instead of every frame
#endregion


#region State
var rotationDirection: float: ## The current rotation to apply to [param nodeToRotate] on every frame.
	set(newValue):
		# if newValue != rotationDirection: # PERFORMANCE: Skip comparison check
		rotationDirection = newValue
		self.set_physics_process(isEnabled and not is_zero_approx(rotationDirection))
#endregion


func _ready() -> void:
	super._ready()
	if not nodeToRotate: nodeToRotate = self.parentEntity
	self.set_physics_process(isEnabled and not is_zero_approx(rotationDirection)) # Apply setters because Godot doesn't on initialization
	Tools.connectSignal(inputComponent.didToggleMouseSuppression, self.onInputComponent_didToggleMouseSuppression)


func onInputComponent_didProcessInput(_event: InputEvent) -> void:
	# TBD: PERFORMANCE: Check if event was turn input?
	self.rotationDirection = inputComponent.turnInput if not shouldUseSecondaryAxis else inputComponent.aimDirection.x


func _physics_process(delta: float) -> void:
	# if not is_zero_approx(rotationDirection): # Checked by property setter
	nodeToRotate.rotation += (rotationSpeed * rotationDirection) * delta
	# DEBUG: Debug.watchList.rotationDirection = rotationDirection


func onInputComponent_didToggleMouseSuppression(shouldSuppressMouse: bool) -> void:
	self.isEnabled = shouldSuppressMouse
