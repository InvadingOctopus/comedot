## Helper functions to assist with common tasks involving [CollisionObject2D] and [CollisionShape2D]
## In the future, these functions & types may be incorporated into the builtin Godot API as native code or via custom extensions.

class_name CollisionTools
extends GDScript # NOTE: DESIGN: We cannot `extends CollisionObject2D` because we want these functions to be global and also available for [CollisionShape2D] etc., not just for instances of a special subclass.


#region CollisionObject2D

## Returns the [Shape2D] from a [CollisionObject2D]-based node (such as [Area2D] or [CharacterBody2D]) and a given "shape index"
## The [param shapeIndex] is a collision shape child index, such as the `shape_idx` from input/collision callbacks.
## @experimental
static func getCollisionShape(node: CollisionObject2D, shapeIndex: int = 0) -> Shape2D:
	# What is this hell... Dumbdot should have a builtin API for this not uncommon task

	var shapeOwnerID: int = node.shape_find_owner(shapeIndex)
	if  shapeOwnerID < 0: return null

	# UNUSED: PERFORMANCE: No need to check: If a [CollisionObject2D] doesn't have any Shapes, it's a configuration error and should crash.
	# var shapeOwnerShapeCount: int = node.shape_owner_get_shape_count(shapeOwnerID)
	# if  shapeOwnerShapeCount < 1: return null

	# INFO: A "shape index" is "global" i.e. not unique to a "shape owner", and a "shape ID" is LOCAL to a "shape owner"
	# NOTE: In case the [CollisionObject2D] has multiple Shapes, find the Shape that matches `shapeIndex`
	for shapeID: int in node.shape_owner_get_shape_count(shapeOwnerID):
		if node.shape_owner_get_shape_index(shapeOwnerID, shapeID) == shapeIndex:
			return node.shape_owner_get_shape(shapeOwnerID, shapeID)
	# else
	return null


## Returns a [Rect2] representing the boundary/extents of the FIRST [CollisionShape2D] child of a [CollisionObject2D] (e.g. [Area2D] or [CharacterBody2D])
## On failure: Returns a 0-sized [Rect2]
## NOTE: The rectangle is in the LOCAL coordinates of the [CollisionObject2D]
## Non-rectangular shapes may not have exact collision geometry; Best suited for areas with a single [RectangleShape2D], in which case the [Shape2D]'s anchor/origin will be at the center of the returned rectangle.
static func getFirstShapeBounds(node: CollisionObject2D) -> Rect2:
	# Find a CollisionShape2D child
	var shapeNode: CollisionShape2D
	if  node.get_child_count() > 0:
		shapeNode = node.get_child(0) as CollisionShape2D # Try the fast way first: Most [Area2D]s will just have 1 child, the [CollisionShape2D]
		if not shapeNode: shapeNode = NodeTools.findFirstChildOfType(node, CollisionShape2D)

	if not shapeNode:
		Debug.printWarning("CollisionTools.getFirstShapeBounds(): Cannot find a CollisionShape2D child", node)
		return RectTools.rect2Zero # On failure, return a rectangle with 0 size/area

	return getShapeBounds(shapeNode)


## Returns a [Rect2] representing the combined rectangular boundaries/extents of ALL the [CollisionShape2D] children of a [CollisionObject2D] (e.g. [Area2D] or [CharacterBody2D]).
## Shapes that are [member CollisionShape2D.disabled] or nested or over the [param maximumShapeCount] are skipped.
## To get the bounds of the first valid shape only, set [param maximumShapeCount] to 1.
## NOTE: The rectangle is in the LOCAL coordinates of the [CollisionObject2D]. To convert to GLOBAL coordinates, use [method CollisionTools.getShapeGlobalBounds].
## Uses each [Shape2D]'s enclosing [Rect2], so non-rectangular shapes are represented by their rectangular bounds.
## Returns: A [Rect2] of all the merged bounds. On failure: a [Rect2] size 0
static func getAllShapeBounds(node: CollisionObject2D, maximumShapeCount: int = 100) -> Rect2:
	# TBD: PERFORMANCE: Option to cache results?
	# HACK: Sigh @ Godot for making this so hard...

	# INFO: PLAN: Overview: A [CollisionObject2D] has [CollisionShape2D] child [Node]s, which in turn have [Shape2D] [Resource]s.
	# The [Shape2D]'s rectangle is local to that resource, so each rectangle is converted into the [CollisionObject2D]'s coordinates before merging.

	if node.get_child_count() < 1: return RectTools.rect2Zero # On failure, return a rectangle with 0 size/area

	# Get all CollisionShape2D children

	var combinedShapeBounds: Rect2
	var shapesAdded:		 int = 0
	var shapeBounds:		 Rect2

	for shapeNode in node.get_children(): # TBD: PERFORMANCE: Use Node.find_children()?
		if shapeNode is CollisionShape2D and not shapeNode.disabled:
			if not shapeNode.shape:
				Debug.printWarning("CollisionTools.getAllShapeBounds(): CollisionShape2D missing a valid Shape2D", shapeNode)
				continue

			shapeBounds = getShapeBounds(shapeNode)

			if shapesAdded < 1: combinedShapeBounds = shapeBounds # Is it the first shape?
			else: combinedShapeBounds = combinedShapeBounds.merge(shapeBounds)

			# DEBUG: Debug.printDebug(str("shape: ", shapeNode.shape, ", rect: ", shapeNode.shape.get_rect(), ", bounds in node: ", shapeBounds, ", combinedShapeBounds: ", combinedShapeBounds), node)
			shapesAdded += 1
			if shapesAdded >= maximumShapeCount: break # TBD: Log if too many shapes?

	if shapesAdded < 1:
		Debug.printWarning("CollisionTools.getAllShapeBounds(): Cannot find a valid CollisionShape2D child", node)
		return Rect2(Vector2.ZERO, Vector2.ZERO) # On failure, return an invalid zero-sized rectangle
	else:
		# DEBUG: Debug.printTrace([combinedShapeBounds, node.get_child_count(), shapesAdded], node)
		return combinedShapeBounds


## Calls [method CollisionTools.getAllShapeBounds] and returns the [Rect2] representing the combined rectangular boundaries/extents of ALL the [CollisionShape2D] children of a [CollisionObject2D] (e.g. [Area2D] or [CharacterBody2D]), converted to GLOBAL coordinates.
## Useful for comparing the [Area2D]s etc. of 2 separate nodes/entities.
## On failure: Returns a 0-sized [Rect2] if no valid shape bounds are found.
static func getShapeGlobalBounds(node: CollisionObject2D) -> Rect2:
	# TBD: PERFORMANCE: Option to cache results?
	var localBounds: Rect2 = getAllShapeBounds(node)
	if not localBounds.has_area(): return RectTools.rect2Zero
	return node.global_transform * localBounds.abs() # Apply all transforms including rotation/skew/etc.

#endregion


#region CollisionShape2D

## Returns a [Rect2] representing the boundary/extents of a [CollisionShape2D]'s [Shape2D] in the local coordinates of the [CollisionShape2D]'s parent.
## On failure: Returns a 0-sized [Rect2]
## ALERT: Non-rectangular shapes may not have exact collision geometry.
static func getShapeBounds(shapeNode: CollisionShape2D) -> Rect2:
	if shapeNode and shapeNode.shape:
		return shapeNode.transform * shapeNode.shape.get_rect().abs() # Apply all transforms including rotation/skew/etc.
	else:
		Debug.printWarning("CollisionTools.getShapeBounds(): CollisionShape2D missing a valid Shape2D", shapeNode)
		return RectTools.rect2Zero

#endregion
