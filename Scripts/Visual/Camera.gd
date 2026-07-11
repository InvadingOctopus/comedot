## Adds extra features and conveniences to [Camera2D] such as clamping within an [Area2D], look ahead,
## and attaching to a different parent node while retaining the view position, e.g. for when the player dies etc.
## TIP: Use [CameraComponent] for [Entity]s such as the player character.

class_name Camera
extends Camera2D

# TODO: Add a "zoomToFitBoundary" option
# TODO: Gamepad joystick look-ahead


#region Parameters

## Shifts the camera's [member Node2D.position] in relation to the mouse position on every frame.
## TIP: This effectively puts the entity on the opposite side of the screen when the mouse pointer is at the screen's edge.
## TIP: The caller should reset [member Camera2D.offset] when enabling and reset [member Node2D.position] when disabling.
## NOTE: Suppressed by [member shouldLookAhead]
## @experimental
@export var shouldTrackMouse: bool = false:
	set(newValue):
		if newValue != shouldTrackMouse:
			shouldTrackMouse = newValue
			self.set_process((shouldTrackMouse and not shouldLookAhead) or shouldBounceZoom)

@export var debugMode: bool = false


@export_group("Boundary")

## Confines the camera to the rectangular bounds of the [Area2D] referenced by [member boundary] if any, on [method _ready]
@export var shouldClampToBoundaryOnReady: bool = true

## The [Area2D] to clamp the camera's position within its rectangular bounds.
## Setting this to `null` resets all distances to 10,000,000
@export var boundary: Area2D:
	set(newValue):
		if boundary != newValue:
			boundary = newValue
			if self.is_node_ready():
				if boundary: clampToBoundary()
				else: unclampFromBoundary()


@export_group("Look Ahead")

## If enabled, the [member Camera2D.offset] is modified to move the camera further to the edge of the screen towards the mouse pointer, whenever the mouse moves.
## TIP: The caller should reset [member Node2D.position] when enabling and reset [member Camera2D.offset] when disabling.
## NOTE: Suppresses [member shouldTrackMouse]
## @experimental
@export var shouldLookAhead: bool = false: # TBD: Should this be mouse only?
	set(newValue):
		if newValue != shouldLookAhead:
			shouldLookAhead = newValue
			self.set_process_input(shouldLookAhead)
			self.set_process((shouldTrackMouse and not shouldLookAhead) or shouldBounceZoom)

## How far the [member shouldLookAhead] target (mouse pointer) should be from the center of the screen
## for the camera offset to start moving towards the edge of the screen.
## @experimental
@export var lookAheadDeadZone: float = 64

@export_group("Zoom Bounce")

## "Bounces" or "headbangs" the camera zoom back and forth in and out of the screen.
## TIP: Useful for inducing dizziness.
## @experimental
@export var shouldBounceZoom: bool = false:
	set(newValue):
		if newValue != shouldBounceZoom:
			shouldBounceZoom = newValue
			self.set_process((shouldTrackMouse and not shouldLookAhead) or shouldBounceZoom)

@export_range(0.0, 10.0, 0.05) var zoomTimerMax:  float = 0.2 ## The number/fraction of seconds for the zoom direction to flip between "in" and "out".
@export_range(0.0, 10.0, 0.05) var zoomDirection: float = 0.2 ## The distance/intensity of the zoom. Swaps sign/"direction" during runtime.

#endregion


#region State
var parent:			Node2D # TBD: Support non-Node2D parents?
var zoomFlipTimer:	float
#endregion


func _ready() -> void:
	parent = self.get_parent() as Node2D
	if shouldClampToBoundaryOnReady and boundary: clampToBoundary()

	var shouldUpdateEveryFrame: bool = (shouldTrackMouse and not shouldLookAhead) or shouldBounceZoom
	self.set_process(shouldUpdateEveryFrame)
	self.set_process_input(shouldLookAhead)
	# Update the initial position etc.
	if shouldUpdateEveryFrame: self._process(0)
	self.align() # Does not require calling force_update_scroll() afterwards


#region Boundary

## NOTE: Does NOT check [member shouldClampToBoundaryOnReady]
func clampToBoundary() -> void:
	if not boundary: return

	# DESIGN: Do NOT attempt to fix or undo invalid boundaries; an Area2D may change later and the caller can repeat clampToBoundary at any time.
	# DESIGN: Do NOT automatically unclamp: Silently allowing the player to access a wider area may lead to more bugs!

	var areaRectangle: Rect2 = CollisionTools.getAllShapeGlobalBounds(boundary)
	if not areaRectangle.has_area():
		Debug.printWarning(str("clampToBoundary(): Cannot get a Rect2 from Area2D: ", boundary), self)
		return

	self.limit_left		= int(areaRectangle.position.x)
	self.limit_top		= int(areaRectangle.position.y)
	self.limit_right	= int(areaRectangle.end.x)
	self.limit_bottom	= int(areaRectangle.end.y)

	self.reset_smoothing() # Snap immediately


