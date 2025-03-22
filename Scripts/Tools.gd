## Helper functions for built-in Godot nodes and types to assist with common tasks.
## Most of this is stuff that should be built-in Godot but isn't :')
## and can't be injected into the base types such as Node etc. :(

class_name Tools
extends GDScript



#region Constants

class CompassDirections: ## A list of unit vectors representing 8 compass directions.
	# TBD: Should this be in `Tools.gd` or in `Global.gd`? :')
	const none		:= Vector2i.ZERO
	const northWest	:= Vector2i(-1, -1)
	const north		:= Vector2i.UP
	const northEast	:= Vector2i(+1, -1)
	const east		:= Vector2i.RIGHT
	const southEast	:= Vector2i(+1, +1)
	const south		:= Vector2i.DOWN
	const southWest	:= Vector2i(-1, +1)
	const west		:= Vector2i.LEFT

#endregion


#region Scene Management
# See SceneManager.gd
#endregion


#region Node Management

## Calls [param parent].[method Node.add_child] and sets the [param child].[member Node.owner].
## This is necessary for persistence to a [PackedScene] for save/load.
## Also sets the `force_readable_name` parameter.
static func addChildAndSetOwner(child: Node, parent: Node) -> void: # DESIGN: TBD: Should `parent` be the 1st argument or 2nd? All global functions operate on the 1st argument, the parent [Node], but this method's name has "child" as the first word, so the `child` should be the 1st argument, right? :')
	parent.add_child(child, true) # force_readable_name
	child.owner = parent


## Returns the first child of [param parentNode] which matches the specified [param type].
## If [param includeParent] is `true` (default) then the [param parentNode] ITSELF may be returned if it is node of a matching type. This may be useful for [Sprite2D] or [Area2D] etc. nodes with the `Entity.gd` script.
static func findFirstChildOfType(parentNode: Node, type: Variant, includeParent: bool = true) -> Node:
	if includeParent and is_instance_of(parentNode, type):
		return parentNode

	var children: Array[Node] = parentNode.get_children()
	for child in children:
		if is_instance_of(child, type): return child # break
	#else
	return null


## Calls [method Tools.findFirstChildOfType] to return the first child of [param parentNode] which matches ANY of the specified [param types]  (searched in the array order).
## If [param includeParent] is `true` (default) then the [param parentNode] ITSELF is returned AFTER none of the requested types are found.
## This may be useful for choosing certain child nodes of an entity to operate on, like an [AnimatedSprite2D] or [Sprite2D] to animate, otherwise operate on the entity itself.
## PERFORMANCE: Should be the same as multiple calls to [method Tools.findFirstChildOfType] in order of the desired types.
static func findFirstChildOfAnyTypes(parentNode: Node, types: Array[Variant], returnParentIfNoMatches: bool = true) -> Node:
	# TBD: Better name
	# Nodes may be an instance of multiple inherited types, so check each of the requested types.
	# NOTE: Types must be the outer loop, so that when searching for [AnimatedSprite2D, Sprite2D], the first [AnimatedSprite2D] is returned.
	# If child nodes are the outer loop, then a [Sprite2D] might be returned if it is higher in the child tree than the [AnimatedSprite2D].
	for type: Variant in types:
		for child in parentNode.get_children():
			if is_instance_of(child, type): return child # break
	
	# Return the parent itself AFTER none of the requested types are found.
	# DESIGN: REASON: This may be useful for situations like choosing an [AnimatedSprite2D] or [Sprite2D] otherwise operate on the entity itself.
	return parentNode if returnParentIfNoMatches else null


## Searches up the tree until a matching parent or grandparent is found.
static func findFirstParentOfType(childNode: Node, type: Variant) -> Node:
	var parent: Node = childNode.get_parent() # parentOrGrandparent

	# If parent is null or not the matching type, get the grandparent (parent's parent) and keep searching up the tree.
	while not (is_instance_of(parent, type)) and not (parent == null):
		parent = parent.get_parent()

	return parent


