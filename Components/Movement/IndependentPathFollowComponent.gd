## Moves the parent entity along a [Path2D] WITHOUT using a [PathFollow2D]. This allows multiple entities to have different positions (progress offsets) on the same path.
## NOTE: Sets the parent entity's position DIRECTLY; does NOT use "physics" such as [member CharacterBody2D.velocity].
## NOTE: To use a [PathFollow2D], see the [PathFollowComponent].
## Requirements: The [Path2D] must have a [Curve2D]. Enable "Editable Children" to modify this component's child path node.
## @experimental

class_name IndependentPathFollowComponent
extends Component

# TBD: A better name?


#region Parameters

## The path to follow. If omitted, then this component's [Path2D] child node is used, otherwise the Entity's parent node is used if that is a [Path2D].
@export var path: Path2D

@export_range(-2000, 2000, 10) var speed: float = 100

## If `true` (default), the entity is snapped to the nearest point on the path, closest to the entity's position at the time this component is ready.
## If `false`, then the entity is moved along the path at an OFFSET relative to the entity's starting position.
@export var shouldSnapEntityToPath: bool = true

@export var shouldRotate: bool = false
@export var shouldCubicInterpolate: bool = false ## PERFORMANCE: Cubic interpolation follows curves better, but linear is faster.

@export var isEnabled: bool = true

#endregion


#region Dependencies
var curve: Curve2D
var progress: float
#endregion


#region Signals
signal didCompletePath ## Emitted when a circuit is completed around the [Path2D]'s [Curve2D].
#endregion


#region Initialization

func _ready() -> void:
	setDependencies()

	if self.isEnabled and self.shouldSnapEntityToPath and curve:
		snapEntityToCurve()


func setDependencies() -> bool:

	# If the path is missing, try the parent entity's parent

	if not path:

		var parentEntityParent: Node = parentEntity.get_parent()

		if is_instance_of(parentEntityParent, Path2D):
			self.path = parentEntityParent as Path2D
			if not path: printWarning("Cannot find a Path2D!")
		else:
			printWarning(str("parentEntity's parent is not a Path2D: ", parentEntityParent))
			return false

	if debugMode: printDebug(str("path → ", self.path))

	# Get the Curve2D of the Path2D

	self.curve = path.curve

	if self.curve:
		if curve.point_count <= 0 or is_zero_approx(curve.get_baked_length()):
			printWarning(str("curve has no length: ", curve))
		elif debugMode:
			printDebug(str("curve: ", self.curve, " length: ", curve.get_baked_length()))
		return true # Return `true` even if the curve is zero, because all the dependencies have been set.
	else:
		printWarning(str("Path2D does not have a Curve2D: ", path))
		return false

#endregion


#region Repositioning

## Snaps the entity's position to the nearest point on the path, closest to the entity's current position.
## The [member progress] is also set according to the snapped position.
## Respects the [member shouldRotate] & [member shouldCubicInterpolate] flags.
## Returns: The new snapped position.
func snapEntityToCurve() -> Vector2:
	## TBD: Make sure we account for all transformations in the parent tree

	# Get the entity's position in the Path's space
	# NOTE: The Curve2D's position is in the Path2D's space

	var entityPositionInPathSpace: Vector2 = path.to_local(parentEntity.global_position)

	# Get the closest position on the Curve2D
	var snappedOffset:   float = curve.get_closest_offset(entityPositionInPathSpace)
	var snappedPosition: Vector2

	if self.shouldRotate: # Do we also need to rotate?
		var bakedTransform: Transform2D = curve.sample_baked_with_rotation(snappedOffset, self.shouldCubicInterpolate)
		snappedPosition = bakedTransform.get_origin()
		self.parentEntity.rotation = bakedTransform.get_rotation()
	else:
		snappedPosition = curve.sample_baked(snappedOffset, self.shouldCubicInterpolate)

	# Set the progress along the curve to match the snapped position
	self.progress = snappedOffset

	# Convert the snapped position to the global space
	snappedPosition = path.to_global(snappedPosition)

	# Move the entity
	self.parentEntity.global_position = snappedPosition

	if debugMode: printDebug(str("snapEntityToCurve() entityPositionInPathSpace: ", entityPositionInPathSpace, " → ", snappedPosition, ", snappedOffset: ", snappedOffset))

	return snappedPosition


func _physics_process(delta: float) -> void:
	if not isEnabled or not curve: return

	# TODO: var previousProgressRatio: float = self.progressRatio # Remember this in case the ratio wraps around after a complete circuit.

	# Don't progress further if we are already at the end
	# TODO: if not self.shouldLoop and (is_equal_approx(previousProgressRatio, 1.0) or previousProgressRatio > 1.0): return

	self.progress += self.speed * delta
	setPosition()

	# TODO: var currentProgressRatio: float = self.progressRatio

	# if (is_equal_approx(currentProgressRatio, 1.0) or currentProgressRatio > 1.0) \
	# or (previousProgressRatio >= 0.9 and currentProgressRatio <= 0.1): # Did we wrap around after completing a circuit? TBD: A more reliable way of detectng a full lap? :)
	# 	printDebug("didCompletePath")
	# 	self.didCompletePath.emit()


func setPosition() -> Vector2:
	if not isEnabled or not path or not curve: return self.parentEntity.position

	var newPositionInPathSpace: Vector2

	if self.shouldRotate: # Do we also need to rotate?
		var bakedTransform: Transform2D = curve.sample_baked_with_rotation(self.progress, self.shouldCubicInterpolate)
		newPositionInPathSpace = bakedTransform.get_origin()
		self.parentEntity.rotation = bakedTransform.get_rotation()
	else:
		newPositionInPathSpace = curve.sample_baked(self.progress, self.shouldCubicInterpolate)

	# Convert the position from the Path2D's space to the global space
	self.parentEntity.global_position = path.to_global(newPositionInPathSpace)

	return self.parentEntity.position

#endregion
