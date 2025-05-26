## Rotates the parent [Entity] or a different [Node2D] every frame.
## NOTE: Uses [method Node._physics_process] instead of [method Node._process] for consistency with other physics-based movement.

class_name SpinComponent
extends Component


#region Parameters
@export var nodeToRotate: Node2D ## If unspecified, this component's parent Entity is rotated.

@export_range(-20, 20, 0.1) var rotationPerFrame: float = 1.0:
	set(newValue):
		rotationPerFrame = newValue
		self.set_physics_process(isEnabled and not is_zero_approx(rotationPerFrame))

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		self.set_physics_process(isEnabled and not is_zero_approx(rotationPerFrame)) # PERFORMANCE: Set once instead of every frame
#endregion


func _ready() -> void:
	if not nodeToRotate: self.nodeToRotate = parentEntity
	self.set_physics_process(isEnabled and not is_zero_approx(rotationPerFrame)) # Apply setters because Godot doesn't on initialization


func _physics_process(delta: float) -> void: # TBD: _physics_process() instead of _process() because movement may interact with physics, right?
	nodeToRotate.rotation += rotationPerFrame * delta