## Replaces a child node with another node at the same index (order).
## NOTE: The child and its sub-children are NOT deleted. To delete a child, use [method Node.queue_free].
## Returns: `true` if [param childToReplace] was found and replaced.
static func replaceChild(parentNode: Node, childToReplace: Node, newChild: Node) -> bool:
	if childToReplace.get_parent() != parentNode:
		Debug.printWarning(str("replaceChild() childToReplace.get_parent(): ", childToReplace.get_parent(), " != parentNode: ", parentNode))
		return false

	# Is the new child already in another parent?
	# TODO: Option to remove new child from existing parent
	var newChildCurrentParent: Node = newChild.get_parent()
	if newChildCurrentParent != null and newChildCurrentParent != parentNode:
		Debug.printWarning("replaceChild(): newChild already in another parent: " + str(newChild, " in ", newChildCurrentParent))
		return false

	var previousChildIndex: int = childToReplace.get_index() # The original index
	parentNode.remove_child(childToReplace)

	Tools.addChildAndSetOwner(newChild, parentNode) # Ensure persistence
	parentNode.move_child(newChild, previousChildIndex)
	newChild.owner = parentNode # INFO: Necessary for persistence to a [PackedScene] for save/load.

	return true


## Removes the first child of the [param parentNode], if any, and adds the specified [param newChild].
## NOTE: The child and its sub-children are NOT deleted. To delete a child, use [method Node.queue_free].
static func replaceFirstChild(parentNode: Node, newChild: Node) -> void:
	var childToReplace: Control = parentNode.findFirstChildControl()
	# Debug.printDebug(str("replaceFirstChildControl(): ", childToReplace, " → ", newChild), parentNode)

	if childToReplace:
		Tools.replaceChild(parentNode, childToReplace, newChild)
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


## Convert a path from the `./` form to the absolute representation: `/root/` INCLUDING the property path if any.
static func convertRelativePathToAbsolute(parentNodeToConvertFrom: Node, relativePath: NodePath) -> NodePath:
	var absoluteNodePath: String = parentNodeToConvertFrom.get_node(relativePath).get_path()
	var propertyPath: String = str(":", relativePath.get_concatenated_subnames())
	var absolutePathIncludingProperty: NodePath = NodePath(str(absoluteNodePath, propertyPath))

	# DEBUG:
	#Debug.printLog(str("Tools.convertRelativePathToAbsolute() parentNodeToConvertFrom: ", parentNodeToConvertFrom, \
		#", relativePath: ", relativePath, \
		#", absoluteNodePath: ", absoluteNodePath, \
		#", propertyPath: ", propertyPath))

	return absolutePathIncludingProperty


static func splitPathIntoNodeAndProperty(path: NodePath) -> Array[NodePath]:
	var nodePath: NodePath
	var propertyPath: NodePath

	nodePath = NodePath(str("/" if path.is_absolute() else "", path.get_concatenated_names()))
	propertyPath = NodePath(str(":", path.get_concatenated_subnames()))

	return [nodePath, propertyPath]

#endregion


#region Area & Shape Functions

## Returns a rectangle representing the bounds of an [Area2D]'s first [CollisionShape2D] child.
## NOTE: The rectangle is in the coordinates of the [CollisionShape2D].
## Works best with areas with a single rectangle shape.
## Returns: On failure: a rectangle with size -1
static func getShapeBounds(area: Area2D) -> Rect2:
	# HACK: Sigh @ Godot for making this so hard...

	# Find a CollisionShape2D child.

	var shapeNode: CollisionShape2D = findFirstChildOfType(area, CollisionShape2D)

	if not shapeNode:
		Debug.printWarning("getShapeBounds(): Cannot find a CollisionShape2D child", str(area))
		return Rect2(area.position.x, area.position.y, -1, -1) # Return a invalid negative-sized rectangle matching the area's origin.

	var shape: Shape2D = shapeNode.shape
	var shapeBounds: Rect2 = shape.get_rect()

	return shapeBounds


