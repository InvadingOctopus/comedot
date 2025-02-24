## Creates copies of the specified scene at random positions within the [Area2D].
## "Paints" the area from the top-left corner and jumps a random distance within a specified range between each nody copy.
## Currently only optimized for rectangular area shapes.

class_name PopulateArea
extends Area2D

# TODO: A better implementation! Use nosie generation?
# TODO: Avoid existing nodes

#region Parameters

@export var sceneToCopy: PackedScene

@export_range(0, 100, 1) var numberOfCopies: int = 10

## A number will be appeneded to the end of this string.
@export var namePrefix: String = "Clone"

@export_group("Positioning")

## The position of the first node, offset from the top-left corner (0,0) of the area.
## The horizontal X component of the offset is also applied to the first node in each "row".
@export var initialOffset: Vector2 = Vector2.ZERO

## The fixed horizontal distance between each copy.
@export_range(8.0, 256.0, 2.0) var horizontalSpacing: float = 32.0

## The fixed vertical distance between each copy.
@export_range(8.0, 256.0, 2.0) var verticalSpacing: float = 32.0

## The minimum offset or "jitter" to apply to each node copies, in relation to its base initial position as defined by the spacing parameters.
@export var minimumVariation: Vector2 = Vector2(8.0, 8.0)

## The maximum offset or "jitter" to apply to each node copies, in relation to its base initial position as defined by the spacing parameters.
@export var maximumVariation: Vector2 = Vector2(64.0, 64.0)

## If `true`, repositions all copies to fit inside the bounds of the area's shape,
## even if the variation parameters make them fall outside the bounds.
@export var shouldClampToShapeBounds: bool = true

@export_group("Parent")

## The parent node to add the new spawns to. If `null`, the spawns will be added as children of this area.
@export var parentOverride: Node2D

## An optional group to add the spawned nodes to.
@export var addToGroup: StringName

## Use for non-rectangular areas. If `true`, each randomly generated position is tested to ensure that it is inside the shape.
## This may be a slower process than choosing a random position within a simple rectangle.
# @export var shouldVerifyWithinArea := false # TODO: Cannot check if a point is within an area :( [as of 4.3 Dev 3]

@export var debugMode: bool = false

#endregion


#region Signals
# signal ?
#endregion


#region State

@onready var shapeNode: CollisionShape2D = %PopulateAreaShape

## The rectangle bounds of the area, updated during populate()
## Keeps the area dimensions updated instead of only at _ready(), and improves performance by saving it outside createNewCopy() calls.
var shapeBounds: Rect2

## The position of the previously created node copy to keep track of for the purposes of distances between copies.
# INFO: Why save the position instead of the node? Because then the randomized and/or clamped position will be used to space the next copy, ruining the intended pattern.
# PREVIOUS: BUG: Why save the node instead of just a [Vector2] position? Saving the node will be useful if its position changes in validateNewNode()
var previousUnmodifiedPosition: Vector2

var previousCopy: Node2D

var totalCopiesCreated: int

#endregion


func _ready() -> void:
	populate()


func populate() -> void:

	if not sceneToCopy:
		Debug.printError("No sceneToCopy", self)
		return

	var sceneResource := load(sceneToCopy.resource_path)
	var parent: Node2D = parentOverride if parentOverride else self

	self.shapeBounds = Tools.getShapeBoundsInArea(self)

	# NOTE: A position of (0,0) may be top-left in the [Area2D] but at center of the [CollisionShape2D]'s shape.
	# So we have to adjust the first copy's position so that (0,0) is at the top-left of the SHAPE.

	initialOffset += shapeBounds.position # NOTE: But if this is done in createNewCopy() then it will be cumulatively reapplied to each copy!

	if debugMode:
		Debug.printDebug(str("shapeBounds: ", shapeBounds, \
			"\ninitialOffset: ", initialOffset, \
			"\ninitialOffset: ", initialOffset))

	for c in numberOfCopies:
		createNewCopy(sceneResource, parent)


