## A component which is a [Camera2D] node with various options,
## such as attaching to a grandparent Node when the parent [Entity] is destroyed, to preserve the on screen viewing position.
## TIP: For standalone non-component scripts for any [Camera2D] node, see the `/Scripts/Visual/` folder and CameraMouseTracking.gd, ClampCameraToArea.gd etc.
## ALERT: BUG: There may be an initial delay or undesiring panning as the start of scene as the [Camera2D] moves to the parent node's position, specially if [member Camera2D.position_smoothing_enabled] is `true`.
## BUGFIX: To workaround the initial lag, add a standalone [Camera2D] outside the player Entity, at the same position as this [CameraComponent], and add a [RemoteTransform2D] as a child of this component, then link the [RemoteTransform2D] with the external [Camera2D].

class_name CameraComponent
extends Component

# TODO: FIXME: There is still a slight jitter when reattaching to a new parent.
# TODO: Gamepad joystick look-ahead


#region Parameters

## If `true`, the camera is detached from the parent [Entity] and reattached to the Entity's parent, if any, or the root Node of the current Scene.
## This may be used to prevent the scene view from jumping to another position to the when the player dies.
## NOTE: [member Component.allowNonEntityParent] should be set to `true`
@export var shouldAttachToGrandparentOnEntityRemoval: bool = true # TBD: A shorter name? Yikes!

## Confines the camera to the rectangular bounds of the [member boundary]
@export var shouldClampToBoundary:	bool = false

## The [Area2D] to clamp the camera's position within its rectangular bounds, if [member shouldClampToBoundary]
@export var boundary: Area2D:
	set(newValue):
		if boundary != newValue:
			boundary = newValue
			if self.is_node_ready(): clampToBoundary()

## Moves the camera to the mouse position on every frame.
## NOTE: Overridden by [member shouldLookAhead]
## @experimental
@export var shouldTrackMouse:		bool = false:
	set(newValue):
		if newValue != shouldTrackMouse:
			shouldTrackMouse = newValue
			self.set_process(shouldTrackMouse or shouldBounceZoom)

## Moves the camera further to the edge of the screen towards the mouse pointer.
## NOTE: Overrides [member shouldTrackMouse]
## @experimental
@export var shouldLookAhead:		bool = false: # TBD: Should this be mouse only?
	set(newValue):
		if newValue != shouldLookAhead:
			shouldLookAhead = newValue
			self.set_process_input(shouldLookAhead)

## How far the [member shouldLookAhead] target (mouse pointer) should be from the center of the screen for the camera offset to start moving towards the edge of the screen.
## @experimental
@export var lookAheadDeadZone:	   float = 64

## "Bounces" or "headbangs" the camera zoom back and forth in and out of the screen. Useful for inducing dizziness.
## @experimental
@export var shouldBounceZoom:		bool = false:
	set(newValue):
		if newValue != shouldBounceZoom:
			shouldBounceZoom = newValue
			self.set_process(shouldTrackMouse or shouldBounceZoom)

@export_range(0.0, 10.0, 0.05) var zoomTimerMax:  float = 0.2 ## The number/fraction of seconds for the zoom direction to flip between "in" and "out".
@export_range(0.0, 10.0, 0.05) var zoomDirection: float = 0.2 ## The distance/intensity of the zoom. Swaps sign/"direction" during runtime.

#endregion


#region State
var selfAsCamera:	Camera2D # Necessary because `Component` is a `Node` not `Node2D` :')
var camera:			Camera2D # The actual camera in use. TODO: Expose as @export for using external [Camera2D] nodes.
var zoomFlipTimer:	float
#endregion


func _ready() -> void:
	selfAsCamera = self.get_node(^".") as Camera2D
	if not camera: camera = selfAsCamera

	if camera:
		if boundary: clampToBoundary()
		if shouldTrackMouse: self.position = camera.get_local_mouse_position()

		self.set_process(shouldTrackMouse or shouldBounceZoom) # Update per-frame only if needed
		self.set_process_input(shouldLookAhead)

	else:
		printWarning("CameraComponent is not a Camera2D node!")
	
	camera.align()
	camera.force_update_scroll()


#region Detachment & Reattachment

func registerEntity(newParentEntity: Entity) -> void:
	# NOTE: This method is overridden in order to reconnect signals in case the new parent is also an Entity.
	super.registerEntity(newParentEntity)
	if newParentEntity: connectSignals() # Make sure the new parent is an Entity


