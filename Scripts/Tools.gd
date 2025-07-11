## Helper functions for built-in Godot nodes and types to assist with common tasks.
## Most of this is stuff that should be built-in Godot but isn't :')
## and can't be injected into the base types such as Node etc. :(

class_name Tools
extends GDScript



#region Constants

## The cardinal & ordinal directions, each assigned a number representing the associated rotation angle in degrees, with East = 0 and incrementing by 45
enum CompassDirection {
	# DESIGN: Start from East to match the default rotation angle of 0
	# TBD: Should this be in `Tools.gd` or in `Global.gd`? :')
	none		=  -1,
	east		=   0,
	southEast	=  45,
	south		=  90,
	southWest	= 135,
	west		= 180,
	northWest	= 225,
	north		= 270,
	northEast	= 315
	}

const compassDirectionVectors: Dictionary[CompassDirection, Vector2i] = {
	CompassDirection.none:		Vector2i.ZERO,
	CompassDirection.east:		Vector2i.RIGHT,
	CompassDirection.southEast:	Vector2i(+1, +1),
	CompassDirection.south:		Vector2i.DOWN,
	CompassDirection.southWest:	Vector2i(-1, +1),
	CompassDirection.west:		Vector2i.LEFT,
	CompassDirection.northWest:	Vector2i(-1, -1),
	CompassDirection.north:		Vector2i.UP,
	CompassDirection.northEast:	Vector2i(+1, -1)
	}

const compassDirectionOpposites: Dictionary[CompassDirection, CompassDirection] = {
	CompassDirection.none:		CompassDirection.none,
	CompassDirection.east:		CompassDirection.west,
	CompassDirection.southEast:	CompassDirection.northWest,
	CompassDirection.south:		CompassDirection.north,
	CompassDirection.southWest:	CompassDirection.northEast,
	CompassDirection.west:		CompassDirection.east,
	CompassDirection.northWest:	CompassDirection.southEast,
	CompassDirection.north:		CompassDirection.south,
	CompassDirection.northEast:	CompassDirection.southWest,
	}

## A list of unit vectors representing 8 compass directions.
class CompassVectors:
	# TBD: Replace with `compassDirectionVectors[CompassDirection]`?
	const none		:= Vector2i.ZERO
	const east		:= Vector2i.RIGHT
	const southEast	:= Vector2i(+1, +1)
	const south		:= Vector2i.DOWN
	const southWest	:= Vector2i(-1, +1)
	const west		:= Vector2i.LEFT
	const northWest	:= Vector2i(-1, -1)
	const north		:= Vector2i.UP
	const northEast	:= Vector2i(+1, -1)

## A sequence of float numbers from -1.0 to +1.0 stepped by 0.1
## TIP: Use [method Array.pick_random] to pick a random variation from this list for colors etc.
const sequenceNegative1toPositive1stepPoint1: Array[float] = [-1.0, -0.9, -0.8, -0.7, -0.6, -0.5, -0.4, -0.3, -0.2, -0.1, 0, +0.1, +0.2, +0.3, +0.4, +0.5, +0.6, +0.7, +0.8, +0.9, +1.0] # TBD: Better name pleawse :')

#endregion


#region Subclasses

## A set of parameters for [method CanvasItem.draw_line]
class Line: # UNUSED: Until Godot can support custom class @export :')
	var start:	Vector2
	var end:	Vector2
	var color:	Color = Color.WHITE
	var width:	float = -1.0 ## A negative means the line will remain a "2-point primitive" i.e. always be a 1-width line regardless of scaling.

#endregion


#region Scene Management
# See SceneManager.gd
#endregion


#region Script Tools

## Returns a [StringName] with the `class_name` from a [Script] type.
## NOTE: This method is needed because we cannot directly write `SomeTypeName.get_global_name()` :(
func getStringNameFromClass(type: Script) -> StringName:
	return type.get_global_name()


## Connects or reconnects a [Signal] to a [Callable] only if the connection does not already exist, to silence any annoying Godot errors about existing connections (presumably for reference counting).
static func connectSignal(sourceSignal: Signal, targetCallable: Callable, flags: int = 0) -> int:
	if not sourceSignal.is_connected(targetCallable):
		return sourceSignal.connect(targetCallable, flags) # No idea what the return value is for.
	else:
		return 0


## Disconnects a [Signal] from a [Callable] only if the connection actually exists, to silence any annoying Godot errors about missing connections (presumably for reference counting).
static func disconnectSignal(sourceSignal: Signal, targetCallable: Callable) -> void:
	if  sourceSignal.is_connected(targetCallable):
		sourceSignal.disconnect(targetCallable)


## Connects/reconnects OR disconnects a [Signal] from a [Callable] safely, based on the [param reconnect] flag.
## TIP: This saves having to type `if someFlag: connectSignal(…) else: disconnectSignal(…)`
static func toggleSignal(sourceSignal: Signal, targetCallable: Callable, reconnect: bool, flags: int = 0) -> int:
	# TBD: Should `reconnect` be a nullable Variant?
	if reconnect and not sourceSignal.is_connected(targetCallable):
		return sourceSignal.connect(targetCallable, flags) # No idea what the return value is for.
	elif not reconnect and sourceSignal.is_connected(targetCallable):
		sourceSignal.disconnect(targetCallable)
	# else:
	return 0


## Checks whether a script has a function/method with the specified name.
## NOTE: Only checks for the name, NOT the arguments or return type.
## ALERT: Use the EXACT SAME CASE as the method you need to find!
static func findMethodInScript(script: Script, methodName: StringName) -> bool: # TBD: Should it be [StringName]?
	# TODO: A variant or option to check for multiple methods.
	# TODO: Check arguments and return type.
	var methodDictionary: Array[Dictionary] = script.get_script_method_list()
	for method in methodDictionary:
		# DEBUG: Debug.printDebug(str("findMethodInScript() script: ", script, " searching: ", method))
		if method["name"] == methodName: return true
	return false

#endregion


#region Node Management

## Calls [param parent].[method Node.add_child] and sets the [param child].[member Node.owner].
## This is necessary for persistence to a [PackedScene] for save/load.
## NOTE: Also sets the `force_readable_name` parameter, which may slow performance if used frequently.
static func addChildAndSetOwner(child: Node, parent: Node) -> void: # DESIGN: TBD: Should `parent` be the 1st argument or 2nd? All global functions operate on the 1st argument, the parent [Node], but this method's name has "child" as the first word, so the `child` should be the 1st argument, right? :')
	parent.add_child(child, Debug.shouldForceReadableName) # PERFORMANCE: force_readable_name only if debugging
	child.owner = parent


## Adds & returns a child node at the position of another node, and optionally copies the rotation and scale of the [member placementNode].
## Also sets the child's owner to the new parent.
## Example: Using [Marker2D]s as placeholders for objects like doors etc. during procedural map generation from a template.
## NOTE: Also sets the `force_readable_name` parameter, which may slow performance if used frequently.
static func addChildAtNode(child: Node2D, placementNode: Node2D, parent: Node, copyRotation: bool = true, copyScale: bool = true) -> Node2D:
	child.position = placementNode.position
	if copyRotation: child.rotation	= placementNode.rotation
	if copyScale:	 child.scale	= placementNode.scale
	parent.add_child(child, Debug.shouldForceReadableName) # PERFORMANCE: force_readable_name only if debugging
	child.owner = parent
	return child


## Returns the first child of [param parentNode] which matches the specified [param type].
## If [param includeParent] is `true` (default) then the [param parentNode] ITSELF may be returned if it is node of a matching type. This may be useful for [Sprite2D] or [Area2D] etc. nodes with the `Entity.gd` script.
static func findFirstChildOfType(parentNode: Node, childType: Variant, includeParent: bool = true) -> Node:
	if includeParent and is_instance_of(parentNode, childType):
		return parentNode

	var children: Array[Node] = parentNode.get_children()
	for child in children:
		if is_instance_of(child, childType): return child # break
	#else
	return null


