## Rotates the parent [Entity] OR an specified [Node2D] to face towards the mouse pointer.
## TIP: May be used to aim a [GunComponent] etc.
## NOTE: Mutually exclusive with [TurningControlComponent]: Set [member shouldDisableOnTurningInput] to disable this component when the player inputs a [constant GlobalInput.Actions.turnLeft] or [GlobalInput.Actions.turnRight]. To reenable, press any mouse button.

class_name MouseRotationComponent
extends Component

# BUG: Custom mouse cursor disappears after mouse moves (macOS?)


#region Parameters

## Override this to rotate a different node instead of the parent [Entity], such as a [GunComponent].
@export var nodeToRotate: Node2D = null

@export_range(0.1, 20, 0.1) var rotationSpeed: float = 5.0

@export var shouldRotateInstantly: bool = false

@export var targetingCursor: Texture2D

## If `true`, this component is disabled when a [constant GlobalInput.Actions.turnLeft] or [GlobalInput.Actions.turnRight] is received, and reenabled when any mouse button is pressed.
## This allows other components such as [TurningControlComponent] to function, supporting mouse & gamepad control on the same entity, but not at the same time.
@export var shouldDisableOnTurningInput: bool = true

@export var isEnabled: bool = true

#endregion


#region State

## The [member Node.global_rotation] in the previous frame.
var previousRotation: float

## TIP: May be used by other components.
var didRotateThisFrame: bool

var haveTurningControlComponent: bool:
	get: return parentEntity.components.has(&"TurningControlComponent") # TBD: PERFORMANCE: Use hardcoded name or not?

#endregion


func _ready() -> void:
	if not nodeToRotate:
		nodeToRotate = self.parentEntity
	setMouseCursor()


func setMouseCursor(useTargetingCursor: bool = self.isEnabled) -> void:
	# TODO: Set hotspot to center.
	if useTargetingCursor: Input.set_custom_mouse_cursor(targetingCursor, Input.CursorShape.CURSOR_CROSS)
	else: Input.set_custom_mouse_cursor(null, Input.CursorShape.CURSOR_ARROW)


func _input(event: InputEvent) -> void:
	# Suppress the turning control if we also have a TurningControlComponent and there was a `turn` event.
	if shouldDisableOnTurningInput and haveTurningControlComponent:
		if self.isEnabled \
		and (event.is_action(GlobalInput.Actions.turnLeft) or event.is_action(GlobalInput.Actions.turnRight)):
			printDebug("Turn action received. Disabling MouseRotationComponent so TurningControlComponent can be used.")
			GlobalUI.createTemporaryLabel("Mouse aiming off if turning. Click to reenable")
			self.isEnabled = false
			setMouseCursor(false)
		elif not self.isEnabled and Input.get_mouse_button_mask() != 0:
			printDebug("Mouse button pressed. Enabling MouseRotationComponent. TurningControlComponent may not work.")
			self.isEnabled = true
			setMouseCursor(true)


func _physics_process(delta: float) -> void:
	if not isEnabled: return

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
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.nodeRotation		= nodeToRotate.rotation
	Debug.watchList.localMousePosition	= nodeToRotate.get_local_mouse_position()
	Debug.watchList.globalMousePosition	= nodeToRotate.get_global_mouse_position()
	Debug.watchList.didRotate			= didRotateThisFrame
