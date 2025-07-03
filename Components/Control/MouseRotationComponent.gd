## Rotates the parent [Entity] OR an specified [Node2D] to face towards the mouse pointer.
## TIP: May be used to aim a [GunComponent] etc.
## ALERT: Mutually exclusive with [TurningControlComponent] etc. Add an [InputComponent] to resolve conflicts with joystick or keyboard turning input.

class_name MouseRotationComponent
extends Component # DESIGN: Not [InputDependentComponentBase] because [InputComponent] is optional

# BUG: Custom mouse cursor disappears after mouse moves (macOS?)


#region Parameters

## Override this to rotate a different node instead of the parent [Entity], such as a [GunComponent].
@export var nodeToRotate: Node2D = null

@export_range(0.1, 20, 0.1) var rotationSpeed: float = 5.0

@export var shouldRotateInstantly: bool = false

@export var targetingCursor: Texture2D

@export var isEnabled: bool = true:
	set(newValue):
		isEnabled = newValue # Don't bother checking for a change
		self.set_physics_process(isEnabled) # PERFORMANCE: Set once instead of every frame
		setMouseCursor(isEnabled)

#endregion


#region State

@onready var inputComponent: InputComponent = parentEntity.findFirstComponentSubclass(InputComponent) # Include subclasses to allow AI etc. Optional dependency; only for resolving conflicts with [TurningControlComponent]

## The [member Node.global_rotation] in the previous frame.
var previousRotation:  float

## TIP: May be used by other components.
var didRotateThisFrame: bool

#endregion


func _ready() -> void:
	if not nodeToRotate:
		nodeToRotate = self.parentEntity

	self.set_physics_process(isEnabled) # Apply setter because Godot doesn't on initialization
	setMouseCursor()

	if inputComponent:
		Tools.connectSignal(inputComponent.didToggleMouseSuppression, self.onInputComponent_didToggleMouseSuppression)


func setMouseCursor(useTargetingCursor: bool = self.isEnabled) -> void:
	# TODO: Set hotspot to center.
	if useTargetingCursor: Input.set_custom_mouse_cursor(targetingCursor, Input.CursorShape.CURSOR_CROSS)
	else: Input.set_custom_mouse_cursor(null, Input.CursorShape.CURSOR_ARROW)


func onInputComponent_didToggleMouseSuppression(shouldSuppressMouse: bool) -> void:
	# Suppress the turning control if we also have a TurningControlComponent and there was a `turn` event.
	if self.isEnabled and shouldSuppressMouse:
		if debugMode: printDebug("Aim or Turn input received. Disabling MouseRotationComponent so TurningControlComponent etc. can be used.")
		self.isEnabled = false
		GlobalUI.createTemporaryLabel("Mouse aiming off. Click to reenable")

	elif not self.isEnabled and not shouldSuppressMouse:
		if debugMode: printDebug("Mouse button pressed. Re-enabling MouseRotationComponent. TurningControlComponent etc. may not work.")
		self.isEnabled = true
		GlobalUI.createTemporaryLabel("Mouse aiming on. Joystick aiming off")


func _physics_process(delta: float) -> void: # CHECK: _physics_process() instead of _process() because any movement may interact with physics, right?
	# Keep track of any actual changes in position & rotation, for any other components to monitor.

	# TBD: Where to `get_global_mouse_position()` from? The parentEntity or nodeToRotate?
	# NOTICE: Can't use `self.get_global_mouse_position()` because Component is not a CanvasItem :(
	# `DisplayServer.mouse_get_position()` doesn't work well either.

	didRotateThisFrame = false
	previousRotation   = nodeToRotate.global_rotation

	var mousePosition: Vector2 = nodeToRotate.get_global_mouse_position()

	# Rotate instantly or gradually?

	if shouldRotateInstantly:
		nodeToRotate.look_at(mousePosition)
	else:
		var nodePosition:	Vector2 = nodeToRotate.global_position
		var rotateFrom:		float   = nodeToRotate.global_rotation
		var rotateTo: 		float   = nodePosition.angle_to_point(mousePosition)

		nodeToRotate.global_rotation = rotate_toward(rotateFrom, rotateTo, rotationSpeed * delta)

		if debugMode:
			Debug.watchList.rotateFrom	= rotateFrom
			Debug.watchList.rotateTo	= rotateTo

	# Update flags

	if not is_equal_approx(nodeToRotate.global_rotation, previousRotation):
		didRotateThisFrame = true

	if debugMode: showDebugInfo()


func showDebugInfo() -> void:
	# if not debugMode: return # Checked above
	Debug.addComponentWatchList(self, {
		nodeRotation		= nodeToRotate.rotation,
		localMousePosition	= nodeToRotate.get_local_mouse_position(),
		globalMousePosition	= nodeToRotate.get_global_mouse_position(),
		didRotate			= didRotateThisFrame,
		})