## Calls [method Tools.findFirstChildOfType] to return the first child of [param parentNode] which matches ANY of the specified [param types]  (searched in the array order).
## If [param includeParent] is `true` (default) then the [param parentNode] ITSELF is returned AFTER none of the requested types are found.
## This may be useful for choosing certain child nodes of an entity to operate on, like an [AnimatedSprite2D] or [Sprite2D] to animate, otherwise operate on the entity itself.
## PERFORMANCE: Should be the same as multiple calls to [method Tools.findFirstChildOfType] in order of the desired types.
static func findFirstChildOfAnyTypes(parentNode: Node, childTypes: Array[Variant], returnParentIfNoMatches: bool = true) -> Node:
	# TBD: Better name
	# Nodes may be an instance of multiple inherited types, so check each of the requested types.
	# NOTE: Types must be the outer loop, so that when searching for [AnimatedSprite2D, Sprite2D], the first [AnimatedSprite2D] is returned.
	# If child nodes are the outer loop, then a [Sprite2D] might be returned if it is higher in the child tree than the [AnimatedSprite2D].
	for type: Variant in childTypes:
		for child in parentNode.get_children():
			if is_instance_of(child, type): return child # break

	# Return the parent itself AFTER none of the requested types are found.
	# DESIGN: REASON: This may be useful for situations like choosing an [AnimatedSprite2D] or [Sprite2D] otherwise operate on the entity itself.
	return parentNode if returnParentIfNoMatches else null


## Searches up the tree until a matching parent or grandparent is found.
static func findFirstParentOfType(childNode: Node, parentType: Variant) -> Node:
	var parent: Node = childNode.get_parent() # parentOrGrandparent

	# If parent is not the matching type, get the grandparent (parent's parent) and keep searching up the tree, until we run out of parents (null).
	while parent != null and not is_instance_of(parent, parentType): # NOTE: Avoid calling get_parent() on `null`
		parent = parent.get_parent()

	return parent


## Appends a linear/"flattened" list of ALL the child nodes AND their subchildren and so on, recursively, from the specified [param firstNode].
## e.g. `[FirstNode, Child1ofFirstNode, Child1ofChild1ofFirstNode, Child2ofChild1ofFirstNode, Child2ofFirstNode, …]`
## TIP: EXAMPLE USAGE: This may be useful for setting UI focus chains in trees/lists etc.
## @experimental
static func flatMapNodeTree(nodeToIterate: Node, existingList: Array[Node]) -> void:
	# TODO: Better name?
	# TODO: Filtering
	# TODO: This should be a generic function for flattening trees of any type :')
	existingList.append(nodeToIterate)
	for index in nodeToIterate.get_child_count(): # No need to -1 because the end of a range is EXCLUSIVE
		flatMapNodeTree(nodeToIterate.get_child(index), existingList)


## Calls [method Tools.flatMapNodeTree] to return a linear/"flattened" list of ALL the child nodes AND their subchildren, recursively, from the specified [param firstNode].
## @experimental
static func getAllChildrenRecursively(firstNode: Node) -> Array[Node]:
	# TBD: Merge with flatMapNodeTree()?
	var flatList: Array[Node]
	Tools.flatMapNodeTree(firstNode, flatList)
	return flatList


## Replaces a child node with another node at the same index (order), optionally copying the position, rotation and/or scale.
## NOTE: The previous child and its sub-children are NOT deleted by default. To delete a child, set [param freeReplacedChild] or use [method Node.queue_free].
## Returns: `true` if [param childToReplace] was found and replaced.
static func replaceChild(parentNode: Node, childToReplace: Node, newChild: Node, copyPosition: bool = false, copyRotation: bool = false, copyScale: bool = false, freeReplacedChild: bool = false) -> bool:
	if childToReplace.get_parent() != parentNode:
		Debug.printWarning(str("replaceChild() childToReplace.get_parent(): ", childToReplace.get_parent(), " != parentNode: ", parentNode))
		return false

	# Is the new child already in another parent?
	# TODO: Option to remove new child from existing parent
	var newChildCurrentParent: Node = newChild.get_parent()
	if newChildCurrentParent != null and newChildCurrentParent != parentNode:
		Debug.printWarning("replaceChild(): newChild already in another parent: " + str(newChild, " in ", newChildCurrentParent))
		return false

	# Copy properties
	if copyPosition: newChild.position	= childToReplace.position
	if copyRotation: newChild.rotation	= childToReplace.rotation
	if copyScale:	 newChild.scale		= childToReplace.scale

	# Swap the kids
	var previousChildIndex: int = childToReplace.get_index() # The original index
	parentNode.remove_child(childToReplace) # NOTE: Do not use `replace_by()` which transfers all sub-children as well.

	Tools.addChildAndSetOwner(newChild, parentNode) # Ensure persistence
	parentNode.move_child(newChild, previousChildIndex)
	newChild.owner = parentNode # INFO: Necessary for persistence to a [PackedScene] for save/load.

	# Yeet the disowned child?
	if freeReplacedChild: childToReplace.queue_free()

	return true


## Removes the first child of the [param parentNode], if any, and adds the specified [param newChild]. Optionally copies the position, rotation and/or scale.
## NOTE: The new child is added regardless of whether the parent already had a child or not.
## NOTE: The previous child and its sub-children are NOT deleted by default. To delete a child, set [param freeReplacedChild] or use [method Node.queue_free].
static func replaceFirstChild(parentNode: Node, newChild: Node, copyPosition: bool = false, copyRotation: bool = false, copyScale: bool = false, freeReplacedChild: bool = false) -> void:
	var childToReplace: Control = parentNode.findFirstChildControl()
	# Debug.printDebug(str("replaceFirstChildControl(): ", childToReplace, " → ", newChild), parentNode)

	if childToReplace:
		Tools.replaceChild(parentNode, childToReplace, newChild, copyPosition, copyRotation, copyScale, freeReplacedChild)
	else: # If there are no children, just add the new one.
		Tools.addChildAndSetOwner(newChild, parentNode) # Ensure persistence
		newChild.owner = parentNode # For persistence


## Removes each child from the [parameter parent] then calls [method Node.queue_free] on the child.
## Returns: The number of removed children.
static func removeAllChildren(parent: Node) -> int:
	var removalCount: int = 0

	for child in parent.get_children():
		parent.remove_child(child) # TBD: Is this needed? Does NOT delete nodes, unlike queue_free()
		child.queue_free()
		removalCount += 1

	return removalCount


## Moves nodes from one parent to another and returns an array of all children that were successfully reparented.
static func reparentNodes(currentParent: Node, nodesToTransfer: Array[Node], newParent: Node, keepGlobalTransform: bool = true) -> Array[Node]:
	var transferredNodes: Array[Node]
	for node in nodesToTransfer:
		if node.get_parent() == currentParent: # TBD: Is this extra layer of "security" necessary?
			node.reparent(newParent, keepGlobalTransform)
			node.owner = newParent # For persistence etc.
			if node.get_parent() == newParent: # TBD: Is this verification necessary?
				transferredNodes.append(node)
			else:
				Debug.printWarning(str("transferNodes(): ", node, " could not be moved from ", currentParent, " to newParent: ", newParent), node)
				continue
		else:
			Debug.printWarning(str("transferNodes(): ", node, " does not belong to currentParent: ", currentParent), node)
			continue
	return transferredNodes


## Convert a [NodePath] from the `./` form to the absolute representation: `/root/` INCLUDING the property path if any.
static func convertRelativeNodePathToAbsolute(parentNodeToConvertFrom: Node, relativePath: NodePath) -> NodePath:
	var absoluteNodePath: String = parentNodeToConvertFrom.get_node(relativePath).get_path()
	var propertyPath: String = str(":", relativePath.get_concatenated_subnames())
	var absolutePathIncludingProperty: NodePath = NodePath(str(absoluteNodePath, propertyPath))

	# DEBUG:
	#Debug.printLog(str("Tools.convertRelativeNodePathToAbsolute() parentNodeToConvertFrom: ", parentNodeToConvertFrom, \
		#", relativePath: ", relativePath, \
		#", absoluteNodePath: ", absoluteNodePath, \
		#", propertyPath: ", propertyPath))

	return absolutePathIncludingProperty


## Returns a copy of a [Rect2] transformed from a node's local coordinates to the global position.
## TIP: PERFORMANCE: This function may be replaced with `Rect2(rect.position + node.global_position, rect.size)` to avoid an extra call.
## TIP: Combine with the output from [member getShapeBoundsInNode] to get an [Area2D]'s global region.
## WARNING: May not work correctly with rotation, scaling or negative dimensions.
static func convertNodeRectToGlobalCoordinates(node: CanvasItem, rect: Rect2) -> Rect2:
	# TODO: Account for rotation & scaling
	return Rect2(rect.position + node.global_position, rect.size)


