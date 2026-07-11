## Wraps a [Camera2D] node with the `/Scripts/Visual/Camera.gd` script to support clamping within an [Area2D], look ahead, etc.
## Also reattaches the camera to another parent node when this component's [Entity] is destroyed,
## e.g. to prevent the on-screen view from resetting when the player dies.
## TIP: To access the underlying [Camera2D], enable "Editable Children" in the Godot Editor.
## TIP: For non-component scripts for standalone [Camera2D] nodes, use `/Scripts/Visual/Camera.gd` directly.
## ALERT: BUG: There may be an initial lag or unintended pan at the start of a scene as the [Camera2D] moves to its parent node's position, especially when [member Camera2D.position_smoothing_enabled] is `true`
## WORKAROUND: To avoid this initial lag, add a standalone [Camera2D] outside the player [Entity], at the same position as this [CameraComponent],
## and add a [RemoteTransform2D] as a child of this component, then link the [RemoteTransform2D] to the external [Camera2D]

class_name CameraComponent
extends Component


#region Parameters

## If `true`, this component detaches its child [Camera2D] when the [Entity] is being removed,
## then the camera is reattached to [member reparentPath] if specified, otherwise to the Entity's parent node (this component's grandparent)
## or the scene's root node.
## TIP: This may prevent the view from jumping to another position when the player dies etc.
@export var shouldReparentCameraOnEntityRemoval: bool = true: # TBD: A shorter name? :')
	set(newValue):
		if newValue != shouldReparentCameraOnEntityRemoval:
			shouldReparentCameraOnEntityRemoval = newValue
			if entity: Tools.toggleSignal(entity.preDelete, self.onEntity_preDelete, self.shouldReparentCameraOnEntityRemoval)

## Optional: The relative path to the parent node that the [Camera2D] should be reparented to when the [Entity] is removed.
## If empty, the camera reattaches to this component's grandparent node (the entity's parent)
## or the scene's root node.
## IMPORTANT: The path must resolve to a [Node2D] or one of its subclasses.
@export_node_path("Node2D") var reparentPath: NodePath = "../.." # Default: Relative from Component → Entity → Entity's Parent

#endregion


#region State
# TBD: Allow management of an external [Camera2D]?
@onready var camera: Camera = $Camera2D
#endregion


func _ready() -> void:
	if  camera:
		camera.debugMode = self.debugMode
		entity.camera	 = self.camera # Repeat incase it wasn't ready during onDidInstall() TBD: Check before overwriting an existing camera?
	else:
		printWarning("CameraComponent does not have a Camera2D node!")


#region Camera Reparenting

func onDidInstall() -> void:
	if self.camera: entity.camera = self.camera # TBD: Check before overwriting an existing camera?
	Tools.toggleSignal(entity.preDelete, self.onEntity_preDelete, self.shouldReparentCameraOnEntityRemoval)


func onWillUninstall() -> void:
	# Unregister the camera if it's still attached to the entity
	if self.camera and entity.camera == self.camera and self.entity.is_ancestor_of(self.camera): entity.camera = null
	if entity: Tools.disconnectSignal(entity.preDelete, self.onEntity_preDelete)


func onEntity_preDelete() -> void:
	if entity: Tools.disconnectSignal(entity.preDelete, self.onEntity_preDelete) # Prevent multiple calls
	# `Entity.preDelete` may be emitted after this component has already exited the scene during shutdown,
	# so make sure we're still around
	if not shouldReparentCameraOnEntityRemoval or not self.is_inside_tree(): return
	reattachCamera()


## Detaches the [Camera2D] and reattaches it to another node at the relative [member reparentPath]
## If no path is specified, then the camera is attached to the entity's parent node (this component's grandparent)
## or the scene's root node.
func reattachCamera() -> bool:
	if not is_instance_valid(camera):
		printWarning("reattachCamera(): Camera missing")
		return false

	if debugMode:  printDebug(str("reattachCamera() reparentPath: ", reparentPath))

	var newParent: Node2D

	# First, have we manually chosen a stepparent?
	# NOTE: Do NOT automatically fallback if there is a path specified, that could cause unexpected behavior at runtime:
	# DESIGN: If a path is specified but invalid, log a warning but don't silently choose a different parent.
	if not reparentPath.is_empty():
		newParent = self.get_node_or_null(reparentPath)

	# Otherwise, look for other nodes to adopt the camera
	else:
		# Does this component have a valid parent? i.e. the entity
		var currentParent: Node2D = self.get_parent()
		# Then use the entity's parent as the new parent for the camera
		if currentParent: newParent = currentParent.get_parent()
		# Otherwise just yeet the camera to the scene root
		if not newParent: newParent = self.get_tree().current_scene if self.is_inside_tree() else null

	# Still no valid prospective parent?
	if not is_instance_valid(newParent):
		printWarning(str("reattachCamera() cannot resolve reparentPath or fallback to Entity's parent or Scene root: ", reparentPath))
		return false

	# Make sure the new parent isn't a descendant of the dying Entity, which would be pointless :')
	if entity and (newParent == entity or entity.is_ancestor_of(newParent)):
		printWarning(str("reattachCamera() reparentPath: ", reparentPath, " must not be inside the Entity being removed: ", entity))
		return false

	if not camera.reattach(newParent):
		printWarning(str("reattachCamera() could not reattach Camera to: ", newParent))
		return false

	return true

#endregion
