## Helper functions to assist with common tasks involving [TileMap], [TileMapLayer] or [TileMapCellData]

class_name TileMapTools
extends GDScript # NOTE: DESIGN: We cannot `extends TileMapLayer` because we want these functions to be globally available, not just for instances of a special subclass.


#region Coordinates & Position 

static func getCellGlobalPosition(map: TileMapLayer, coordinates: Vector2i) -> Vector2:
	var cellPosition:		Vector2 = map.map_to_local(coordinates)
	var cellGlobalPosition:	Vector2 = map.to_global(cellPosition)
	return cellGlobalPosition


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
	return TileMapTools.getTileMapScreenBounds(map).has_point(point)


## Checks if a [Rect2]'s [member Rect2.position] origin and/or [member Rect2.end] points are inside a [TileMapLayer].
## If [param checkOriginAndEnd] is `true` (default) then this method returns `true` only if the rectangle's origin AND end are BOTH fully inside the TileMap.
## If [param checkOriginAndEnd] is `false` then even a partial intersection returns `true`.
## IMPORTANT: The [param rectangle] must be in the coordinate space of the [param map]'s parent node. See [method Node2D.to_local].
## NOTE: Rotation and other transforms are NOT supported.
## WARNING: Internal float-based positions may have fractional values like 0.5 etc. which may cause calculations to return a result that does not match the visuals onscreen, e.g. intersections may return false.
static func isRectInTileMap(rectangle: Rect2, map: TileMapLayer, checkOriginAndEnd: bool = true) -> bool:
	var tileMapBounds: Rect2 = TileMapTools.getTileMapScreenBounds(map)
	return tileMapBounds.encloses(rectangle) if checkOriginAndEnd else rectangle.intersects(tileMapBounds)


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

	Debug.printDebug(str("TileMapTools.convertCoordinatesBetweenTileMaps() ", sourceMap, " @", cellCoordinatesInSourceMap, " → sourcePixel: ", pixelPositionInSourceMap, " → globalPixel: ", globalPosition, " → destinationPixel: ", pixelPositionInDestinationMap, " → @", cellCoordinatesInDestinationMap, " ", destinationMap))
	return cellCoordinatesInDestinationMap

#endregion


#region Data

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

#endregion


#region Occupancy

## Uses a custom data structure to mark individual [TileMap] cells (not tiles) as occupied or unoccupied by an [Entity].
static func setCellOccupancy(data: TileMapCellData, coordinates: Vector2i, isOccupied: bool, occupant: Entity) -> void:
	data.setCellData(coordinates, Global.TileMapCustomData.isOccupied, isOccupied) # NOTE: Do NOT delete this key, because a MISSING key is assumed to be a vacant cell!
	data.setCellData(coordinates, Global.TileMapCustomData.occupant, occupant if isOccupied else null) # PERFORMANCE: Not using TileMapCellData.eraseCellData() so we can avoid allocation churn


static func checkTileAndCellVacancy(map: TileMapLayer, data: TileMapCellData, coordinates: Vector2i, ignoreEntity: Entity) -> bool:
	# CHECK: First check the CELL data because it's quicker, right?
	var isCellVacant: bool = TileMapTools.checkCellVacancy(data, coordinates, ignoreEntity)
	if not isCellVacant: return false # If there is an occupant, no need to check the Tile data, just scram

	# Then check the TILE data
	var isTileVacant: bool = TileMapTools.checkTileVacancy(map, coordinates)

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
	isTileVacant = (isWalkable or isWalkable == null) and (not isBlocked or isBlocked == null)

	return isTileVacant


## Checks if the specified tile is vacant by examining the custom tile/cell data for flags such as [constant Global.TileMapCustomData.isWalkable].
static func checkCellVacancy(mapData: TileMapCellData, coordinates: Vector2i, ignoreEntity: Entity) -> bool:
	var isCellVacant: bool = false

	# First check the CELL data because it's quicker

	# Make sure the `isOccupied` flag exists
	if not mapData.hasCellData(coordinates, Global.TileMapCustomData.isOccupied):
		return true # If there is no such flag at all, `true` OR `false`, just assume that this map doesn't support occupancy, and report it as a vacant space.

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

#endregion


#region Physics