## Splits a [NodePath] into an Array of 2 paths where index [0] is the node's path and [1] is the property chain, e.g. `/root:size:x` → [`/root`, `:size:x`]
static func splitPathIntoNodeAndProperty(path: NodePath) -> Array[NodePath]:
	var nodePath: NodePath
	var propertyPath: NodePath

	nodePath = NodePath(str("/" if path.is_absolute() else "", path.get_concatenated_names()))
	propertyPath = NodePath(str(":", path.get_concatenated_subnames()))

	return [nodePath, propertyPath]

#endregion


#region Area & Shape Geometry

static func getRectCorner(rectangle: Rect2, compassDirection: Vector2i) -> Vector2:
	var position:	Vector2 = rectangle.position
	var center:		Vector2 = rectangle.get_center()
	var end:		Vector2 = rectangle.end

	match compassDirection:
		CompassVectors.northWest:	return Vector2(position.x, position.y)
		CompassVectors.north:		return Vector2(center.x, position.y)
		CompassVectors.northEast:	return Vector2(end.x, position.y)
		CompassVectors.east:		return Vector2(end.x, center.y)
		CompassVectors.southEast:	return Vector2(end.x, end.y)
		CompassVectors.south:		return Vector2(center.x, end.y)
		CompassVectors.southWest:	return Vector2(position.x, end.y)
		CompassVectors.west:		return Vector2(position.x, center.y)

		_: return Vector2.ZERO


## Returns a [Rect2] representing the boundary/extents of the FIRST [CollisionShape2D] child of a [CollisionObject2D] (e.g. [Area2D] or [CharacterBody2D]).
## NOTE: The rectangle is in the coordinates of the shape's [CollisionShape2D] container, with its anchor at the CENTER.
## Works most accurately & reliably for areas with a single [RectangleShape2D].
## Returns: A [Rect2] of the bounds. On failure: a rectangle with size -1 and the position set to the [CollisionObject2D]'s local position.
static func getShapeBounds(node: CollisionObject2D) -> Rect2:
	# HACK: Sigh @ Godot for making this so hard...

	# Find a CollisionShape2D child.
	var shapeNode: CollisionShape2D = findFirstChildOfType(node, CollisionShape2D)

	if not shapeNode:
		Debug.printWarning("getShapeBounds(): Cannot find a CollisionShape2D child", node)
		return Rect2(node.position.x, node.position.y, -1, -1) # Return an invalid negative-sized rectangle matching the node's origin.

	return shapeNode.shape.get_rect()


## Returns a [Rect2] representing the combined rectangular boundaries/extents of ALL the [CollisionShape2D] children of an a [CollisionObject2D] (e.g. [Area2D] or [CharacterBody2D]).
## To get the bounds of the first shape only, set [param maximumShapeCount] to 1.
## NOTE: The rectangle is in the LOCAL coordinates of the [CollisionObject2D]. To convert to GLOBAL coordinates, add + the area's [member Node2D.global_position].
## Works most accurately & reliably for areas/bodies with a single [RectangleShape2D].
## Returns: A [Rect2] of all the merged bounds. On failure: a rectangle with size -1 and the position set to the [CollisionObject2D]'s local position.
static func getShapeBoundsInNode(node: CollisionObject2D, maximumShapeCount: int = 100) -> Rect2:
	# TBD: PERFORMANCE: Option to cache results?
	# HACK: Sigh @ Godot for making this so hard...

	# INFO: PLAN: Overview: An [CollisionObject2D] has a [CollisionShape2D] child [Node], which in turn has a [Shape2D] [Resource].
	# In the parent CollisionObject2D, the CollisionShape2D's "anchor point" is at the top-left corner, so its `position` may be 0,0.
	# But inside the CollisionShape2D, the Shape2D's anchor point is at the CENTER of the shape, so its `position` would be for example 16,16 for a rectangle of 32x32.
	# SO, we have to figure out the Shape2D's rectangle in the coordinate space of the CollisionObject2D.
	# THEN convert it to global coordinates.

	if node.get_child_count() < 1: return Rect2(node.position.x, node.position.y, -1, -1) # In case of failure, return an invalid negative-sized rectangle matching the node's origin.

	# Get all CollisionShape2D children

	var combinedShapeBounds: Rect2
	var shapesAdded: int = 0
	var shapeSize:	 Vector2
	var shapeBounds: Rect2

	for shapeNode in node.get_children(): # TBD: PERFORMANCE: Use Node.find_children()?
		if shapeNode is CollisionShape2D:
			shapeSize = shapeNode.shape.get_rect().size # TBD: Should we use `extents`? It seems to be half of the size, but it seems to be a hidden property [as of 4.3 Dev 3].
			# Because a [CollisionShape2D]'s anchor is at the center of, we have to get it's top-left corner, by subtracting HALF the size of the actual SHAPE:
			shapeBounds = Rect2(shapeNode.position - shapeSize / 2, shapeSize) # TBD: PERFORMANCE: Use * 0.5?

			if shapesAdded < 1: combinedShapeBounds = shapeBounds # Is it the first shape?
			else: combinedShapeBounds.merge(shapeBounds)

			# DEBUG: Debug.printDebug(str("shape: ", shapeNode.shape, ", rect: ", shapeNode.shape.get_rect(), ", bounds in node: ", shapeBounds, ", combinedShapeBounds: ", combinedShapeBounds), node)
			shapesAdded += 1
			if shapesAdded >= maximumShapeCount: break

	if shapesAdded < 1:
		Debug.printWarning("getShapeBoundsInNode(): Cannot find a CollisionShape2D child", node)
		return Rect2(node.position.x, node.position.y, -1, -1)
	else:
		# DEBUG: Debug.printTrace([combinedShapeBounds, node.get_child_count(), shapesAdded], node)
		return combinedShapeBounds


## Calls [method Tools.getShapeBoundsInNode] and returns the [Rect2] representing the combined rectangular boundaries/extents of ALL the [CollisionShape2D] children of a [CollisionObject2D] (e.g. [Area2D] or [CharacterBody2D]), converted to GLOBAL coordinates.
## Useful for comparing the [Area2D]s etc. of 2 separate nodes/entities.
static func getShapeGlobalBounds(node: CollisionObject2D) -> Rect2:
	# TBD: PERFORMANCE: Option to cache results?
	var shapeGlobalBounds: Rect2 = getShapeBoundsInNode(node)
	shapeGlobalBounds.position   = node.to_global(shapeGlobalBounds.position)
	return shapeGlobalBounds


## Returns a [Vector2] representing the distance by which an [intended] inner/"contained" [Rect2] is outside of an outer/"container" [Rect2], e.g. a player's [ClimbComponent] in relation to a Climbable [Area2D] "ladder" etc.
## TIP: To put the inner rectangle back inside the container rectangle, SUBTRACT (or add the negative of) the returned offset from the [param containedRect]'s [member Rect2.position] (or from the position of the Entity it represents).
## WARNING: Does NOT include rotation or scaling etc.
## Returns: The offset/displacement by which the [param containedRect] is outside the bounds of the [param containerRect].
## Negative -X values mean to the left, +X means to the right. -Y means jutting upwards, +Y means downwards.
## (0,0) if the [param containedRect] is completely inside the [param containerRect].
static func getRectOffsetOutsideContainer(containedRect: Rect2, containerRect: Rect2) -> Vector2:
	# If the container completely encloses the containee, no need to do anything.
	if containerRect.encloses(containedRect): return Vector2.ZERO

	var displacement: Vector2

	# Out to the left?
	if containedRect.position.x < containerRect.position.x:
		displacement.x = containedRect.position.x - containerRect.position.x # Negative if the containee's left edge is further left
	# Out to the right?
	elif containedRect.end.x > containerRect.end.x:
		displacement.x = containedRect.end.x - containerRect.end.x # Positive if the containee's right edge is further right

	# Out over the top?
	if containedRect.position.y < containerRect.position.y:
		displacement.y = containedRect.position.y - containerRect.position.y # Negative if the containee's top is higher
	# Out under the bottom?
	elif containedRect.end.y > containerRect.end.y:
		displacement.y = containedRect.end.y - containerRect.end.y # Positive if the containee's bottom is lower

	return displacement


