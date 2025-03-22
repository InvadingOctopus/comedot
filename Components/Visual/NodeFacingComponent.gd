## Rotates the parent [Entity] OR another specified [Node2D] to face towards another node.
## TIP: May be used to aim a [GunComponent] towards a targetting cursor etc.
## NOTE: Mutually exclusive with [TurningControlComponent]: 
## Set [member shouldDisableOnTurningInput] to disable this component when the player inputs a [constant GlobalInput.Actions.turnLeft] or [GlobalInput.Actions.turnRight].
## Will be reenabled after a [Timer] duration.

class_name NodeFacingComponent
extends Component


#region Parameters

## Override this to rotate a different node instead of the parent [Entity], such as a [GunComponent].
@export var nodeToRotate: Node2D

## The node to face towards, such as a targeting cursor.
@export var targetToFace: Node2D

@export_range(0.1, 20, 0.1) var rotationSpeed: float = 5.0

@export var shouldRotateInstantly: bool = false

## If `true`, this component is disabled when a [constant GlobalInput.Actions.turnLeft] or [GlobalInput.Actions.turnRight] is received, and reenabled after the [member reenablingTimer] duration.
## This allows other components such as [TurningControlComponent] to function on the same entity, but not at the same time as this [NodeFacingComponent].
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

@onready var reenablingTimer: Timer = $ReenablingTimer

#endregion


func _ready() -> void:
	if not nodeToRotate: nodeToRotate = self.parentEntity
	if not targetToFace: printDebug("No targetToFace") # Do not clutter the log with warnings, in case the target is set after _ready(), e.g. spawning monsters set to target the player.


func _input(event: InputEvent) -> void:
	# Suppress the turning control if we also have a TurningControlComponent and there was a `turn` event.
	if shouldDisableOnTurningInput and haveTurningControlComponent:
		if self.isEnabled \
		and (event.is_action(GlobalInput.Actions.turnLeft) or event.is_action(GlobalInput.Actions.turnRight)):
			printDebug("Turn action received. Disabling NodeFacingComponent so TurningControlComponent can be used.")
			# TBD: GlobalUI.createTemporaryLabel("NodeFacingComponent off if turning. Click to reenable")
			self.isEnabled = false
			reenablingTimer.start()


func _physics_process(delta: float) -> void: # TBD: Should this be `_process()` or `_physics_process()`?
	if not isEnabled or not targetToFace: return

	# Keep track of any actual changes in position & rotation, for any other components to monitor.

	didRotateThisFrame = false
	previousRotation   = nodeToRotate.global_rotation

	var targetPosition: Vector2 = targetToFace.global_position

	# Rotate instantly or gradually?

	if shouldRotateInstantly:
		nodeToRotate.look_at(targetPosition)
	else:
		var nodePosition:	Vector2 = nodeToRotate.global_position
		var rotateFrom:		float   = nodeToRotate.global_rotation
		var rotateTo: 		float   = nodePosition.angle_to_point(targetPosition)

		nodeToRotate.global_rotation = rotate_toward(rotateFrom, rotateTo, rotationSpeed * delta)

		if debugMode:
			Debug.watchList.rotateFrom	= rotateFrom
			Debug.watchList.rotateTo	= rotateTo

	# Update flags

	if not is_equal_approx(nodeToRotate.global_rotation, previousRotation):
		didRotateThisFrame = true

	if debugMode: showDebugInfo()


func onReenablingTimer_timeout() -> void:
	printDebug("Re-enabling NodeFacingComponent. TurningControlComponent may not work.")
	self.isEnabled = true


func showDebugInfo() -> void:
	# if not debugMode: return # Checked above
	Debug.watchList[str("\n —", parentEntity.name, ".", self.name)] = ""
	Debug.watchList.nodeRotation		= nodeToRotate.rotation
	Debug.watchList.targetPosition		= targetToFace.position
	Debug.watchList.targetPositionGlobal= targetToFace.global_position
	Debug.watchList.didRotate			= didRotateThisFrame