func unclampFromBoundary() -> void:
	const defaultDistance: int = 10_000_000
	self.limit_left		= -defaultDistance
	self.limit_top		= -defaultDistance
	self.limit_right	=  defaultDistance
	self.limit_bottom	=  defaultDistance
	self.reset_smoothing() # Snap immediately

#endregion


#region Per-Frame

func _process(delta: float) -> void:
	# NOTE: Cannot use `_input()` for updating position only on mouse events, because it causes erratic behavior.
	if shouldTrackMouse and not shouldLookAhead:
		# Position the camera halfway between the entity/parent node's origin and the mouse.
		# NOTE: This effectively puts the entity/parent on the opposite side of the screen when the mouse pointer is at the screen's edge.
		self.position = parent.to_local(self.get_global_mouse_position()) * 0.5 # DESIGN: Missing `parent` should crash

	# Woop Zoop
	if shouldBounceZoom and not is_zero_approx(delta):
		self.zoom += Vector2(zoomDirection * delta, zoomDirection * delta) # Camera2D.zoom
		zoomFlipTimer += delta
		if  zoomFlipTimer >= zoomTimerMax:
			zoomDirection = -zoomDirection
			zoomFlipTimer = 0


## @experimental
func _input(event: InputEvent) -> void:
	# Look Ahead
	# THANKS: Inspired by optionaldev2876@YouTube https://www.youtube.com/watch?v=Wzrw6_KDMl4
	if shouldLookAhead and event is InputEventMouseMotion:
		var viewport: Rect2 = self.get_viewport_rect() # Get the unscaled Viewport dimensions
		var target: Vector2 = event.position - (viewport.size * 0.5) # Get the mouse position from the center of the screen

		if target.length() < lookAheadDeadZone: # Move the camera offset only when the target is far enough from the center.
			self.offset = Vector2.ZERO
		else:
			self.offset = target.normalized() * (target.length() - lookAheadDeadZone) * 0.5

		if debugMode: Debug.printDebug(str("event.position: ", event.position, ", viewport.half: ", viewport.size * 0.5, ", target: ", target, ", target.normalized: ", target.normalized(), ", target.length: ", target.length(), ", Camera2D.offset: ", self.offset), self)

#endregion


#region Reattachment

## Detaches this camera from its current parent and reattaches it to [param newParent] while maintaining the current view position & rotation.
## TIP: Useful for preventing the camera from resetting/jumping when the player dies etc.
## Returns `true` if the camera is successfully moved to or is already attached to [param newParent]
func reattach(newParent: Node2D) -> bool: # Can't name it "reparent()" because Godot already has a function with that name
	if not self.is_inside_tree():
		Debug.printWarning("reattach(): Camera is not inside the SceneTree", self)
		return false

	if not is_instance_valid(newParent):
		Debug.printWarning(str("reattach(): Invalid new parent: ", newParent), self)
		return false

	if not newParent.is_inside_tree():
		Debug.printWarning(str("reattach(): New parent is not inside the SceneTree: ", newParent), self)
		return false

	if self == newParent or self.is_ancestor_of(newParent):
		Debug.printWarning(str("reattach(): Cannot reparent the camera to itself or a descendant: ", newParent), self)
		return false

	self.parent = self.get_parent() # TBD: Support non-Node2D parents?
	if parent == newParent: return true
	if debugMode: Debug.printDebug(str("reattach(): ", parent, " → ", newParent, " @ camera global position: ", self.global_position), self)

	# Meet the new parent
	self.owner = null
	if self.parent: super.reparent(newParent) # reparent() requires a current parent
	else: newParent.add_child(self)
	self.set_owner(newParent)

	if self.get_parent() != newParent:
		Debug.printWarning(str("reattach() failed to reparent camera to: ", newParent), self)
		return false

	# TODO: Save & restore the position, rotation etc. to avoid a "jump"

	self.align()
	self.reset_smoothing()
	self.reset_physics_interpolation()
	self.force_update_scroll()

	parent = self.get_parent() as Node2D
	if debugMode: Debug.printDebug(str("New camera position: ", self.position, ", global: ", self.global_position), self)
	return true

#endregion


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList.cameraBoundary	= boundary.position if boundary else Vector2.ZERO
	Debug.watchList.cameraLeft		= limit_left
	Debug.watchList.cameraRight		= limit_right
	Debug.watchList.cameraTop		= limit_top
	Debug.watchList.cameraBottom	= limit_bottom