## Checks a list of [Rect2]s and returns the rectangle nearest to another specific rectangle.
## The [param comparedRects] would usually represent static "zones" and the [param primaryRect] may be the bounds of a player Entity or another character etc.
static func findNearestRect(primaryRect: Rect2, comparedRects: Array[Rect2]) -> Rect2:
	# TBD: PERFORMANCE: Option to cache results?

	var nearestRect:	 Rect2
	var minimumDistance: float = INF # Start with infinity

	# TBD: PERFORMANCE: All these variables could be replaced by directly accessing Rect2.position & Rect2.end etc. but these names may make the code easier to read and understand.

	var primaryLeft:	float = primaryRect.position.x
	var primaryRight:	float = primaryRect.end.x
	var primaryTop:		float = primaryRect.position.y
	var primaryBottom:	float = primaryRect.end.y

	var comparedLeft:	float
	var comparedRight:	float
	var comparedTop:	float
	var comparedBottom:	float

	var gap:			Vector2 # The pixels between the area edges
	var distance:		float	# The Euclidean distance between edges

	for comparedRect: Rect2 in comparedRects:
		if not comparedRect.abs().has_area(): continue # Skip rect if it doesn't have an area

		# If both regions are exactly the same position & size,
		# or either of them completely contain the other, then you can't get any nearer than that!
		if comparedRect.is_equal_approx(primaryRect) \
		or comparedRect.encloses(primaryRect) or primaryRect.encloses(comparedRect):
			minimumDistance = 0
			nearestRect = comparedRect
			break

		# Simplify names
		comparedLeft	= comparedRect.position.x
		comparedRight	= comparedRect.end.x
		comparedTop		= comparedRect.position.y
		comparedBottom	= comparedRect.end.y
		gap				= Vector2.ZERO # Gaps will default to 0 if the edges are touching

		# Compute horizontal gap
		if   primaryRight  < comparedLeft:	gap.x = comparedLeft - primaryRight		# Primary to the left of Compared?
		elif comparedRight < primaryLeft:	gap.x = primaryLeft  - comparedRight	# or to the right?

		# Compute vertical gap
		if   primaryBottom  < comparedTop:	gap.y = comparedTop - primaryBottom		# Primary above Compared?
		elif comparedBottom < primaryTop:	gap.y = primaryTop  - comparedBottom	# or below?

		# Get the Euclidean distance between edges
		distance = sqrt(gap.x * gap.x + gap.y * gap.y)

		# We have a nearer `nearestRect` if this is a new minimum
		if  distance < minimumDistance:
			minimumDistance = distance
			nearestRect = comparedRect

	return nearestRect


## Checks a list of [Area2D]s and returns the area nearest to another specific area.
## The [param comparedAreas] would usually be static "zones" and the [param primaryArea] may be the bounds of a player Entity or another character etc.
## NOTE: If 2 different [Area2D]s are at the same distance from [param primaryArea] then the one on top i.e. with the higher [member CanvasItem.z_index] will be used.
static func findNearestArea(primaryArea: Area2D, comparedAreas: Array[Area2D]) -> Area2D:
	# TBD: PERFORMANCE: Option to cache results?

	# DESIGN: PERFORMANCE: Cannot use findNearestRect() because that would require calling getShapeGlobalBounds() on all areas beforehand,
	# and there is a separate tie-break based on the Z index, so there has to be some code dpulication :')

	var nearestArea:	Area2D = null # Initialize with `null` to avoid the "used before assigning a value" warning
	var minimumDistance: float = INF  # Start with infinity

	var primaryAreaBounds:  Rect2 = Tools.getShapeGlobalBounds(primaryArea)
	var comparedAreaBounds: Rect2

	# TBD: PERFORMANCE: All these variables could be replaced by directly accessing Rect2.position & Rect2.end etc. but these names may make the code easier to read and understand.

	var primaryLeft:	float = primaryAreaBounds.position.x
	var primaryRight:	float = primaryAreaBounds.end.x
	var primaryTop:		float = primaryAreaBounds.position.y
	var primaryBottom:	float = primaryAreaBounds.end.y

	var comparedLeft:	float
	var comparedRight:	float
	var comparedTop:	float
	var comparedBottom:	float

	var gap:			Vector2 # The pixels between the area edges
	var distance:		float	# The Euclidean distance between edges

	for comparedArea: Area2D in comparedAreas:
		if comparedArea == primaryArea: continue

		comparedAreaBounds = Tools.getShapeGlobalBounds(comparedArea)
		if not comparedAreaBounds.abs().has_area(): continue # Skip area if it doesn't have an area!

		# If both regions are exactly the same position & size,
		# or either of them completely contain the other, then you can't get any nearer than that!
		if comparedAreaBounds.is_equal_approx(primaryAreaBounds) \
		or comparedAreaBounds.encloses(primaryAreaBounds) or primaryAreaBounds.encloses(comparedAreaBounds):
			# Is this the first overlapping area? (i.e. the minimum distance is not already 0)
			# or is it another overlapping area visually on top (with a higher Z index) of a previous overlapping area?
			if not is_zero_approx(minimumDistance) \
			or (nearestArea and comparedArea.z_index > nearestArea.z_index):
				minimumDistance = 0
				nearestArea = comparedArea
			continue # NOTE: Do NOT `break` the loop here! Keep checking for multiple overlapping areas to choose the one with the highest Z index.

		# Simplify names
		comparedLeft	= comparedAreaBounds.position.x
		comparedRight	= comparedAreaBounds.end.x
		comparedTop		= comparedAreaBounds.position.y
		comparedBottom	= comparedAreaBounds.end.y
		gap				= Vector2.ZERO # Gaps will default to 0 if the edges are touching

		# Compute horizontal gap
		if   primaryRight  < comparedLeft:	gap.x = comparedLeft - primaryRight		# Primary to the left of Compared?
		elif comparedRight < primaryLeft:	gap.x = primaryLeft  - comparedRight	# or to the right?

		# Compute vertical gap
		if   primaryBottom  < comparedTop:	gap.y = comparedTop - primaryBottom		# Primary above Compared?
		elif comparedBottom < primaryTop:	gap.y = primaryTop  - comparedBottom	# or below?

		# Get the Euclidean distance between edges
		distance = sqrt(gap.x * gap.x + gap.y * gap.y)

		# We have a nearer `nearestArea` if this is a new minimum
		if  distance < minimumDistance:
			minimumDistance = distance
			nearestArea = comparedArea

		# If 2 different [Area2D]s have the same distance,
		# use the one that is visually on top of the other: with a higher Z index
		elif is_equal_approx(distance, minimumDistance) \
		and nearestArea and comparedArea.z_index > nearestArea.z_index:
			nearestArea = comparedArea
		# TBD: Otherwise, keep the first area.

	return nearestArea


## Returns a random point inside the combined rectangular boundary of ALL an [Area2D]'s [Shape2D]s.
## NOTE: Does NOT verify whether a point is actually enclosed inside a [Shape2D].
## Works most accurately & reliably for areas with a single [RectangleShape2D].
static func getRandomPositionInArea(area: Area2D) -> Vector2:
	var areaBounds: Rect2 = getShapeBoundsInNode(area)

	# Generate a random position within the area.

	#randomize() # TBD: Do we need this?

	#var isWithinArea: bool = false
	#while not isWithinArea:

	var x: float = randf_range(areaBounds.position.x, areaBounds.end.x)
	var y: float = randf_range(areaBounds.position.y, areaBounds.end.y)
	var randomPosition: Vector2 = Vector2(x, y)

	#if shouldVerifyWithinArea: isWithinArea = ... # TODO: Cannot check if a point is within an area :( [as of 4.3 Dev 3]
	#else: isWithinArea = true

	# DEBUG: Debug.printDebug(str("area: ", area, ", areaBounds: ", areaBounds, ", randomPosition: ", randomPosition))
	return randomPosition


## Returns a COPY of a [Vector2i] moved in the specified [enum CompassDirection]
static func offsetVectorByCompassDirection(vector: Vector2i, direction: CompassDirection) -> Vector2i:
	return vector + Tools.compassDirectionVectors[direction]

