## Rotates the parent [Entity] OR the parent [Node] towards the mouse pointer.

class_name MouseRotationComponent
extends Component


#region parameters

## Override this to rotate a different node instead of the parent [Entity], such as a [GunComponent].
@export var nodeToRotate: Node2D = null

@export_range(0.1, 20, 0.1) var rotationSpeed: float = 5.0

@export var shouldRotateInstantly := false
@export var isEnabled := true

#endregion


func _ready():
	if not nodeToRotate:
		nodeToRotate = self.parentEntity


func _physics_process(delta: float):
	if not isEnabled: return

	# NOTICE: Can't use `get_global_mouse_position()` because Component is not a CanvasItem :(
	# `DisplayServer.mouse_get_position()` doesn't work well either.
	# TBD: Where to `get_global_mouse_position()` from?
	var mousePosition := parentEntity.get_global_mouse_position()

	# Rotate instantly or gradually?

	if shouldRotateInstantly:
		nodeToRotate.look_at(mousePosition)
	else:
		var nodePosition  := nodeToRotate.global_position
		var rotateFrom    := nodeToRotate.global_rotation
		var rotateTo      := nodePosition.angle_to_point(mousePosition)

		#%DebugInfo.text = "node.rotation: %s
#rotateFrom: %s
#rotateTo: %s
#localMousePosition: %s
#globalMousePosition: %s
		#" % [nodeToRotate.rotation, rotateFrom, rotateTo, get_local_mouse_position(), get_global_mouse_position()]

		nodeToRotate.global_rotation = rotate_toward(rotateFrom, rotateTo, rotationSpeed * delta)

