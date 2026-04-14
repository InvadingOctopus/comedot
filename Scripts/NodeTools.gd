## Helper functions to assist with common tasks involving [Node] or [Node2D]

class_name NodeTools
extends GDScript # NOTE: DESIGN: We cannot `extends Node` because we want these functions to be globally available, not just for instances of a special subclass.


#region Parent/Child Tree Heirarchy 

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


## Calls [method NodeTools.findFirstChildOfType] to return the first child of [param parentNode] which matches ANY of the specified [param types]  (searched in the array order).
## If [param includeParent] is `true` (default) then the [param parentNode] ITSELF is returned AFTER none of the requested types are found.
## This may be useful for choosing certain child nodes of an entity to operate on, like an [AnimatedSprite2D] or [Sprite2D] to animate, otherwise operate on the entity itself.
## WARNING: [param returnParentIfNoMatches] returns the [param parentNode] even if it is NOT one of the [param childTypes]!
## PERFORMANCE: Should be the same as multiple calls to [method NodeTools.findFirstChildOfType] in order of the desired types.
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
## WARNING: May cause stack overflow if [param nodeToIterate] has a deeply-nested node trees.
## @experimental
static func flatMapNodeTree(nodeToIterate: Node, existingList: Array[Node]) -> void:
	# TODO: Better name?
	# TODO: Filtering
	# TODO: This should be a generic function for flattening trees of any type :')
	existingList.append(nodeToIterate)
	for index in nodeToIterate.get_child_count(): # No need to -1 because the end of a range is EXCLUSIVE
		flatMapNodeTree(nodeToIterate.get_child(index), existingList)


## Calls [method NodeTools.flatMapNodeTree] to return a linear/"flattened" list of ALL the child nodes AND their subchildren, recursively, from the specified [param firstNode].
## NOTE: INCLUDES [param firstNode] (the parent)
## @experimental
static func getAllChildrenRecursively(firstNode: Node) -> Array[Node]:
	# TBD: Merge with flatMapNodeTree()?
	var flatList: Array[Node]
	NodeTools.flatMapNodeTree(firstNode, flatList)
	return flatList


## Replaces a child node with another node at the same index (order), optionally copying the position, rotation and/or scale.
## NOTE: The previous child and its sub-children are NOT deleted by default. To delete a child, set [param freeReplacedChild] or use [method Node.queue_free]
## Returns: `true` if [param childToReplace] was found and replaced.
static func replaceChild(
	parentNode:		Node,
	childToReplace:	Node,
	newChild:		Node,
	copyPosition:	bool = false,
	copyRotation:	bool = false,
	copyScale:		bool = false,
	freeReplacedChild: bool = false) -> bool:
	
	if  childToReplace == newChild: return true # Are we trying to make the same node replace itself lol

	if  childToReplace.get_parent() != parentNode:
		Debug.printWarning(str("replaceChild() childToReplace.get_parent(): ", childToReplace.get_parent(), " != parentNode: ", parentNode))
		return false

	# Is the new child already in another parent?
	# TODO: Option to remove new child from existing parent
	var newChildCurrentParent: Node = newChild.get_parent()
	if  newChildCurrentParent != null and newChildCurrentParent != parentNode:
		Debug.printWarning("replaceChild(): newChild already in another parent: " + str(newChild, " in ", newChildCurrentParent))
		return false
	
	# Copy properties
	if  newChild is Node2D and childToReplace is Node2D:
		if copyPosition: newChild.position	= childToReplace.position
		if copyRotation: newChild.rotation	= childToReplace.rotation
		if copyScale:	 newChild.scale		= childToReplace.scale

	# Swap the kids
	var previousChildIndex: int = childToReplace.get_index() # The original index
	parentNode.remove_child(childToReplace) # NOTE: Do not use `replace_by()` which transfers all sub-children as well.

	# If `newChild` is already in the target `parentNode`, just move it to the `childToReplace`'s place in the order and position etc.
	if newChild.get_parent() != parentNode:
		NodeTools.addChildAndSetOwner(newChild, parentNode) # Ensure persistence e.g. to a [PackedScene] for save/load

	parentNode.move_child(newChild, previousChildIndex)

	# Yeet the disowned child?
	if freeReplacedChild: childToReplace.queue_free()

	return true


## Removes the first child of the [param parentNode], if any, and adds the specified [param newChild]. Optionally copies the position, rotation and/or scale.
## NOTE: The new child is added regardless of whether the parent already had a child or not.
## NOTE: The previous child and its sub-children are NOT deleted by default. To delete a child, set [param freeReplacedChild] or use [method Node.queue_free].
static func replaceFirstChild(parentNode: Node, newChild: Node, copyPosition: bool = false, copyRotation: bool = false, copyScale: bool = false, freeReplacedChild: bool = false) -> void:
	var childToReplace: Node = parentNode.get_child(0) if parentNode.get_child_count() > 0 else null
	# Debug.printDebug(str("replaceFirstChildControl(): ", childToReplace, " → ", newChild), parentNode)

	if childToReplace:
		NodeTools.replaceChild(parentNode, childToReplace, newChild, copyPosition, copyRotation, copyScale, freeReplacedChild)
	else: # If there are no children, just add the new one.
		NodeTools.addChildAndSetOwner(newChild, parentNode) # Ensure persistence


