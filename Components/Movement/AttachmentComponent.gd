## Sets the [member Node2D.position] of another node (which may be another [Entity]) to the position of this component on every frame.
## To implement "mounts" such as vehicles, horses etc. see [RideableComponent].

class_name AttachmentComponent
extends Component


#region Parameters
@export var nodeToAttach: CanvasItem
@export var offset: Vector2
@export var isEnabled: bool = true
#endregion


func _ready() -> void:
	if not nodeToAttach: printWarning("No nodeToAttach!")


func _process(_delta: float) -> void: # TBD: _process() or _physics_process()?
	if not isEnabled or not nodeToAttach: return
	# DESIGN: Set the attachee's position to this COMPONENT's position, NOT the Entity's position,
	# so that there may be an additional constant offset.
	nodeToAttach.global_position = self.global_position + offset
	if nodeToAttach is CollisionObject2D:
		nodeToAttach.reset_physics_interpolation() # CHECK: Is this necessary?
