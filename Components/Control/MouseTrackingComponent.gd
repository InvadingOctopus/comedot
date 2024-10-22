## Moves the entity to the mouse position, immediately or gradually.

class_name MouseTrackingComponent
extends Component


#region Parameters
@export var shouldRepositionImmediately: bool = true
@export_range(0, 1000, 5) var speed: float = 100
@export var isEnabled := true
#endregion


func _physics_process(delta: float) -> void:
	# NOTE: Cannot use `_input()` because `delta` is needed here.
	if not isEnabled: return
	if shouldRepositionImmediately:
		parentEntity.global_position = parentEntity.get_global_mouse_position()
	else:
		parentEntity.global_position = parentEntity.global_position.move_toward(parentEntity.get_global_mouse_position(), speed * delta)
