## Rotates the parent [Entity] or a different [Node2D] every frame.
## NOTE: Uses [method Node._physics_process] instead of [method Node._process] for consistency with other physics-based movement.

class_name SpinComponent
extends Component


#region Parameters
@export var nodeToRotate: Node2D ## If unspecified, this component's parent Entity is rotated.
@export_range(-20, 20, 0.1) var rotationPerFrame: float = 1.0
@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled)
#endregion


func _ready() -> void:
	if not nodeToRotate: self.nodeToRotate = parentEntity


func _physics_process(delta: float) -> void:
	# if not isEnabled: return # Set by property setter
	nodeToRotate.rotation += rotationPerFrame * delta