## Removes each child from the [parameter parent] then calls [method Node.queue_free] on the child.
## Returns: The number of removed children.
static func removeAllChildren(parent: Node) -> int:
	var removalCount: int = 0

	for child in parent.get_children():
		parent.remove_child(child) # TBD: Is this needed? Does NOT delete nodes, unlike queue_free() but maybe we want to see immediate removal instead of waiting on "queue"
		child.queue_free()
		removalCount += 1

	return removalCount


## Asks a node's parent to remove all other children of the same class/type/script as the calling [param node].
## NOTE: If there are multiple children of the same "type" such as [Label] but they have different SCRIPTS, they will NOT count as the "same type"!
## Returns: The number of nodes removed.
## @experimental
static func removeSiblingsOfSameType(node: Node, shouldFree: bool = false) -> int:
	# TODO: Handle subclasses
	# NOTE: "Built‑in" Godot types such as Sprite2D, Label etc. may have an empty get_script()
	# so we may have to try checking the "class name" too.

	var parent:		Node	= node.get_parent()
	var nodeScript:	Variant	= node.get_script()
	var nodeClass:	String	= node.get_class()

	if not is_instance_valid(parent):
		Debug.printWarning(str("removeSiblingsOfSameType(): ", node, " has no valid parent!"))
		return 0

	var children: Array[Node] = parent.get_children(false) # not include_internal # Take a snapshot just in case, to avoid modifying an array while iterating over it
	var removalCount: int = 0

	for sibling: Node in children:
		if sibling == node: continue # Is it us?

		var isSameType: bool = false

		# CHECK: Does this work in all cases?
		if nodeScript: isSameType = sibling.get_script() == nodeScript # Do we have the same script?
		else: isSameType = sibling.get_class() == nodeClass # Otherwise compare the class

		if isSameType:
			parent.remove_child(sibling)
			if shouldFree: sibling.queue_free()
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
				Debug.printWarning(str("reparentNodes(): ", node, " could not be moved from ", currentParent, " to newParent: ", newParent), node)
				continue
		else:
			Debug.printWarning(str("reparentNodes(): ", node, " does not belong to currentParent: ", currentParent), node)
			continue
	return transferredNodes

#endregion


#region Position

## Returns a copy of a [Rect2] transformed from a node's local coordinates to the global position.
## TIP: PERFORMANCE: This function may be replaced with `Rect2(rect.position + node.global_position, rect.size)` to avoid an extra call.
## TIP: Combine with the output from [member getShapeBoundsInNode] to get an [Area2D]'s global region.
## WARNING: May not work correctly with rotation, scaling or negative dimensions.
static func convertNodeRectToGlobalCoordinates(node: Node2D, rect: Rect2) -> Rect2:
	# TODO: Account for rotation
	return Rect2(node.to_global(rect.position), rect.size * node.global_scale)


## Returns the specified "design size" centered on a Node's Viewport.
## NOTE: The viewport size may different from the scaled screen/window size.
static func getCenteredPositionOnViewport(node: Node2D, designWidth: float, designHeight: float) -> Vector2:
	# TBD: Better name?
	# The "design size" has to be specified because it's hard to get the actual size, accounting for scaling etc.
	var viewport: Rect2		= node.get_viewport_rect() # First see what the viewport size is
	var center: Vector2		= Vector2(viewport.size.x / 2.0, viewport.size.y / 2.0) # Get the viewport center
	var designSize: Vector2	= Vector2(designWidth, designHeight) # Get the node design size
	return center - (designSize / 2.0) # Center the size on the viewport


## Searches a group of nodes and returns the node nearest to the specified reference position.
## Compares the [member Node2D.global_position]s.
## TIP: May be used to find the closest player for monsters to chase, or the nearest mosnter for a homing missile weapon to attack, etc.
static func findNearestNodeInGroup(referencePosition: Vector2, targetGroup: StringName) -> Node2D:
	# TBD: Should we have a [Node2D] parameter?
	# NOTE: Use Engine.get_main_loop() instead of Node.get_tree()
	# because when called by ChaseComponent etc. the parent entity may not be in a SceneTree yet
	var nodesInGroup: Array[Node] = Engine.get_main_loop().get_nodes_in_group(targetGroup) # TBD: Verify that the `MainLoop` is a `SceneTree`?
	if  nodesInGroup.is_empty(): return null

	var nearestNode:		Node2D  = null
	var minimumDistance:	float   = INF # Start with infinity
	var checkingDistance:	float

	for nodeToCheck in nodesInGroup:
		if nodeToCheck is not Node2D: continue
		
		checkingDistance = referencePosition.distance_squared_to(nodeToCheck.global_position) # PERFORMANCE: distance_squared_to() is faster than distance_to()
		if is_zero_approx(checkingDistance):
			return nodeToCheck # Can't get any closer than 0! Just return the node being checked; no need to update `nearestNode`
		elif checkingDistance < minimumDistance:
			minimumDistance   = checkingDistance
			nearestNode		  = nodeToCheck

	return nearestNode


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

#endregion


#region Copy

## NOTE: Does NOT add the new copy to the original node's parent. Follow up with [method NodeTools.addChildAndSetOwner].
## Default flags: DUPLICATE_SIGNALS + DUPLICATE_GROUPS + DUPLICATE_SCRIPTS + DUPLICATE_USE_INSTANTIATION
static func createScaledCopy(nodeToDuplicate: Node2D, copyScale: Vector2, flags: int = 15) -> Node2D:
	var scaledCopy: Node2D = nodeToDuplicate.duplicate(flags)
	scaledCopy.scale = copyScale
	return scaledCopy

#endregion