## Checks for a collision between a [TileMapLayer] and physics body at the specified tile coordinates.
## ALERT: UNIMPLEMENTED: Will ALWAYS return `true`. Currently there seems to be no way to easily check this in Godot yet.
## @experimental
static func checkTileCollision(map: TileMapLayer, _body: PhysicsBody2D, _coordinates: Vector2i) -> bool:
	# If the TileMap or its collisions are disabled, then the tile is always available.
	if not map.enabled or not map.collision_enabled: return true
	return true # HACK: TODO: Implement

#endregion


#region Randomization

## Returns an array of random coordinates on a [TileMapLayer] from the specified grid range.
## WARNING: Do NOT use [method TileMapLayer.get_used_rect()] [member Rect2i.size] or [member Rect2i.end] as it is NOT 0-based: It will be +1 outside the map's actual grid! TIP: Use [method Rect2i.grow](-1)
static func findRandomTileMapCells(
	map:				TileMapLayer,
	selectionChance:	float = 1.0,
	includeUsedCells:	bool  = true,
	includeEmptyCells:	bool  = true,
	cellRegionStart:	Vector2i = map.get_used_rect().position,
	cellRegionEnd:		Vector2i = map.get_used_rect().grow(-1).end # Make `end` 0-based
) -> Array[Vector2i]:

	# TODO: Validate parameters and sizes
	# TODO: PERFORMANCE: Using `map.get_used_rect()` twice for default arguments is a bit jank
	# NOTE: Rect2i parameters are less intuitive because it uses width/height parameters for initialization, not direct end coordinates.

	if (not includeUsedCells and not includeEmptyCells) \
	or is_zero_approx(selectionChance) or selectionChance < 0 \
	or cellRegionEnd < cellRegionStart:
		return []

	var coordinates: Vector2i
	var isCellEmpty: bool
	var randomCells: Array[Vector2i]

	# CHECK: PERFORMANCE: What's faster? TileMapLayer.get_used_cells() & then filtering,
	# or building the list manually by iterating every cell?

	# NOTE: +1 to range() end to make the bounds inclusive
	for y in range(cellRegionStart.y, cellRegionEnd.y + 1):
		for x in range(cellRegionStart.x, cellRegionEnd.x + 1):

			# PERFORMANCE: Roll the chance before doing all the other checks and calculations
			if selectionChance < 1.0 and not randf() < selectionChance: continue # TBD: Should this be an integer?

			coordinates = Vector2i(x, y)

			# A cell is considered "empty" if its source & alternative identifiers are -1, and its atlas coordinates are (-1,-1).
			# TBD: PERFORMANCE: Do we need to check ALL 3?
			isCellEmpty = map.get_cell_source_id(coordinates)  == -1 \
				and map.get_cell_alternative_tile(coordinates) == -1 \
				and map.get_cell_atlas_coords(coordinates) == Vector2i(-1, -1)

			if (includeUsedCells  and not isCellEmpty) \
			or (includeEmptyCells and isCellEmpty):
				randomCells.append(Vector2i(x, y))

	return randomCells


## "Repaints" all the specified cell coordinates in a [TileMapLayer] with random tiles from the specified range in the Map's [TileSet] atlas.
## TIP: Call [method findRandomTileMapCells] to build an array of random cells.
## NOTE: If [member atlasSourceID] is set to -1, or [member atlasCoordinatesMin] & [member atlasCoordinatesMax] are BOTH set to -1 & -1, the cells will be ERASED.
static func randomizeTileMapCells(
	map:				 TileMapLayer,
	cellsToRepaint:		 Array[Vector2i], # TBD: PERFORMANCE: Use `PackedVector2Array`?
	atlasCoordinatesMin: Vector2i,
	atlasCoordinatesMax: Vector2i,
	atlasSourceID:		 int = 0) -> void:
	
	# TODO: Validate atlas sizes
	# NOTE: Rect2i parameters are less intuitive because it uses width/height parameters for initialization, not direct end coordinates.
	# TBD:  PERFORMANCE: Add a separate modificationChance for extra control or is findRandomTileMapCells()'s selectionChance enough?

	if not map \
	or cellsToRepaint.is_empty() \
	or atlasCoordinatesMax < atlasCoordinatesMin:
		return

	var randomTile:  Vector2i

	for cellCoordinates in cellsToRepaint:
		randomTile = Vector2i(
			randi_range(atlasCoordinatesMin.x, atlasCoordinatesMax.x),
			randi_range(atlasCoordinatesMin.y, atlasCoordinatesMax.y))
		map.set_cell(cellCoordinates, atlasSourceID, randomTile)