#endregion


#region Physics Functions

## Sets the X and/or Y components of [member CharacterBody2D.velocity] to 0 if the [method CharacterBody2D.get_last_motion()] is 0 in the respective axes.
## This prevents the "glue effect" where if the player keeps inputting a direction while the character is pushed against a wall,
## it will take a noticeable delay to move in the other direction while the velocity gradually changes from the wall's direction to away from the wall.
static func resetBodyVelocityIfZeroMotion(body: CharacterBody2D) -> Vector2:
	var lastMotion: Vector2 = body.get_last_motion()
	if is_zero_approx(lastMotion.x): body.velocity.x = 0
	if is_zero_approx(lastMotion.y): body.velocity.y = 0
	return lastMotion


## Returns the [Shape2D] from a [CollisionObject2D]-based node (such as [Area2D] or [CharacterBody2D]) and a given "shape index"
## @experimental
static func getCollisionShape(node: CollisionObject2D, shapeIndex: int = 0) -> Shape2D:
	# What is this hell...
	var areaShapeOwnerID: int = node.shape_find_owner(shapeIndex)
	# UNUSED: var areaShapeOwner: CollisionShape2D = node.shape_owner_get_owner(areaShapeOwnerID)
	return node.shape_owner_get_shape(areaShapeOwnerID, shapeIndex) # CHECK: Should it be `shapeIndex` or 0?

#endregion


#region Visual Functions

## Returns an offset by which to modify the GLOBAL position of a node to keep it clamped within a maximum distance/radius (in any direction) from another node.
## If the [param nodeToClamp] is within the [param maxDistance] of the [param anchor] then (0,0) is returned i.e. no movement required.
## May be used to tether a visual effect (such as a targeting cursor) to an anchor such as a character sprite, as in [AimingCursorComponent] & [TetherComponent].
## NOTE: Does NOT return a direct position, so the [param nodeToClamp]'s `global_position` must be updated via `+=` NOT `=`!
static func clampPositionToAnchor(nodeToClamp: Node2D, anchor: Node2D, maxDistance: float) -> Vector2:
	var difference:	Vector2 = nodeToClamp.global_position - anchor.global_position # Use global position in case it's a parent/child relationship e.g. a visual component staying near its entity.
	var distance:	float   = difference.length()

	if distance > maxDistance:
		var offset: Vector2 = difference.normalized() * maxDistance
		return (anchor.global_position + offset) - nodeToClamp.global_position
	else:
		return Vector2.ZERO


## Returns a [Color] with R,G,B each set to a random value "quantized" to steps of 0.25
static func getRandomQuantizedColor() -> Color:
	const steps: Array[float] = [0.25, 0.5, 0.75, 1.0]
	return Color(steps.pick_random(), steps.pick_random(), steps.pick_random())


## Returns the specified "design size" centered on a Node's Viewport.
## NOTE: The viewport size may different from the scaled screen/window size.
static func getCenteredPositionOnViewport(node: Node2D, designWidth: float, designHeight: float) -> Vector2:
	# TBD: Better name?
	# The "design size" has to be specified because it's hard to get the actual size, accounting for scaling etc.
	var viewport: Rect2		= node.get_viewport_rect() # First see what the viewport size is
	var center: Vector2		= Vector2(viewport.size.x / 2.0, viewport.size.y / 2.0) # Get the viewport center
	var designSize: Vector2	= Vector2(designWidth, designHeight) # Get the node design size
	return center - (designSize / 2.0) # Center the size on the viewport


static func addRandomDistance(position: Vector2,    \
minimumDistance: Vector2, maximumDistance: Vector2, \
xScale: float = 1.0, yScale: float = 1.0) -> Vector2:

	var randomizedPosition: Vector2 = position
	randomizedPosition.x += randf_range(minimumDistance.x, maximumDistance.x) * xScale
	randomizedPosition.y += randf_range(minimumDistance.y, maximumDistance.y) * yScale
	return randomizedPosition

## Returns the global position of the top-left corner of the screen in the camera's view.
static func getScreenTopLeftInCamera(camera: Camera2D) -> Vector2:
	var cameraCenter: Vector2 = camera.get_screen_center_position()
	return cameraCenter - camera.get_viewport_rect().size / 2


## NOTE: Does NOT add the new copy to the original node's parent. Follow up with [method Tools.addChildAndSetOwner].
## Default flags: DUPLICATE_SIGNALS + DUPLICATE_GROUPS + DUPLICATE_SCRIPTS + DUPLICATE_USE_INSTANTIATION
static func createScaledCopy(nodeToDuplicate: Node2D, copyScale: Vector2, flags: int = 15) -> Node2D:
	var scaledCopy: Node2D = nodeToDuplicate.duplicate(flags)
	scaledCopy.scale = copyScale
	return scaledCopy


#endregion


#region Tile Map Functions

static func getCellGlobalPosition(map: TileMapLayer, coordinates: Vector2i) -> Vector2:
	var cellPosition: Vector2 = map.map_to_local(coordinates)
	var cellGlobalPosition: Vector2 = map.to_global(cellPosition)
	return cellGlobalPosition


## For a list of custom data layer names, see [Global.TileMapCustomData].
static func getTileData(map: TileMapLayer, coordinates: Vector2i, dataName: StringName) -> Variant:
	var tileData: TileData = map.get_cell_tile_data(coordinates)
	return tileData.get_custom_data(dataName) if tileData else null


## Gets custom data for an individual cell of a [TileMapCellData].
## NOTE: CELLS are different from TILES; A Tile is the resource used by a [TileSet] to paint multiple cells of a [TileMapLayer].
## DESIGN: This is a separate function on top of [TileMapCellData] because it may redirect to a native Godot feature in the future.
static func getCellData(map: TileMapLayerWithCellData, coordinates: Vector2i, key: StringName) -> Variant:
	return map.getCellData(coordinates, key)


## Sets custom data for an individual cell of a [TileMapLayerWithCellData].
## NOTE: CELLS are different from TILES; A Tile is the resource used by a [TileSet] to paint multiple cells of a [TileMapLayer].
## DESIGN: This is a separate function on top of [TileMapLayerWithCellData] because it may redirect to a native Godot feature in the future.
static func setCellData(map: TileMapLayerWithCellData, coordinates: Vector2i, key: StringName, value: Variant) -> void:
	map.setCellData(coordinates, key, value)


## Uses a custom data structure to check if individual [TileMap] cells (not tiles) are occupied by an [Entity] and returns it.
## NOTE: Does NOT check for [member Global.TileMapCustomData.isOccupied] first, only the [member Global.TileMapCustomData.occupant]
static func getCellOccupant(data: TileMapCellData, coordinates: Vector2i) -> Entity:
	return data.getCellData(coordinates, Global.TileMapCustomData.occupant)


## Uses a custom data structure to mark individual [TileMap] cells (not tiles) as occupied or unoccupied by an [Entity].
static func setCellOccupancy(data: TileMapCellData, coordinates: Vector2i, isOccupied: bool, occupant: Entity) -> void:
	data.setCellData(coordinates, Global.TileMapCustomData.isOccupied, isOccupied)
	data.setCellData(coordinates, Global.TileMapCustomData.occupant, occupant if isOccupied else null)


static func checkTileAndCellVacancy(map: TileMapLayer, data: TileMapCellData, coordinates: Vector2i, ignoreEntity: Entity) -> bool:
	# CHECK: First check the CELL data because it's quicker, right?
	var isCellVacant: bool = Tools.checkCellVacancy(data, coordinates, ignoreEntity)
	if not isCellVacant: return false # If there is an occupant, no need to check the Tile data, just scram

	# Then check the TILE data
	var isTileVacant: bool = Tools.checkTileVacancy(map, coordinates)

	return isCellVacant and isTileVacant