## Returns a rectangle representing the bounds of an [Area2D]'s first [CollisionShape2D] child.
## NOTE: The rectangle is in the coordinates of the [Area2D].
## Works best with areas with a single rectangle shape.
## Returns: On failure: a rectangle with size -1
static func getShapeBoundsInArea(area: Area2D) -> Rect2:
	# TODO: More accuracy within all sorts of shapes
	# TODO: Find a more elegant and efficient way :')
	# HACK: Sigh @ Godot for making this so hard...

	# INFO: Overview: An [Area2D] has a [CollisionShape2D] child [Node], which in turn has a [Shape2D] [Resource].
	# In the parent Area2D, the CollisionShape2D's "anchor point" is at the top-left corner, so its `position` may be 0,0.
	# But inside the CollisionShape2D, the Shape2D's anchor point is at the center of the shape, so its `position` may be 16,16 for a rectangle of 32x32.
	# SO, we have to figure out the Shape2D's rectangle in the coordinate space of the Area2D.
	# THEN convert it to global coordinates.

	# First, find a CollisionShape2D child.

	var shapeNode: CollisionShape2D = findFirstChildOfType(area, CollisionShape2D)

	if not shapeNode:
		Debug.printWarning("getShapeBoundsInArea(): Cannot find a CollisionShape2D child", str(area))
		return Rect2(area.position.x, area.position.y, -1, -1) # Return a invalid negative-sized rectangle matching the area's origin.

	# Make local copies of the frequently used stuff.

	var _shapeNodePositionInArea := shapeNode.position
	var shape: Shape2D = shapeNode.shape

	# The bounding rectangle of the shape. NOTE: In the coordinates of the CollisionShape2D node!
	var shapeBoundingRect: Rect2 = shape.get_rect() # TBD: Should we use `extents`? It seems to be half of the size, but it seems to be a hidden property [as of 4.3 Dev 3].

	# Because a [CollisionShape2D]'s anchor is at its center,
	# we have to get it's top-left corner,
	# by subtracting HALF the size of the actual SHAPE:

	var shapeNodeTopLeftCorner := Vector2( \
		shapeNode.position.x - shapeBoundingRect.size.x / 2, \
		shapeNode.position.y - shapeBoundingRect.size.y / 2)

	var shapeBoundsInArea := Rect2( \
		shapeNodeTopLeftCorner.x, shapeNodeTopLeftCorner.y, \
		shapeBoundingRect.size.x, shapeBoundingRect.size.y)

	#var shapeGlobalOrigin: Vector2 = shapeNode.global_position - shapeNode.shape.extents # NOTE: CHECK: `extents` seems to be the distance of the edge from the origin (center in this case), but it seems to be a hidden property?

	return shapeBoundsInArea


static func getShapeGlobalBounds(area: Area2D) -> Rect2:
	var shapeGlobalBounds := getShapeBoundsInArea(area)
	shapeGlobalBounds.position = area.to_global(shapeGlobalBounds.position)
	return shapeGlobalBounds


static func getRandomPositionInArea(area: Area2D) -> Vector2:

	var areaBounds: Rect2 = getShapeBoundsInArea(area)

	# Generate a random position within the area.

	#var isWithinArea := false
	#while not isWithinArea:

	#randomize() # TBD: Do we need this?

	var x: float = randf_range(areaBounds.position.x, areaBounds.end.x)
	var y: float = randf_range(areaBounds.position.y, areaBounds.end.y)
	var randomPosition: Vector2 = Vector2(x, y)

	#if shouldVerifyWithinArea: isWithinArea = ... # TODO: Cannot check if a point is within an area :( [as of 4.3 Dev 3]
	#else: isWithinArea = true

	#Debug.printDebug(str("area: ", area, ", areaBounds: ", areaBounds, ", randomPosition: ", randomPosition))

	return randomPosition

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


## Returns the [Shape2D] from a [CollisionObject2D]-based node (such as [Area2D]) and a given "shape index"
## @experimental
static func getCollisionShape(node: CollisionObject2D, shapeIndex: int) -> Shape2D:
	# What is this hell...
	var areaShapeOwnerID: int = node.shape_find_owner(shapeIndex)
	# UNUSED: var areaShapeOwner: CollisionShape2D = node.shape_owner_get_owner(areaShapeOwnerID)
	return node.shape_owner_get_shape(areaShapeOwnerID, shapeIndex) # CHECK: Should it be `shapeIndex` or 0?

#endregion


#region Visual Functions

static func getRectCorner(rectangle: Rect2, compassDirection: Vector2i) -> Vector2:
	var position	:= rectangle.position
	var center		:= rectangle.get_center()
	var end			:= rectangle.end

	match compassDirection:
		CompassDirections.northWest:	return Vector2(position.x, position.y)
		CompassDirections.north:		return Vector2(center.x, position.y)
		CompassDirections.northEast:	return Vector2(end.x, position.y)
		CompassDirections.east:			return Vector2(end.x, center.y)
		CompassDirections.southEast:	return Vector2(end.x, end.y)
		CompassDirections.south:		return Vector2(center.x, end.y)
		CompassDirections.southWest:	return Vector2(position.x, end.y)
		CompassDirections.west:			return Vector2(position.x, center.y)

		_: return Vector2.ZERO


