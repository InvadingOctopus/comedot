## Rotates the parent [Entity] OR the parent [Node] every frane,

class_name SpinComponent
extends Component


@export var isPaused := false
@export var shouldRotateParentNodeInsteadOfEntity := false
@export_range(-20, 20, 0.1) var rotationAmount: float = 1.0


var parent: Node2D


func _ready() -> void:
	self.parent = get_parent()


func _physics_process(delta: float) -> void:

	if isPaused: return

	# Which node to rotate?

	if shouldRotateParentNodeInsteadOfEntity:
		self.parent.rotation += rotationAmount * delta
	else:
		parentEntity.rotation += rotationAmount * delta