## Checks if the specified tile is vacant by examining the custom tile/cell data for flags such as [constant Global.TileMapCustomData.isWalkable].
static func checkTileVacancy(map: TileMapLayer, coordinates: Vector2i) -> bool:
	var isTileVacant: bool = false

	# NOTE: DESIGN: Missing values should be considered as `true` to assist with quick prototyping
	# TODO: Check all this in a more elegant way

	var tileData: 	TileData = map.get_cell_tile_data(coordinates)
	var isWalkable:	Variant
	var isBlocked:	Variant

	if tileData:
		isWalkable = tileData.get_custom_data(Global.TileMapCustomData.isWalkable)
		isBlocked  = tileData.get_custom_data(Global.TileMapCustomData.isBlocked)

	if map is TileMapLayerWithCellData and map.debugMode: Debug.printDebug(str("tileData[isWalkable]: ", isWalkable, ", [isBlocked]: ", isBlocked))

	# If there is no data, assume the tile is always vacant.
	isTileVacant = (isWalkable or isWalkable == null) and (not isBlocked or isWalkable == null)

	return isTileVacant


## Checks if the specified tile is vacant by examining the custom tile/cell data for flags such as [constant Global.TileMapCustomData.isWalkable].
static func checkCellVacancy(mapData: TileMapCellData, coordinates: Vector2i, ignoreEntity: Entity) -> bool:
	var isCellVacant: bool = false

	# First check the CELL data because it's quicker

	var cellDataOccupied: Variant = mapData.getCellData(coordinates, Global.TileMapCustomData.isOccupied) # NOTE: Should not be `bool` so it can be `null` if missing, NOT `false` if missing.
	var cellDataOccupant: Entity  = mapData.getCellData(coordinates, Global.TileMapCustomData.occupant)

	if mapData.debugMode: Debug.printDebug(str("checkCellVacancy() ", mapData, " @", coordinates, " cellData[cellDataOccupied]: ", cellDataOccupied, ", occupant: ", cellDataOccupant))

	if cellDataOccupied is bool:
		isCellVacant = not cellDataOccupied or cellDataOccupant == ignoreEntity
	else:
		# If there is no data, assume the cell is always unoccupied.
		isCellVacant = true

	# If there is an occupant, no need to check the Tile data, just scram
	if not isCellVacant: return false

	return isCellVacant


## Verifies that the given coordinates are within the specified [TileMapLayer]'s grid.
static func checkTileMapCoordinates(map: TileMapLayer, coordinates: Vector2i) -> bool:
	var gridRect: Rect2i = map.get_used_rect()
	return gridRect.has_point(coordinates)


## Returns the rectangular bounds of a [TileMapLayer] containing all of its "used" or "painted" cells, in the coordinate space of the TileMap's parent.
## ALERT: This may not correspond to the visual position of a cell/tile, i.e. it ignores the [member TileData.texture_origin] property of individual tiles.
static func getTileMapScreenBounds(map: TileMapLayer) -> Rect2: # TBD: Rename to getTileMapBounds()?
	var cellGrid:	Rect2 = Rect2(map.get_used_rect()) # Convert integer `Rect2i` to float to simplify calculations
	if not cellGrid.has_area(): return Rect2() # Null area if there are no cells

	var screenRect:	Rect2
	var tileSize:	Vector2 = Vector2(map.tile_set.tile_size) # Convert integer `Vector2i` to float to simplify calculations

	# The points will initially be in the TileMap's own space
	screenRect.position  = cellGrid.position * tileSize
	screenRect.size		 = cellGrid.size * tileSize

	# Offset the bounds by the map's own position in the map's parent's space
	screenRect.position += map.position

	return screenRect


## Checks if a [Vector2] is inside a [TileMapLayer].
## IMPORTANT: The [param point] must be in the coordinate space of the [param map]'s parent node. See [method Node2D.to_local].
## WARNING: Internal float-based positions may have fractional values like 0.5 etc. which may cause calculations to return a result that does not match the visuals onscreen, e.g. intersections may return false.
static func isPointInTileMap(point: Vector2, map: TileMapLayer) -> bool:
	# NOTE: Apparently there is no need to grow_individual() the Rect2's right & bottom edges by 1 pixel even though Rect2.has_point() does NOT include points on those edges, according to the Godot documentation.
	return Tools.getTileMapScreenBounds(map).has_point(point)


## Checks if a [Rect2]'s [member Rect2.position] origin and/or [member Rect2.end] points are inside a [TileMapLayer].
## If [param checkOriginAndEnd] is `true` (default) then this method returns `true` only if the rectangle's origin AND end are BOTH fully inside the TileMap.
## If [param checkOriginAndEnd] is `false` then even a partial intersection returns `true`.
## IMPORTANT: The [param rectangle] must be in the coordinate space of the [param map]'s parent node. See [method Node2D.to_local].
## NOTE: Rotation and other transforms are NOT supported.
## WARNING: Internal float-based positions may have fractional values like 0.5 etc. which may cause calculations to return a result that does not match the visuals onscreen, e.g. intersections may return false.
static func isRectInTileMap(rectangle: Rect2, map: TileMapLayer, checkOriginAndEnd: bool = true) -> bool:
	var tileMapBounds: Rect2 = Tools.getTileMapScreenBounds(map)
	return tileMapBounds.encloses(rectangle) if checkOriginAndEnd else rectangle.intersects(tileMapBounds)


## Checks for a collision between a [TileMapLayer] and physics body at the specified tile coordinates.
## ALERT: UNIMPLEMENTED: Will ALWAYS return `true`. Currently there seems to be no way to easily check this in Godot yet.
## @experimental
static func checkTileCollision(map: TileMapLayer, _body: PhysicsBody2D, _coordinates: Vector2i) -> bool:
	# If the TileMap or its collisions are disabled, then the tile is always available.
	if not map.enabled or not map.collision_enabled: return true
	return true # HACK: TODO: Implement


## Converts [TileMap] cell coordinates from [param sourceMap] to [param destinationMap].
## The conversion is performed by converting cell coordinates to pixel/screen coordinates first.
static func convertCoordinatesBetweenTileMaps(sourceMap: TileMapLayer, cellCoordinatesInSourceMap: Vector2i, destinationMap: TileMapLayer) -> Vector2i:

	# 1: Convert the source TileMap's cell coordinates to pixel (screen) coordinates, in the source map's space.
	# NOTE: This may not correspond to the visual position of the tile; it ignores `TileData.texture_origin` of the individual tiles.
	var pixelPositionInSourceMap: Vector2 = sourceMap.map_to_local(cellCoordinatesInSourceMap)

	# 2: Convert the pixel position to the global space
	var globalPosition: Vector2 = sourceMap.to_global(pixelPositionInSourceMap)

	# 3: Convert the global position to the destination TileMap's space
	var pixelPositionInDestinationMap: Vector2 = destinationMap.to_local(globalPosition)

	# 4: Convert the pixel position to the destination map's cell coordinates
	var cellCoordinatesInDestinationMap: Vector2i = destinationMap.local_to_map(pixelPositionInDestinationMap)

	Debug.printDebug(str("Tools.convertCoordinatesBetweenTileMaps() ", sourceMap, " @", cellCoordinatesInSourceMap, " → sourcePixel: ", pixelPositionInSourceMap, " → globalPixel: ", globalPosition, " → destinationPixel: ", pixelPositionInDestinationMap, " → @", cellCoordinatesInDestinationMap, " ", destinationMap))
	return cellCoordinatesInDestinationMap


## Damages a [TileMapLayer] Cell if it is [member Global.TileMapCustomData.isDestructible].
## Changes the cell's tile to the [member Global.TileMapCustomData.nextTileOnDamage] if there is any,
## or erases the cell if there is no "next tile" specified or both X & Y coordinates are below 0 i.e. (-1,-1)
## Returns `true` if the cell was damaged.
## @experimental
static func damageTileMapCell(map: TileMapLayer, coordinates: Vector2i) -> bool:
	# TODO: Variable health & damage
	# PERFORMANCE: Do not call Tools.getTileData() to reduce calls
	var tileData: TileData = map.get_cell_tile_data(coordinates)
	if tileData:
		var isDestructible: bool = tileData.get_custom_data(Global.TileMapCustomData.isDestructible)
		if  isDestructible:
			var nextTileOnDamage: Vector2i = tileData.get_custom_data(Global.TileMapCustomData.nextTileOnDamage)
			if nextTileOnDamage and (nextTileOnDamage.x >= 0 or nextTileOnDamage.y >= 0): # Both negative coordinates are invalid or mean "destroy on damage"
				map.set_cell(coordinates, 0, nextTileOnDamage)
			else: map.erase_cell(coordinates)
			return true

	return false