## Returns the specified "design size" centered on a Node's Viewport.
## NOTE: The viewport size may different from the scaled screen/window size.
static func getCenteredPositionOnViewport(node: Node2D, designWidth: float, designHeight: float) -> Vector2i:
	# TBD: Better name?
	# The "design size" has to be specified because it's hard to get the actual size, accounting for scaling etc.
	var viewport: Rect2		= node.get_viewport_rect() # First see what the viewport size is
	var center: Vector2		= Vector2(viewport.size.x / 2.0, viewport.size.y / 2.0) # Get the viewport center
	var designSize: Vector2	= Vector2(designWidth, designHeight) # Get the node design size
	return center - (designSize / 2.0) # Center the size on the viewport


static func addRandomDistance(position: Vector2, \
minimumDistance: Vector2, maximumDistance: Vector2, \
xScale: float = 1.0, yScale: float = 1.0) -> Vector2:

	var randomizedPosition := position
	randomizedPosition.x += randf_range(minimumDistance.x, maximumDistance.x) * xScale
	randomizedPosition.y += randf_range(minimumDistance.y, maximumDistance.y) * yScale
	return randomizedPosition

## Returns the global position of the top-left corner of the screen in the camera's view.
static func getScreenTopLeftInCamera(camera: Camera2D) -> Vector2:
	var cameraCenter := camera.get_screen_center_position()
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


## Sets custom data for an individual cell of a [TileMapLayerWithCustomCellData].
## NOTE: CELLS are different from TILES; A Tile is the resource used by a [TileSet] to paint multple cells of a [TileMapLayer.]
## DESIGN: This is a separate function on top of [TileMapLayerWithCustomCellData] because it may redirect to a native Godot feature in the future.
static func setCellData(map: TileMapLayerWithCustomCellData, coordinates: Vector2i, key: StringName, value: Variant) -> void:
	map.setCellData(coordinates, key, value)


## Gets custom data for an individual cell of a [TileMapLayerWithCustomCellData].
## NOTE: CELLS are different from TILES; A Tile is the resource used by a [TileSet] to paint multple cells of a [TileMapLayer.]
## DESIGN: This is a separate function on top of [TileMapLayerWithCustomCellData] because it may redirect to a native Godot feature in the future.
static func getCellData(map: TileMapLayerWithCustomCellData, coordinates: Vector2i, key: StringName) -> Variant:
	return map.getCellData(coordinates, key)


## Uses a custom data structure to mark individual [TileMap] cells (not tiles) as occupied or unoccupied by an [Entity].
static func setCellOccupancy(map: TileMapLayerWithCustomCellData, coordinates: Vector2i, isOccupied: bool, occupant: Entity) -> void:
	map.setCellData(coordinates, Global.TileMapCustomData.isOccupied, isOccupied)
	map.setCellData(coordinates, Global.TileMapCustomData.occupant, occupant if isOccupied else null)


## Checks if the specified tile is vacant by examining the custom tile/cell data for flags such as [const Global.TileMapCustomData.isWalkable].
static func checkTileVacancy(map: TileMapLayerWithCustomCellData, coordinates: Vector2i, ignoreEntity: Entity) -> bool:
	var isTileVacant: bool = false
	var isCellVacant: bool = false

	# First check the CELL data because it's quicker

	var cellDataOccupied: Variant = map.getCellData(coordinates, Global.TileMapCustomData.isOccupied) # NOTE: Should not be `bool` so it can be `null` if missing, NOT `false` if missing.
	var cellDataOccupant: Entity  = map.getCellData(coordinates, Global.TileMapCustomData.occupant)

	if map.debugMode: Debug.printDebug(str("checkTileVacancy() ", map, " @", coordinates, " cellData[cellDataOccupied]: ", cellDataOccupied, ", occupant: ", cellDataOccupant))

	if cellDataOccupied is bool:
		isCellVacant = not cellDataOccupied or cellDataOccupant == ignoreEntity
	else:
		# If there is no data, assume the cell is always unoccupied.
		isCellVacant = true

	# If there is an occupant, no need to check the Tile data, just scram
	if not isCellVacant: return false

	# Then check the TILE data

	# NOTE: DESIGN: Missing values should be considered as `true` to assist with quick prototyping
	# TODO: Check all this in a more elegant way

	var tileData: 	TileData = map.get_cell_tile_data(coordinates)
	var isWalkable:	Variant
	var isBlocked:	Variant

	if tileData:
		isWalkable = tileData.get_custom_data(Global.TileMapCustomData.isWalkable)
		isBlocked  = tileData.get_custom_data(Global.TileMapCustomData.isBlocked)

	if map.debugMode: Debug.printDebug(str("tileData[isWalkable]: ", isWalkable, ", [isBlocked]: ", isBlocked))

	# If there is no data, assume the tile is always vacant.
	isTileVacant = (isWalkable or isWalkable == null) and (not isBlocked or isWalkable == null)

	return isTileVacant and isCellVacant


