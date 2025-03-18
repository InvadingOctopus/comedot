## A component which is a [Camera2D] node with various options,
## such as attaching to a grandparent Node when the parent [Entity] is destroyed, to preserve the on screen viewing position.
## TIP: For standalone non-component scripts for any [Camera2D] node, see the `/Scripts/Visual/` folder and CameraMouseTracking.gd, ClampCameraToArea.gd etc.

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
var selfAsCamera:  Camera2D # Necessary because `Component` is a `Node` not `Node2D` :')
var zoomFlipTimer: float
#endregion


func _ready() -> void:
	self.selfAsCamera = self.get_node(^".") as Camera2D

	if selfAsCamera:
		if boundary: clampToBoundary()
		if shouldTrackMouse: self.position = selfAsCamera.get_local_mouse_position()

		self.set_process(shouldTrackMouse or shouldBounceZoom) # Update per-frame only if needed
		self.set_process_input(shouldLookAhead)

	else:
		printWarning("CameraComponent is not a Camera2D node!")


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

	if debugMode: printDebug(str("Reattaching to new parent: ", newParent, " @ global position: ", selfAsCamera.global_position))

	selfAsCamera.position_smoothing_enabled = false # TODO: FIXME: HACK: Fix jump/hitter :(
	self.owner = null
	self.reparent(newParent, true) # keep_global_transform
	self.set_owner(newParent)
	selfAsCamera.reset_smoothing()

	if debugMode: printDebug(str("New position: ", selfAsCamera.position, ", global: ", selfAsCamera.global_position))

#endregion


#region Boundary

func clampToBoundary() -> void:
	if not boundary: return

	var areaRectangle: Rect2 = Tools.getShapeGlobalBounds(boundary)

	if not areaRectangle:
		Debug.printWarning(str("Cannot get a Rect2 from Area2D: ", boundary), self)

	selfAsCamera.limit_left   = int(areaRectangle.position.x)
	selfAsCamera.limit_right  = int(areaRectangle.end.x)
	selfAsCamera.limit_top	  = int(areaRectangle.position.y)
	selfAsCamera.limit_bottom = int(areaRectangle.end.y)

#endregion


#region Per-Frame

func _process(delta: float) -> void:
	# NOTE: Cannot use `_input()` for updating position only on mouse events, because it causes erratic behavior.
	if shouldTrackMouse:
		selfAsCamera.position = selfAsCamera.get_global_mouse_position() * (0.5) # CHECK: WEIRD: Using the global position and halving it smoothes movement and fixes erratic behavior.

	# Woop Zoop
	if shouldBounceZoom:
		selfAsCamera.zoom += Vector2(zoomDirection * delta, zoomDirection * delta) # Camera2D.zoom
		zoomFlipTimer += delta
		if zoomFlipTimer >= zoomTimerMax:
			zoomDirection = -zoomDirection
			zoomFlipTimer = 0


## @experimental
func _input(event: InputEvent) -> void:
	# Look Ahead
	# THANKS: Inspired by optionaldev2876@YouTube https://www.youtube.com/watch?v=Wzrw6_KDMl4
	if shouldLookAhead and event is InputEventMouseMotion:
		# Get the unscaled Viewport dimensions
		var viewport: Rect2 = selfAsCamera.get_viewport_rect()
		# Get the mouse position from the center of the screen
		var target: Vector2 = event.position - (viewport.size * 0.5)

		if target.length() < lookAheadDeadZone: # Move the camera offset only when the target is far enough from the center.
			selfAsCamera.offset = Vector2.ZERO
		else:
			selfAsCamera.offset = target.normalized() * (target.length() - lookAheadDeadZone) * 0.5

		if debugMode: printDebug(str("event.position: ", event.position, ", viewport.half: ", viewport.size * 0.5, ", target: ", target, ", target.normalized: ", target.normalized(), ", target.length: ", target.length(), ", Camera2D.offset: ", selfAsCamera.offset))

#endregion


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.boundary		= self.boundary.position
	Debug.watchList.limit_left  	= selfAsCamera.limit_left
	Debug.watchList.limit_right 	= selfAsCamera.limit_right
	Debug.watchList.limit_top		= selfAsCamera.limit_top
	Debug.watchList.limit_bottom	= selfAsCamera.limit_bottom