#endregion


#region Spawn

## Creates instance copies of a specified Scene and positions them over a [TileMapLayer]'s cells, each at a unique position in the grid.
## Returns a [Dictionary] of the nodes that were created, with their cell coordinates as the keys.
## TIP: To spawn scenes at specific cell coordinates, call [method TileMapTools.populateTileMapCells]
static func populateTileMap(map: TileMapLayer, sceneToCopy: PackedScene, numberOfCopies: int, parentOverride: Node2D = null, groupToAddTo: StringName = &"") -> Dictionary[Vector2i, Node2D]:
	# TODO: FIXME: Handle negative cell coordinates
	# TBD: Allow non-Node2D `parentOverride`?
	# TBD: Add option for range of allowed cell coordinates instead of using the entire TileMap?

	# Validation

	if not sceneToCopy:
		Debug.printWarning("TileMapTools.populateTileMap(): No sceneToCopy", str(map))
		return {}

	var mapRect: Rect2i = map.get_used_rect()

	if not mapRect.has_area():
		Debug.printWarning(str("TileMapTools.populateTileMap(): map has no area: ", mapRect.size), str(map))
		return {}

	var totalCells: int = mapRect.size.x * mapRect.size.y

	if numberOfCopies > totalCells:
		Debug.printWarning(str("TileMapTools.populateTileMap(): numberOfCopies: ", numberOfCopies, " > totalCells: ", totalCells), str(map))
		return {}

	# Spawn

	var parent:  Node2D = parentOverride if parentOverride else map
	var newNode: Node2D

	var minCoordinates: Vector2i = mapRect.position
	var maxCoordinates: Vector2i = mapRect.end - Vector2i.ONE
	var coordinates:  Vector2i
	var nodesSpawned: Dictionary[Vector2i, Node2D]

	for count in numberOfCopies:
		newNode = sceneToCopy.instantiate()

		# Find a unoccupied cell
		# Rect size = 1 if 1 cell, so subtract - 1
		# TBD: A more efficient way?

		coordinates = Vector2i(
			randi_range(minCoordinates.x, maxCoordinates.x),
			randi_range(minCoordinates.y, maxCoordinates.y))

		# NOTE: No chance of an infinite loop because we checked numberOfCopies <= totalCells
		while(nodesSpawned.get(coordinates)):
			coordinates = Vector2i(
				randi_range(minCoordinates.x, maxCoordinates.x),
				randi_range(minCoordinates.y, maxCoordinates.y))

		# Position

		if parent == map:
			newNode.position = map.map_to_local(coordinates)
		else:
			newNode.position = parent.to_local(
				map.to_global(
					map.map_to_local(coordinates)))

		if newNode is Entity and newNode.getComponent(TileBasedPositionComponent):
			newNode.components.TileBasedPositionComponent.currentCoordinates = coordinates

		# Add
		NodeTools.addChildAndSetOwner(newNode, parent)
		if not groupToAddTo.is_empty(): newNode.add_to_group(groupToAddTo, true) # persistent
		nodesSpawned[coordinates] = newNode

	return nodesSpawned


