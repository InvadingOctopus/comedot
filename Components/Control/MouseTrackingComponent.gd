## Moves the entity to the mouse position, immediately or gradually.
## TIP: An optional [InputComponent] resolves exclusivity conflicts versus joystick-based components such as [PositionControlComponent].

class_name MouseTrackingComponent
extends Component


#region Parameters
@export var shouldRepositionImmediately: bool = true

@export_range(0, 1000, 5) var speed: float = 100 ## Effective only if not [member shouldRepositionImmediately].

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled)
#endregion


func _ready() -> void:
	self.set_physics_process(isEnabled) # Apply setter because Godot doesn't on initialization

	var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent)
	if  inputComponent:
		Tools.connectSignal(inputComponent.didToggleMouseSuppression, self.onInputComponent_didToggleMouseSuppression)


func onInputComponent_didToggleMouseSuppression(shouldSuppressMouse: bool) -> void:
	self.isEnabled = not shouldSuppressMouse


func _physics_process(delta: float) -> void:
	# NOTE: Cannot use _input() because `delta` is needed here.

	if shouldRepositionImmediately:
		parentEntity.global_position = parentEntity.get_global_mouse_position()
	else:
		parentEntity.global_position = parentEntity.global_position.move_toward(parentEntity.get_global_mouse_position(), speed * delta)

	parentEntity.reset_physics_interpolation() # CHECK: Apparently necessary to avoid intermediate positioning for 1 or more frames.