func createNewCopy(sceneResource: Resource, parent: Node2D = self) -> Node2D:
	var newCopy: Node2D = sceneResource.instantiate()

	newCopy.name = str(namePrefix, totalCopiesCreated)

	# Set the position of the new copy,
	# by "painting" the area left-to-right, starting from the top-left corner,
	# and going top-to-bottom after each "row",
	# maintaining the specified spacing between copies.

	# First, is this the first copy?
	# var isFirstNode: bool = totalCopiesCreated <= 0

	if debugMode: Debug.printDebug(str("createNewCopy(): totalCopiesCreated: ", totalCopiesCreated))

	if totalCopiesCreated <= 0:
		previousUnmodifiedPosition = Vector2.ZERO
		newCopy.position = initialOffset
		if debugMode: Debug.printDebug(str("Initial: newCopy.position: ", initialOffset))
	else:
		# If not the first copy, get the previous copy's position.
		newCopy.position = previousUnmodifiedPosition # Copy the position so that we get both X & Y before applying adjustments.
		if debugMode: Debug.printDebug(str("previousPosition: ", previousUnmodifiedPosition))

		# Apply horizontal spacing between the previous copy and the next copy
		newCopy.position.x += horizontalSpacing
		if debugMode: Debug.printDebug(str("Spacing: newCopy.position: ", newCopy.position))

		# If we exceeded the area's width, then go down a "row"

		if newCopy.position.x > self.shapeBounds.end.x:
			if debugMode: Debug.printDebug("newCopy.position.x > shapeBounds.end.x")
			newCopy.position.x = initialOffset.x
			# Reset the horizontal position to line up with the initial offset
			if debugMode: Debug.printDebug(str("New Row X Reset: newCopy.position: ", newCopy.position))
			newCopy.position.y += verticalSpacing
			if debugMode: Debug.printDebug(str("New Row Y Spacing: newCopy.position: ", newCopy.position))

	# Store the final position before any randomization or clamping,
	# so the next copy can be spaced according to the expected grid pattern.

	previousUnmodifiedPosition = newCopy.position
	if debugMode: Debug.printDebug(str("previousUnmodifiedPosition: ", previousUnmodifiedPosition))

	# Apply the random "jitter" or "jiggle" offset to each copy

	var randomX: float = randf_range(minimumVariation.x, maximumVariation.x)
	var randomY: float = randf_range(minimumVariation.y, maximumVariation.y)
	if debugMode: Debug.printDebug(str("Random Variation: ", randomX, ", ", randomY))

	newCopy.position.x += randomX
	newCopy.position.y += randomY
	if debugMode: Debug.printDebug(str("Random Variation: newCopy.position: ", newCopy.position))

	# Clamp the copy within the shape's bounds, if that option is chosen.

	if shouldClampToShapeBounds:
		newCopy.position.x = clampf(newCopy.position.x, self.shapeBounds.position.x, self.shapeBounds.end.x)
		newCopy.position.y = clampf(newCopy.position.y, self.shapeBounds.position.y, self.shapeBounds.end.y)
		if debugMode: Debug.printDebug(str("Clamp: newCopy.position: ", newCopy.position))

	# Convert the copy's position to the parent's space.
	# TBD: Verify

	#if parent != self:
		#newCopy.global_position = self.to_global(newCopy.position)

	# Let the game-specific subclasses of [PopulateArea], if any, customize the new copies.

	if validateNewNode(newCopy, parent):

		if not addToGroup.is_empty():
			newCopy.add_to_group(addToGroup, true)

		parent.add_child(newCopy)
		newCopy.owner = parent # INFO: Necessary for persistence to a [PackedScene] for save/load.
		#didCopy.emit(newCopy, parent)
		previousCopy = newCopy
		totalCopiesCreated += 1
		if debugMode: Debug.printDebug(str("totalCopiesCreated: ", totalCopiesCreated))

		return newCopy
	else:
		return null


## Deletes all the child nodes which match the [member sceneToCopy]
## and resets the [member totalCopiesCreated] counter.
func clearAllNodes() -> void:
	var sceneResource := load(sceneToCopy.resource_path)
	# TBD: Do we need an instance to compare against?

	for child in self.get_children():
		if is_instance_of(child, sceneResource):
			child.queue_free()
			totalCopiesCreated -= 1
			if totalCopiesCreated < 0:
				Debug.printWarning("clearAllNodes(): totalCopiesCreated went < 0: " + str(totalCopiesCreated), self)

	totalCopiesCreated = 0


## A method for subclasses to override. Prepares newly spawned node with further game-specific logic.
## May suppress the creation of a newly spawned node by checking additional conditions and returning `false`.
@warning_ignore("unused_parameter")
func validateNewNode(newCopy: Node2D, parent: Node2D) -> bool:
	return true
