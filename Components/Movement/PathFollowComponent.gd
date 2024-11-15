## Increments the [member PathFollow2D.progress] each frame. Respects the rotation & interpolation flags as set on the [PathFollow2D] node.
## NOTE: Sets the parent entity's position DIRECTLY; does NOT use "physics" such as [member CharacterBody2D.velocity].
## Requirements: The parent Entity must be a child node of a [PathFollow2D] which must itself be a child of a [Path2D].

class_name PathFollowComponent
extends Component


#region Parameters

@export_range(-2000, 2000, 10) var speed: float = 100

## If `true` (default), the entity is snapped to the nearest point on the path, closest to the entity's position at the time this component is ready.
## The [member PathFollow2D.progress] is also set according to the snapped position, and the rest of the movement resumes from there.
## If `false`, then the entity is moved along the path at an OFFSET relative to the entity's starting position.
@export var shouldSnapEntityToPath: bool = true

## If `true` (default), the [member PathFollow2D.progress] is set to 0 when this component is [method _ready] and on [method Component.unregisterParent].
@export var shouldResetProgress: bool = true

@export var isEnabled: bool = true

#endregion


#region Dependencies
var path:  Path2D
var curve: Curve2D
var pathFollower: PathFollow2D
#endregion


#region Signals
signal didCompletePath ## Emitted when the [PathFollow2D] completes a circuit around the [Path2D]'s [Curve2D].
#endregion


#region Initialization

func _ready() -> void:
	setDependencies()

	if self.shouldResetProgress and pathFollower:
		pathFollower.progress = 0

	if self.shouldSnapEntityToPath and curve:
		snapEntityToCurve()


func setDependencies() -> bool:

	# Get the PathFollow2D parent of this component's parent Entity

	var parentEntityParent: Node = parentEntity.get_parent()

	if is_instance_of(parentEntityParent, PathFollow2D):
		self.pathFollower = parentEntityParent as PathFollow2D
		if not pathFollower: printWarning("Cannot set pathFollower!")
	else:
		printWarning(str("parentEntity's parent is not a PathFollow2D: ", parentEntityParent))
		return false

	# Get the Path2D parent of the PathFollow2D

	var pathFollowerParent: Node = pathFollower.get_parent()

	if is_instance_of(pathFollowerParent, Path2D):
		self.path = pathFollowerParent as Path2D
		if not path: printWarning("Cannot set path!")
	else:
		printWarning(str("pathFollower's parent is not a Path2D: ", pathFollowerParent))
		return false

	# Get the Curve2D of the Path2D

	self.curve = path.curve

	if curve:
		return true
	else:
		printWarning(str("Path2D does not have a Curve2D: ", path))
		return false

#endregion


#region Repositioning

## Snaps the entity's position to the nearest point on the path, closest to the entity's current position.
## The [member PathFollow2D.progress] is also set according to the snapped position.
## Respects the rotation & interpolation flags as set on the [PathFollow2D] node.
## Returns: The new snapped position.
func snapEntityToCurve() -> Vector2:
	## TBD: Make sure we account for all transformations in the parent tree

	# Get the entity's position in the Path's space
	# NOTE: The PathFollow2D's position is in the Path2D's space

	var entityPositionInPathSpace: Vector2 = path.to_local(parentEntity.global_position)

	# Get the closest position on the Curve2D
	var snappedOffset:   float = curve.get_closest_offset(entityPositionInPathSpace)
	var snappedPosition: Vector2

	if pathFollower.rotates: # Do we also need to rotate?
		var bakedTransform: Transform2D = curve.sample_baked_with_rotation(snappedOffset, pathFollower.cubic_interp)
		snappedPosition = bakedTransform.get_origin()
		self.parentEntity.rotation = bakedTransform.get_rotation()
	else:
		snappedPosition = curve.sample_baked(snappedOffset, pathFollower.cubic_interp)

	# Set the PathFollow2D's progress to match the snapped position
	pathFollower.progress = snappedOffset

	# Convert the snapped position to the global space
	snappedPosition = path.to_global(snappedPosition)

	# Move the entity
	self.parentEntity.global_position = snappedPosition

	if shouldShowDebugInfo: printDebug(str("snapEntityToCurve() entityPositionInPathSpace: ", entityPositionInPathSpace, " → ", snappedPosition, ", snappedOffset: ", snappedOffset))

	return snappedPosition


func _physics_process(delta: float) -> void:
	if not isEnabled or not pathFollower: return

	var previousProgressRatio: float = pathFollower.progress_ratio # Remember this in case the ratio wraps around after a complete circuit.

	# Don't progress further if we are already at the end
	if not pathFollower.loop and (is_equal_approx(previousProgressRatio, 1.0) or previousProgressRatio > 1.0): return

	pathFollower.progress += self.speed * delta

	var currentProgressRatio: float = pathFollower.progress_ratio

	if (is_equal_approx(currentProgressRatio, 1.0) or currentProgressRatio > 1.0) \
	or (previousProgressRatio >= 0.9 and currentProgressRatio <= 0.1): # Did we wrap around after completing a circuit? TBD: A more reliable way of detectng a full lap? :)
		printDebug("didCompletePath")
		self.didCompletePath.emit()


func unregisterParent() -> void:
	if self.shouldResetProgress and pathFollower: pathFollower.progress = 0
	super.unregisterParent()

#endregion