func connectSignals() -> void:
	Tools.connectSignal(parentEntity.preDelete, self.onEntity_preDelete)


func onEntity_preDelete() -> void:
	if parentEntity:
		Tools.disconnectSignal(parentEntity.preDelete, self.onEntity_preDelete) # Prevent multiple calls!
	if shouldAttachToGrandparentOnEntityRemoval:
		self.cancel_free() # We still want to live!
		attachToGrandparent()


## Detaches the camera from the [Entity] and reattaches to the Entity's parent, if any, or the root Node of the current Scene.
## This may prevent the scene view from jumping to another position to the when a player dies etc.
## NOTE: Does NOT check for [member shouldAttachToGrandparentOnParentRemoval] as it must done by other event-handling methods.
func attachToGrandparent() -> void:
	# TBD: Should we still detach from any parent, not just an Entity?
	if not is_instance_valid(parentEntity): return
	if debugMode: printDebug(str("attachToGrandparent(): Detaching from parent entity: ", parentEntity))

	# See if the Entity has a parent
	var newParent: Node
	newParent = parentEntity.get_parent()

	# If not, just put this camera on the scene tree
	if not is_instance_valid(newParent):
		newParent = SceneManager.get_tree().current_scene # FINDBETTERWAY: How else to get the damn SceneTree from a Node that's not in the SceneTree???

	if debugMode: printDebug(str("Reattaching to new parent: ", newParent, " @ global position: ", camera.global_position))

	camera.position_smoothing_enabled = false # TODO: FIXME: HACK: Fix jump/hitter :(
	self.owner = null
	self.reparent(newParent, true) # keep_global_transform
	self.set_owner(newParent)
	camera.reset_smoothing()

	if debugMode: printDebug(str("New position: ", camera.position, ", global: ", camera.global_position))

#endregion


#region Boundary

func clampToBoundary() -> void:
	if not boundary: return

	var areaRectangle: Rect2 = Tools.getShapeGlobalBounds(boundary)

	if not areaRectangle:
		Debug.printWarning(str("Cannot get a Rect2 from Area2D: ", boundary), self)

	camera.limit_left   = int(areaRectangle.position.x)
	camera.limit_right  = int(areaRectangle.end.x)
	camera.limit_top	  = int(areaRectangle.position.y)
	camera.limit_bottom = int(areaRectangle.end.y)
	
	camera.reset_smoothing()

#endregion


#region Per-Frame

func _process(delta: float) -> void:
	# NOTE: Cannot use `_input()` for updating position only on mouse events, because it causes erratic behavior.
	if shouldTrackMouse:
		camera.position = camera.get_global_mouse_position() * (0.5) # CHECK: WEIRD: Using the global position and halving it smoothes movement and fixes erratic behavior.

	# Woop Zoop
	if shouldBounceZoom:
		camera.zoom += Vector2(zoomDirection * delta, zoomDirection * delta) # Camera2D.zoom
		zoomFlipTimer += delta
		if zoomFlipTimer >= zoomTimerMax:
			zoomDirection = -zoomDirection
			zoomFlipTimer = 0


## @experimental
func _input(event: InputEvent) -> void:
	# Look Ahead
	# THANKS: Inspired by optionaldev2876@YouTube https://www.youtube.com/watch?v=Wzrw6_KDMl4
	if shouldLookAhead and event is InputEventMouseMotion:
		var viewport: Rect2 = camera.get_viewport_rect() # Get the unscaled Viewport dimensions
		var target: Vector2 = event.position - (viewport.size * 0.5) # Get the mouse position from the center of the screen

		if target.length() < lookAheadDeadZone: # Move the camera offset only when the target is far enough from the center.
			camera.offset = Vector2.ZERO
		else:
			camera.offset = target.normalized() * (target.length() - lookAheadDeadZone) * 0.5

		if debugMode: printDebug(str("event.position: ", event.position, ", viewport.half: ", viewport.size * 0.5, ", target: ", target, ", target.normalized: ", target.normalized(), ", target.length: ", target.length(), ", Camera2D.offset: ", camera.offset))

#endregion


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.addComponentWatchList(self, {
		boundary		= self.boundary.position,
		limit_left  	= camera.limit_left,
		limit_right 	= camera.limit_right,
		limit_top		= camera.limit_top,
		limit_bottom	= camera.limit_bottom,
		})