## Sets all the Cells in the specified [TileMapLayer] region to random Tiles from the specified coordinates in the Map's [TileSet].
## The [param modificationChance] must be between 0…1 and is rolled for Cell to determine whether it will be modified.
## If [param skipEmptyCells] is `true` then empty "unpainted" cells in the TileMap will be left untouched.
static func randomizeTileMapCells(map: TileMapLayer, cellRegionStart: Vector2i, cellRegionEnd: Vector2i, tileCoordinatesMin: Vector2i, tileCoordinatesMax: Vector2i, modificationChance: float, skipEmptyCells: bool = false) -> void:
	# TODO: Validate parameters and sizes
	# NOTE: Rect2i is less intuitive because it uses width/height parameters for initialization, not direct end coordinates.

	var randomTile: Vector2i

	# NOTE: +1 to range() end to make the bounds inclusive
	for y in range(cellRegionStart.y, cellRegionEnd.y + 1):
		for x in range(cellRegionStart.x, cellRegionEnd.x + 1):
			if skipEmptyCells and map.get_cell_atlas_coords(Vector2i(x, y)) == Vector2i(-1, -1): continue # (-1,-1) = Cell does not exist
			if is_equal_approx(modificationChance, 1.0) or randf() < modificationChance: # TBD: Should this be an integer?
				randomTile = Vector2i(randi_range(tileCoordinatesMin.x, tileCoordinatesMax.x), randi_range(tileCoordinatesMin.y, tileCoordinatesMax.y))
				map.set_cell(Vector2i(x, y), 0, randomTile)


## Creates instance copies of the specified Scene and places them in the TileMap's cells, each at a unique position in the grid.
## Returns a Dictionary of the nodes that were created, with their cell coordinates as the keys.
static func populateTileMap(map: TileMapLayer, sceneToCopy: PackedScene, numberOfCopies: int, parentOverride: Node = null, groupToAddTo: StringName = &"") -> Dictionary[Vector2i, Node2D]:
	# TODO: FIXME: Handle negative cell coordinates
	# TBD: Add option for range of allowed cell coordinates instead of using the entire TileMap?

	# Validation

	if not sceneToCopy:
		Debug.printWarning("No sceneToCopy specified", str(map))
		return {}

	var mapRect: Rect2i = map.get_used_rect()

	if not mapRect.has_area():
		Debug.printWarning(str("map has no area: ", mapRect.size), str(map))
		return {}

	var totalCells: int = mapRect.size.x * mapRect.size.y

	if numberOfCopies > totalCells:
		Debug.printWarning(str("numberOfCopies: ", numberOfCopies, " > totalCells: ", totalCells), str(map))
		return {}

	# Spawn

	var nodesSpawned: Dictionary[Vector2i, Node2D]
	var parent: Node2D = parentOverride if parentOverride else map

	for count in numberOfCopies:
		var newNode: Node2D = sceneToCopy.instantiate()

		# Find a unoccupied cell
		# Rect size = 1 if 1 cell, so subtract - 1
		# TBD: A more efficient way?

		var coordinates: Vector2i = Vector2i(
			randi_range(0, mapRect.size.x - 1),
			randi_range(0, mapRect.size.y - 1))

		while(nodesSpawned.get(coordinates)):
			coordinates = Vector2i(
				randi_range(0, mapRect.size.x - 1),
				randi_range(0, mapRect.size.y - 1))

		# Position
		if parent == map:
			newNode.position = map.map_to_local(coordinates)
		else:
			newNode.position = parent.to_local(
				map.to_global(
					map.map_to_local(coordinates)))

		# Add

		Tools.addChildAndSetOwner(newNode, parent)
		if not groupToAddTo.is_empty(): newNode.add_to_group(groupToAddTo, true) # persistent
		nodesSpawned[coordinates] = newNode

	return nodesSpawned

#endregion


#region UI Functions

## Sets the text of [Label]s from a [Dictionary].
## Iterates over an array of [Label]s, and takes the prefix of the node name by removing the "Label" suffix, if any, and making it LOWER CASE,
## and searches the [param dictionary] for any String keys which match the label's name prefix. If there is a match, sets the label's text to the dictionary value for each key.
## Example: `logMessageLabel.text = dictionary["logmessage"]`
## TIP: Use to quickly populate an "inspector" UI with text representing multiple properties of a selected object etc.
## NOTE: The dictionary keys must all be fully LOWER CASE.
static func setLabelsWithDictionary(labels: Array[Label], dictionary: Dictionary[String, Variant], shouldShowPrefix: bool = false, shouldHideEmptyLabels: bool = false) -> void:
	# DESIGN: We don't accept an array of any Control/Node because Labels may be in different containers, and some Labels may not need to be assigned from the Dictionary.
	for label: Label in labels:
		if not label: continue

		var namePrefix: String = label.name.trim_suffix("Label").to_lower()
		var dictionaryValue: Variant = dictionary.get(namePrefix)

		label.text = namePrefix + ":" if shouldShowPrefix else "" # TBD: Space after colon?

		if dictionaryValue:
			label.text += str(dictionaryValue)
			if shouldHideEmptyLabels: label.visible = true # Automatically show non-empty labels in case they were already hidden
		else:
			label.text += ""
			if shouldHideEmptyLabels: label.visible = false


## Displays the values of the specified [Object]'s properties in different [Label]s.
## Each [Label] must have EXACTLY the same case-sensitie name as a matching property in [param object]: `isEnabled` but NOT `IsEnabled` or `EnabledLabel` etc.
## TIP: Example: May be used to quickly display a [Resource] or [Component]'s data in a UI [Container].
## RETURNS: The number of [Label]s with names matching [param object] properties.
## For a script to attach to a UI [Container], use "PrintPropertiesToLabels.gd"
static func printPropertiesToLabels(object: Object, labels: Array[Label], shouldShowPropertyNames: bool = true, shouldHideNullProperties: bool = true, shouldUnhideAvailableLabels: bool = true) -> int:
	var value: Variant # NOTE: Should not be String so we can explicitly check for `null`
	var matchCount: int = 0

	# Go through all our Labels
	for label in labels:
		# Does the object have a property with a matching name?
		value = object.get(label.name)

		if shouldShowPropertyNames: label.text = label.name + ": "
		else: label.text = ""

		# NOTE: Explicitly check for `null` to avoid cases like "0.0" being treated as a non-existent property.
		if value != null:
			label.text += str(value)
			if shouldUnhideAvailableLabels: label.visible = true
			matchCount += 1
		else:
			label.text += "null" if shouldShowPropertyNames else ""
			if shouldHideNullProperties: label.visible = false

	return matchCount

#endregion


#region Text Functions

## Returns an Enum's value along with its key as a text string.
## TIP: To just get the Enum key corresponding to the specified value, use [method Dictionary.find_key].
## WARNING: May NOT work as expected for enums with non-sequential values or starting below 0, or if there are multiple identical values, or if there is a 'null' key.
static func getEnumText(enumType: Dictionary, value: int) -> String:
	# TBD: Less ambiguous name?
	var key: String

	key = str(enumType.find_key(value)) # TBD: Check for `null`?
	if key.is_empty(): key = "[invalid key/value]"

	return str(value, " (", key, ")")


## Iterates over a [String] and replaces all occurrences of text matching the [param substitutions] [Dictionary]'s [method Dictionary.keys] with the values for those keys.
## Example: A Dictionary of { "Apple":"Banana", "Cat":"Dog" } would replace all "Apple" in [param sourceString] with "Banana" and all "Cat" with "Dog".
## NOTE: Does NOT modify the [param sourceString], instead returns a modified string.
static func replaceStrings(sourceString: String, substitutions: Dictionary[String, String]) -> String:
	var modifiedString: String = sourceString
	for key: String in substitutions.keys():
		modifiedString = modifiedString.replace(key, substitutions[key])
	return modifiedString

#endregion


#region Maths Functions

## TIP: To "truncate" the number of decimal points, use Godot's [method @GlobalScope.snappedf] function.