## Verifies that the given coordinates are within the specified [TileMapLayer]'s grid.
static func checkTileMapBounds(map: TileMapLayer, coordinates: Vector2i) -> bool:
	var mapRect: Rect2i = map.get_used_rect()
	return mapRect.has_point(coordinates)


## Checks for a collision between a [TileMapLayer] and physics body at the specified tile coordinates.
## ALERT: Will ALWAYS return `true`. Currently there seems to be no way to easily check this in Godot yet.
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
static func randomizeTileMapCells(map: TileMapLayer, cellRegionStart: Vector2i, cellRegionEnd: Vector2i, tileCoordinatesMin: Vector2i, tileCoordinatesMax: Vector2i, modificationChance: float) -> void:
	# TODO: Validate parameters and sizes
	
	var randomTile: Vector2i

	# NOTE: +1 to range() end to make the bounds inclusive
	for y in range(cellRegionStart.y, cellRegionEnd.y + 1):
		for x in range(cellRegionStart.x, cellRegionEnd.x + 1):
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

## Returns the variable name for an enum value.
## WARNING: May NOT work as expected for enums with non-sequential values or starting below 0, or if there are multiple identical values, or if there is a 'null' key.
static func getEnumText(enumType: Dictionary, value: int) -> String:
	var text: String

	text = str(enumType.find_key(value)) # TBD: Check for `null`?
	if text.is_empty(): text = "[invalid key/value]"

	return str(value, " (", text, ")")


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
## INFO: To "truncate" the number of decimal points, use Godot's [method @GlobalScope.snappedf] function.
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


## Connects or reconnects a [Signal] to a [Callable] only if the connection does not already exist, to silence any annoying Godot errors about existing connections (presumably for reference counting).
static func connectSignal(sourceSignal: Signal, targetCallable: Callable, flags: int = 0) -> int:
	if not sourceSignal.is_connected(targetCallable):
		return sourceSignal.connect(targetCallable, flags) # No idea what the return value is for.
	else:
		return 0


## Disconnects a [Signal] from a [Callable] only if the connection actually exists, to silence any annoying Godot errors about missing connections (presumably for reference counting).
static func disconnectSignal(sourceSignal: Signal, targetCallable: Callable) -> void:
	if sourceSignal.is_connected(targetCallable):
		sourceSignal.disconnect(targetCallable)


## Stops a [Timer] and emits its [signal Timer.timeout] signal.
## WARNING: This may cause bugs, especially when multiple objects are using `await` to wait for a Timer.
## Returns: The leftover time before the timer was stopped. WARNING: May not be accurate!
static func skipTimer(timer: Timer) -> float:
	# WARNING: This may not be accurate because the Timer is still running until the `stop()` call.
	var leftoverTime: float = timer.time_left
	timer.stop()
	timer.timeout.emit()
	return leftoverTime


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


## Returns a copy of a number wrapped around to the [param minimum] or [param maximum] value if it exceeds or goes below either limit (inclusive).
## May be used to cycle through a range by adding/subtracting an offset to [param current] such as +1 or -1. The number may be an array index or `enum` state, or a sprite position to wrap it around the screen Pac-Man-style.
static func wrapInteger(minimum: int, current: int, maximum: int) -> int:
	if minimum > maximum:
		Debug.printWarning(str("cycleInteger(): minimum ", minimum, " > maximum ", maximum, ", returning current: ", current))
		return current
	elif minimum == maximum: # If there is no difference between the range, just return either.
		return minimum

	# NOTE: Do NOT clamp first! So that an already-offset value may be provided for `current`

	# THANKS: rubenverg@Discord, lololol__@Discord
	return posmod(current - minimum, maximum - minimum + 1) + minimum # +1 to make limits inclusive

#endregion