## Creates instance copies of a specified Scene over a list of cells on a [TileMapLayer]'s grid.
## Returns a [Dictionary] of the nodes that were created, with their cell coordinates as the keys.
## TIP: Call [method TileMapTools.findRandomTileMapCells] to get an array of random cells.
## TIP: To spawn scenes at random coordinates all over the map with a fixed number of copies, call [method TileMapTools.populateTileMap]
## NOTE: If [param cellCoordinates] contains duplicate coordinates, only 1 copy is created per coordinate,
## but the effective [param spawnChance] will be higher for duplicate coordinates!
static func populateTileMapCells(
	map:			TileMapLayer,
	cellCoordinates:Array[Vector2i],
	sceneToCopy:	PackedScene,
	maximumNumberOfCopies: int,
	spawnChance:	float 		= 1.0,
	parentOverride:	Node2D		= null,
	groupToAddTo:	StringName	= &"") -> Dictionary[Vector2i, Node2D]:

	# Validation

	if maximumNumberOfCopies < 1: return {}

	if not sceneToCopy:
		Debug.printWarning("TileMapTools.populateTileMapCells(): No sceneToCopy", str(map))
		return {}

	if cellCoordinates.is_empty():
		Debug.printWarning("TileMapTools.populateTileMapCells(): No cellCoordinates!", str(map))
		return {}

	if is_zero_approx(spawnChance) or spawnChance < 0:
		Debug.printWarning(str("TileMapTools.populateTileMapCells(): spawnChance <= 0: ", spawnChance), str(map))
		return {}

	# Spawn

	var parent:  Node2D = parentOverride if parentOverride else map
	var newNode: Node2D
	var nodesSpawned: Dictionary[Vector2i, Node2D]

	for coordinates in cellCoordinates:
		# maximumNumberOfCopies == 0 is guarded at the top of the function, so we'll recheck it at the end of this loop

		# Did we already spawn a node at the same coordinates?
		if nodesSpawned.has(coordinates):
			var existingNode := nodesSpawned[coordinates]
			# Is the node still valid?
			if is_instance_valid(existingNode):
				# Warn if the `cellCoordinates` array has duplicate items
				Debug.printWarning(str("TileMapTools.populateTileMapCells(): Node already spawned @", coordinates, ": ", nodesSpawned[coordinates]), str(map))
				# TBD: Allow multiple copies at the same coordinates? But that would make the return Dictionary omit duplicates..
				# NOTE: BUGRISK: The effective `spawnChance` will be higher for duplicate coordinates!
				continue
			else: # If the node is no longer valid, just remove the coordinates from the "already spawned" list and spawn again
				nodesSpawned.erase(coordinates)

		# PERFORMANCE: Roll the chance before doing all the other checks and calculations
		if spawnChance < 1.0 and not randf() < spawnChance: continue # TBD: Should this be an integer?

		newNode = sceneToCopy.instantiate()

		# Position

		if parent == map:
			newNode.position = map.map_to_local(coordinates)
		else:
			newNode.position = parent.to_local(
				map.to_global(
					map.map_to_local(coordinates)))

		if newNode is Entity and newNode.getComponent(TileBasedPositionComponent):
			newNode.components.TileBasedPositionComponent.currentCoordinates = coordinates

		# Add
		NodeTools.addChildAndSetOwner(newNode, parent)
		if not groupToAddTo.is_empty(): newNode.add_to_group(groupToAddTo, true) # persistent
		nodesSpawned[coordinates] = newNode

		if nodesSpawned.size() >= maximumNumberOfCopies: break

	return nodesSpawned

#endregion


#region Descructibility

## Damages a [TileMapLayer] Cell if it is [member Global.TileMapCustomData.isDestructible].
## Changes the cell's tile to the [member Global.TileMapCustomData.nextTileOnDamage] if there is any,
## or erases the cell if there is no "next tile" specified or either of the X or Y coordinates are below 0 i.e. (-1,-1)
## Returns `true` if the cell was damaged.
## NOTE: If [member atlasSourceID] is set to -1, cells will ALWAYS be ERASED.
## @experimental
static func damageTileMapCell(map: TileMapLayer, coordinates: Vector2i, atlasSourceID: int = 0) -> bool:
	# TODO: Variable health & damage
	# PERFORMANCE: Do not call TileMapTools.getTileData() to reduce calls
	var tileData: TileData = map.get_cell_tile_data(coordinates)
	if  tileData:
		var isDestructible: bool = tileData.get_custom_data(Global.TileMapCustomData.isDestructible)
		if  isDestructible:
			var shouldEraseCell: bool = false

			if tileData.has_custom_data(Global.TileMapCustomData.nextTileOnDamage):
				var nextTileOnDamage: Vector2i = tileData.get_custom_data(Global.TileMapCustomData.nextTileOnDamage)
				if  nextTileOnDamage.x >= 0 and nextTileOnDamage.y >= 0: # If either atlas coordinates are negative it means "destroy on damage"
					map.set_cell(coordinates, atlasSourceID, nextTileOnDamage)
				else: shouldEraseCell = true # Destroy if any of the coordinates is invalid

			else: shouldEraseCell = true # Destroy if there is no `nextTileOnDamage`

			if shouldEraseCell:
				map.erase_cell(coordinates)

			return true
	# else
	return false

#endregion