## "Rolls" a random integer number from 1…100 (inclusive) and returns `true` if the result is less than or equal to the specified [param chancePercent].
## i.e. If the chance is 10% then a roll of 1…10 will succeed but 11…100 (90 possibilities) will fail.
func rollChance(chancePercent: int) -> bool:
	return randi_range(1, 100) <= chancePercent


## Returns a copy of a number wrapped around to the [param minimum] or [param maximum] value if it exceeds or goes below either limit (inclusive).
## May be used to cycle through a range by adding/subtracting an offset to [param current] such as +1 or -1. The number may be an array index or `enum` state, or a sprite position to wrap it around the screen Pac-Man-style.
static func wrapInteger(minimum: int, current: int, maximum: int) -> int:
	# TBD: Use Godot's pingpong()?
	if minimum > maximum:
		Debug.printWarning(str("cycleInteger(): minimum ", minimum, " > maximum ", maximum, ", returning current: ", current))
		return current
	elif minimum == maximum: # If there is no difference between the range, just return either.
		return minimum

	# NOTE: Do NOT clamp first! So that an already-offset value may be provided for `current`

	# THANKS: rubenverg@Discord, lololol__@Discord
	return posmod(current - minimum, maximum - minimum + 1) + minimum # +1 to make limits inclusive

#endregion


#region File System Functions

## Returns a copy of the specified [param path] with the specified [param prefix] added if the path does not begin with "res://" or "user://".
## If the path already has a prefix then it is returned unmodified.
## NOTE: Case-sensitive.
static func addPathPrefixIfMissing(path: String, prefix: String = "res://") -> String:
	if  not path.begins_with("res://") \
	and not path.begins_with("user://"):
		return prefix + path
	else:
		return path


## Returns a list of all the subfolders and recursively searches for any deeper subfolders inside the folder at [param initialPath].
## IMPORTANT: The [param initialPath] must begin with `"res://"` or `"user://"`
static func findAllSubfolders(initialPath: String = "res://") -> PackedStringArray:
	var subfolders: PackedStringArray
	var dirAccess:  DirAccess = DirAccess.open(initialPath)
	if not dirAccess:
		print("Error: Cannot open DirAccess @ " + initialPath) # NOTE: Don't use Debug.gd logging so this method can be used by the Comedot plugin/addon.
		return []

	# PLAN: Go through each folder in the `subfolders` array,
	# index-wise, not via iterator as the array will be modified during iteration.
	# Get the subfolders of each folder, and append them at the end of the array.
	# This way, all child folders are added to the list, and then their children are added, ensuring a full traversal.

	subfolders.append(initialPath) # Add the initial folder to enumerate the contents of

	var index: int = 0
	var parentPath: String
	var newSubfoldersToAppend: PackedStringArray

	while index < subfolders.size():
		# WORKAROUND: Dummy Godot does not give us the full path in each item returned by DirAccess.get_directories_at()
		# so we have to prefix it manually >:(
		parentPath = subfolders[index] # Get the current folder being enumerated, which is assumed to be prefixed with its full path already.
		newSubfoldersToAppend.clear() # Clear any previous additions
		for newSubfolder in DirAccess.get_directories_at(parentPath):
			newSubfoldersToAppend.append(parentPath + "/" + newSubfolder) # Prefix the parent folder's path to each subfolder's name. grrr
		subfolders.append_array(newSubfoldersToAppend)
		index += 1 # Enumerate the next folder

	return subfolders


## Returns an array of all files at the specified path which include [param filter] (case-insensitive) in the filename.
## If [param filter] is empty then all files are returned.
## If the [param folderPath] does not begin with "res://" or "user://" (case-sensitive) then "res://" is added.
## NOTE: When used on a "res://" path in an exported project, only the files actually included in the PCK at the given folder level are returned.
static func getFilesInFolder(folderPath: String, filter: String = "") -> PackedStringArray:
	folderPath = Tools.addPathPrefixIfMissing(folderPath, "res://") # Use the exported/packaged resources path if omitted.
	var folder: DirAccess = DirAccess.open(folderPath)
	if folder == null:
		Debug.printWarning("getFilesFromFolder() cannot open " + folderPath)
		return []

	folder.list_dir_begin() # CHECK: Necessary for get_files()?
	var files: PackedStringArray

	for fileName: String in folder.get_files():
		if filter.is_empty() or fileName.containsn(filter):
			files.append(folder.get_current_dir() + "/" + fileName) # CHECK: Use get_current_dir() instead of folderPath?

	folder.list_dir_end() # CHECK: Necessary for get_files()?
	return files


## Returns an array of the exported resources in the specified folder which include [param filter] (case-insensitive) in the exported filename.
## If [param filter] is empty then all resources are returned.
## If the [param folderPath] does not begin with "res://" or "user://" (case-sensitive) then "res://" is added.
static func getResourcesInFolder(folderPath: String, filter: String = "") -> PackedStringArray:
	folderPath = Tools.addPathPrefixIfMissing(folderPath, "res://") # Use the exported/packaged resources path if omitted.
	var resources: PackedStringArray = ResourceLoader.list_directory(folderPath)
	if resources.is_empty(): return []

	if not folderPath.ends_with("/"): folderPath += "/" # Tack the tail on

	var filteredResources: PackedStringArray
	for resourceName: String in resources:
		if filter.is_empty() or resourceName.containsn(filter):
			filteredResources.append(folderPath + resourceName)

	return filteredResources


## Returns the path of the specified object, after replacing its extension with the specified string.
## May be used for quickly getting the accompanying `.gd` Script for a `.tscn` Scene or `.tres` Resource, if they share the same file name.
## If the resulting file with the replaced extension does not exist, an empty string is returned.
static func getPathWithDifferentExtension(sourcePath: String, replacementExtension: String) -> String:
	# var sourcePath: String = object.get_script().resource_path
	if sourcePath.is_empty(): return ""

	var sourceExtension: String = "." + sourcePath.get_extension() # Returns the file extension without the leading period
	var replacementPath: String = sourcePath.replacen(sourceExtension, replacementExtension) # The `N` in `replacen` means case-insensitive

	Debug.printDebug(str("getPathWithDifferentExtension() sourcePath: ", sourcePath, ", replacementPath: ", replacementPath))

	if FileAccess.file_exists(replacementPath): return replacementPath
	else:
		Debug.printDebug(str("replacementPath does not exist: ", replacementPath))
		return ""

#endregion


#region Miscellaneous Functions

static func validateArrayIndex(array: Array, index: int) -> bool:
	return index >= 0 and index < array.size()


## Checks whether a [Variant] value may be considered a "success", for example the return of a function.
## If [param value] is a [bool], then it is returned as is.
## If the value is an [Array] or [DIctionary], `true` is returned if it's not empty.
## For all other types, `true` is returned if the value is not `null`.
## TIP: Use for verifying whether a [Payload]'s [method executeImplementation] executed successfully.
static func checkResult(value: Variant) -> bool:
	# Because GDScript doesn't have Tuples :')
	if    value is bool: return value
	elif  value is Array or value is Dictionary: return not value.is_empty()
	elif  value != null: return true
	else: return false


## Stops a [Timer] and emits its [signal Timer.timeout] signal.
## WARNING: This may cause bugs, especially when multiple objects are using `await` to wait for a Timer.
## Returns: The leftover time before the timer was stopped. WARNING: May not be accurate!
static func skipTimer(timer: Timer) -> float:
	# WARNING: This may not be accurate because the Timer is still running until the `stop()` call.
	var leftoverTime: float = timer.time_left
	timer.stop()
	timer.timeout.emit()
	return leftoverTime


## Searches for a [param value] in an [param options] array and if found, returns the next item from the list.
## If [param value] is the last member of the array, then the array's first item is returned.
## If there is only 1 item in the array, then the same value is returned, or `null` if [param value] is not found.
## TIP: May be used to cycle through a list of possible options, such as [42, 69, 420, 666]
## WARNING: The cycle may get "stuck" if there are 2 or more identical values in the list: [a, b, b, c] will always only return the 2nd `b`
static func cycleThroughList(value: Variant, list: Array[Variant]) -> Variant:
	if not value or list.is_empty(): return null

	var index: int = list.find(value)

	if index >= 0: # -1 means value not found.
		if list.size() == 1: return value
		else: return list[index+1] if index < list.size()-1 else list[0] # Wrap around if at the end of the array.
	else: return null

#endregion
