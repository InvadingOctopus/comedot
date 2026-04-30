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
## ALERT:  May not correspond to the visual position of a cell/tile, i.e. it ignores the [member TileData.texture_origin] property of individual tiles.
static func getTileMapScreenBounds(map: TileMapLayer) -> Rect2: # TBD: Rename to getTileMapBounds()?
	var cellGrid:	Rect2 = Rect2(map.get_used_rect()) # Convert integer `Rect2i` to float to simplify calculations
	if not cellGrid.has_area(): return Tools.rect2Zero # Null area if there are no cells
	var tileSize:	Vector2 = Vector2(map.tile_set.tile_size) # Convert integer `Vector2i` to float to simplify calculations
	return map.transform * Rect2(cellGrid.position * tileSize, cellGrid.size * tileSize).abs() # Apply all transforms including rotation etc.


## Checks if a [Vector2] is inside the rectangular bounds of a [TileMapLayer]'s "used" or "painted" cells.
## Handles scaling/rotation/etc., EXCEPT a 0 scale and other "non-invertible" transforms.
## IMPORTANT: The [param point] must be in the coordinate space of the [param map]'s parent node. See [method Node2D.to_local]
## ALERT: Empty cells between painted cells are considered inside the [TileMapLayer] bounds, e.g. if only 2 cells are painted at (0,0) & (99,99) then all the 100x100 empty cells in between are considered within the TileMap.
## WARNING: Internal float-based positions may have fractional values like 0.5 etc. which may cause calculations to return a result that does not match the visuals onscreen, e.g. intersections may return false.
static func isPointInTileMap(point: Vector2, map: TileMapLayer) -> bool:
	var pointInMap: Vector2 = map.transform.affine_inverse() * point   # Convert from the parent's space into the TileMapLayer's local space
	return map.get_used_rect().has_point(map.local_to_map(pointInMap)) # Convert local position to cell coordinates


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
	var pixelPositionInSourceMap:			Vector2  = sourceMap.map_to_local(cellCoordinatesInSourceMap)

	# 2: Convert the pixel position to the global space
	var globalPosition:						Vector2  = sourceMap.to_global(pixelPositionInSourceMap)

	# 3: Convert the global position to the destination TileMap's space
	var pixelPositionInDestinationMap:		Vector2  = destinationMap.to_local(globalPosition)

	# 4: Convert the pixel position to the destination map's cell coordinates
	# UNUSED: Return directly without creating another variable: var cellCoordinatesInDestinationMap:	Vector2i = destinationMap.local_to_map(pixelPositionInDestinationMap)

	# DEBUG: Disable for PERFORMANCE: Debug.printDebug(str("TileMapTools.convertCoordinatesBetweenTileMaps() ", sourceMap, " @", cellCoordinatesInSourceMap, " → sourcePixel: ", pixelPositionInSourceMap, " → globalPixel: ", globalPosition, " → destinationPixel: ", pixelPositionInDestinationMap, " → @", cellCoordinatesInDestinationMap, " ", destinationMap))
	return destinationMap.local_to_map(pixelPositionInDestinationMap) # cellCoordinatesInDestinationMap


## Returns an array of [Vector2i] cell coordinates on a [TileMapLayer] grid within the specified region.
## NOTE: If [param specifyRegion] is `false` then [param cellRegionStart] & [param cellRegionEnd] are ignored, and the entire grid containing all the "painted" cells of the TileMap is searched. NOTE: The painted region may NOT be the entire TileMap; e.g. if only (6,9) is the painted cell, only that 1 cell will be searched.
## NOTE: [param cellRegionEnd] is INCLUSIVE.
## WARNING: When filling out the [param cellRegionStart] or [param cellRegionEnd], Do NOT use [method TileMapLayer.get_used_rect] [member Rect2i.size] or [member Rect2i.end] as it is NOT 0-based: It will be +1 outside the map's actual grid! TIP: Use [method Rect2i.grow](-1)
## ALERT: In some cases, the cells may not be ordered from top-left to bottom-right, depending on the implementation of Godot's API.
## PERFORMANCE: If [param includeUsedCells] is `true` but [param includeEmptyCells] and [param specifyRegion] are both `false` then this method simply returns [method TileMapLayer.get_used_cells]
static func findTileMapCells(
	map:				TileMapLayer,
	includeUsedCells:	bool,
	includeEmptyCells:	bool,
	specifyRegion:		bool	 = false, # TODO: Find a better way to specify an optional region
	cellRegionStart:	Vector2i = Vector2i.ZERO,
	cellRegionEnd:		Vector2i = Vector2i.ZERO
) -> Array[Vector2i]:
	# NOTE: DESIGN: [Rect2i] parameters would be less intuitive because it uses width/height parameters for initialization, not explicit end coordinates.

	if (not includeUsedCells and not includeEmptyCells): return [] # If no cells are wanted, there's nothing to return!

	# If we just want all the "painted" cells, there's no need for any further processing; just use the builtin method
	if includeUsedCells and not includeEmptyCells and not specifyRegion:
		return map.get_used_cells()

	# Otherwise, decide the area we'll cover

	var area: Rect2i
	if  specifyRegion:
		area = Rect2i(cellRegionStart, cellRegionEnd - cellRegionStart + Vector2i.ONE) # +1 because Rect2i is EXCLUSIVE: It omits the last column/row
	else:
		area = map.get_used_rect()

	if not area.has_area(): return []

	# Collate the cells according to the flags

	var cells:			Array[Vector2i]
	var areaCellCount:	int = area.size.x * area.size.y
	var index:			int = 0 # IMPORTANT: Make sure index doesn't change from 0 before any of the loops below!

	# All cells in the region?
	if includeUsedCells and includeEmptyCells:
		cells.resize(areaCellCount) # PERFORMANCE: Resizing is faster than Array.append()
		# DESIGN: PERFORMANCE: It would be faster to call TileMapLayer.get_used_cells() first and then add the empty cells,
		# but we want the array to be in order, from top-left to bottom-right
		# Add all the cells within the range, in order
		for y in	 range(area.position.y, area.end.y):
			for x in range(area.position.x, area.end.x):
				cells[index] = Vector2i(x, y)
				index += 1

	# Only "painted" cells in the region?
	elif includeUsedCells and not includeEmptyCells:
		# PERFORMANCE: Array.append() in a loop is slower than Array.resize() then assigning by index
		# CHECK: Benchmark; is this implementation slower than just a single loop → append()?

		# So first we set the size to the maximum possible
		var usedCells: Array[Vector2i] = map.get_used_cells() # TBD: PERFORMANCE: If the get_used_cells() array is rebuilt whenever called (not cached), then calling this may defeat the optimization subbranch below
		var maxCount:  int = mini(usedCells.size(), areaCellCount) # Is the number of painted cells less than the total number of all cells within the area?
		cells.resize(maxCount)

		# Now filter and only include the painted cells that are within the area

		# PERFORMANCE: Handle cases where the `area` is tiny but the number of TileMapLayer.get_used_cells() is large,
		# because iterating the `area` directly might be faster than iterating over get_used_cells()
		# TBD: CHECK: Is the order always the same for get_used_cells()? Top-left to bottom-right?
		if areaCellCount < usedCells.size():
			var coordinates: Vector2i
			for y in	 range(area.position.y, area.end.y):
				for x in range(area.position.x, area.end.x):
					coordinates = Vector2i(x, y)
					if map.get_cell_source_id(coordinates) == -1: continue # Skip unpainted cells
					cells[index] = coordinates
					index += 1

		else: # areaCellCount >= usedCells.size()
			for coordinates in usedCells:
				if not area.has_point(coordinates): continue
				cells[index] = coordinates
				index += 1

		# Then shrink the array down to the actual number of painted cells that were within the area
		cells.resize(index)

	# Only the empty "unpainted" cells in the region?
	elif not includeUsedCells and includeEmptyCells:
		cells.resize(areaCellCount) # PERFORMANCE: Empty cells cannot exceed the total area anyway, so use the area as the array size first
		var coordinates: Vector2i
		for y in	 range(area.position.y, area.end.y):
			for x in range(area.position.x, area.end.x):
				coordinates = Vector2i(x, y)
				if map.get_cell_source_id(coordinates) != -1: continue # Skip painted cells
				cells[index] = coordinates
				index += 1
		cells.resize(index) # Shrink the array down to the actual number of unpainted cells that were within the area

	return cells

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

## Calls [method findTileMapCells] and returns shuffled [Vector2i] cell coordinates from a [TileMapLayer] grid, optionally filtered by [param selectionChance].
## NOTE: If [param specifyRegion] is `false` then [param cellRegionStart] & [param cellRegionEnd] are ignored, and the entire grid containing all the "painted" cells of the TileMap is searched. NOTE: The painted region may NOT be the entire TileMap; e.g. if only (6,9) is the painted cell, only that 1 cell will be searched.
## NOTE: [param cellRegionEnd] is INCLUSIVE.
## NOTE: If [param selectionChance] is `1.0` or higher, all matching cells are returned in random order.
## WARNING: When filling out the [param cellRegionStart] or [param cellRegionEnd], Do NOT use [method TileMapLayer.get_used_rect] [member Rect2i.size] or [member Rect2i.end] as it is NOT 0-based: It will be +1 outside the map's actual grid! TIP: Use [method Rect2i.grow](-1)
## TIP: Useful for randomizing terrain etc.
static func findRandomTileMapCells(
	map:				TileMapLayer,
	selectionChance:	float = 1.0,
	includeUsedCells:	bool  = true,
	includeEmptyCells:	bool  = true,
	specifyRegion:		bool  = false, # TODO: Find a better way to specify an optional region
	cellRegionStart:	Vector2i = Vector2i.ZERO,
	cellRegionEnd:		Vector2i = Vector2i.ZERO
) -> Array[Vector2i]:

	# If the chance is 0% we can't return anything!
	if selectionChance < 0 or is_zero_approx(selectionChance): return []

	var cells: Array[Vector2i] = TileMapTools.findTileMapCells(
		map, includeUsedCells, includeEmptyCells,
		specifyRegion, cellRegionStart, cellRegionEnd)

	# The shuffle() is important if downstream code caps results, such as populateTileMapCells(... maximumNumberOfCopies ...); otherwise selectionChance == 1.0 still returns a deterministic top-left-first list.
	cells.shuffle()

	# If the chance is 100% then just return all the cells
	if selectionChance > 1.0 or is_equal_approx(selectionChance, 1.0):
		return cells

	var randomCells:	 Array[Vector2i]
	var randomCellCount: int = 0

	# PERFORMANCE: Array.append() in a loop is slower than Array.resize() then assigning by index
	randomCells.resize(cells.size()) # Set to the maximum possible size, before filtering by chance

	for coordinates in cells:
		if randf() < selectionChance:
			randomCells[randomCellCount] = coordinates
			randomCellCount += 1

	randomCells.resize(randomCellCount) # Shrink the array down to the actual number of cells that were randomly selected
	return randomCells


## "Repaints" all the specified cell coordinates in a [TileMapLayer] with random tiles from the specified range in the Map's [TileSet] atlas.
## TIP: Call [method findRandomTileMapCells] to build an array of random cells.
## NOTE: If [member atlasSourceID] is set to -1, or [member atlasCoordinatesMin] & [member atlasCoordinatesMax] are BOTH set to (-1,-1), the cells will be ERASED.
static func randomizeTileMapCells(
	map:				 TileMapLayer,
	cellsToRepaint:		 Array[Vector2i], # TBD: PERFORMANCE: Use `PackedVector2Array`?
	atlasCoordinatesMin: Vector2i,
	atlasCoordinatesMax: Vector2i,
	atlasSourceID:		 int = 0) -> void:

	# TODO: Validate atlas sizes
	# NOTE: Rect2i parameters are less intuitive because it uses width/height parameters for initialization, not direct end coordinates.
	# TBD:  PERFORMANCE: Add a separate modificationChance for extra control or is findRandomTileMapCells()'s selectionChance enough?

	if not map or cellsToRepaint.is_empty(): return

	# If certain arguments are -1, erase all cells in the list
	var shouldEraseCells: bool = atlasSourceID == -1 \
		or (atlasCoordinatesMin == Vector2i(-1, -1)  \
		and atlasCoordinatesMax == Vector2i(-1, -1))

	if not shouldEraseCells \
	and (atlasCoordinatesMax.x < atlasCoordinatesMin.x \
	or   atlasCoordinatesMax.y < atlasCoordinatesMin.y): # FIXED: Compare x,y separately otherwise min:(0,10) < max:(1,2) will pass validation then potentially call randi_range(10, 2) for y, if just comparing the whole vectors
		return

	var randomTile:  Vector2i

	for cellCoordinates in cellsToRepaint:
		if shouldEraseCells:
			map.erase_cell(cellCoordinates)
			continue

		randomTile = Vector2i(
			randi_range(atlasCoordinatesMin.x, atlasCoordinatesMax.x),
			randi_range(atlasCoordinatesMin.y, atlasCoordinatesMax.y))
		map.set_cell(cellCoordinates, atlasSourceID, randomTile)

#endregion


#region Spawn

## Creates instances of a specified Scene and positions them over a [TileMapLayer]'s cells, each at a unique coordinate on the grid.
## Includes empty "unpainted" cells: e.g. if a TileMap has 1 painted cell at (0,0) and 1 at (99,99), the total area used for spawning is 100x100 cells.
## NOTE: If [param numberOfCopies] will be clamped if it's greater than the total number of cells in the [param map]
## RETURNS: A [Dictionary] of the nodes that were created, with their cell coordinates as the keys.
## TIP: To spawn scenes at a predetermined array of cell coordinates, call [method TileMapTools.populateTileMapCells]
static func populateTileMap(
	map:			TileMapLayer,
	sceneToCopy:	PackedScene,
	numberOfCopies:	int,
	parentOverride:	Node2D		= null,
	groupToAddTo:	StringName	= &""
) -> Dictionary[Vector2i, Node2D]:

	# TBD: Allow non-Node2D `parentOverride`?
	# TBD: PERFORMANCE: Is it necessary to return all the spawned nodes?
	# May be a waste of memory and processing if callers rarely use the nodes right after populating, e.g. just for random terrain/Entity generation.
	# TIP: If a caller needs to access the spawned nodes, it could just iterate on the `groupToAddTo`

	# Validation

	if numberOfCopies < 1: return {}

	if not sceneToCopy:
		Debug.printWarning("TileMapTools.populateTileMap(): No sceneToCopy", map)
		return {}

	var mapRect: Rect2i = map.get_used_rect()

	if not mapRect.has_area():
		Debug.printWarning(str("TileMapTools.populateTileMap(): map has no area: ", mapRect.size), map)
		return {}

	var totalCells: int = mapRect.size.x * mapRect.size.y

	if  numberOfCopies > totalCells: # Clamp; we can't spawn more copies than there are cells!
		Debug.printDebug(str("TileMapTools.populateTileMap(): numberOfCopies: ", numberOfCopies, " > totalCells: ", totalCells, " • Clamping"), map)
		numberOfCopies = totalCells

	# Spawn

	var parent:				Node2D = parentOverride if parentOverride else map
	var newNode:			Node2D
	var nodesSpawned:		Dictionary[Vector2i, Node2D]

	# Store indexes or "slots" for the Fisher-Yates algorithm (each step explained in the loop below)
	# Key:   Logical slot still available to roll
	# Value: Actual cell index represented by that slot
	var swappedCellIndices:	Dictionary[int, int]
	var selectedCellIndex:	int
	var cellIndex:			int
	var coordinates:		Vector2i
	var remainingCellCount:	int = totalCells

	for count in numberOfCopies:
		newNode = sceneToCopy.instantiate()

		# If the number of copies to spawn is less than the total number of cells, we need to choose random cells
		if numberOfCopies < totalCells:
			# 1: Find an unused cell.
			# PERFORMANCE: Use a "sparse" Fisher-Yates algorithm to pick unique random cells without retrying already selected cells.
			# and without allocating an Array containing every cell; which would reduce performance when used on large TileMaps.

			# 1.1: Roll one slot from the still available range.
			# Example: [A,B,C,D]: select B
			selectedCellIndex = randi_range(0, remainingCellCount - 1)

			# 1.2: Resolve that slot to the actual cell index.
			# Instead of using an Array of all coordinates or indices, assume that every slot points to itself unless `swappedCellIndices` says otherwise:
			# If the slot was never swapped (i.e. the key doesn't exist) then it represents itself.
			cellIndex = swappedCellIndices.get(selectedCellIndex, selectedCellIndex)

			# 1.3: Remove the selected slot by replacing it with the last available slot.
			# This is the same idea as swapping `selectedIndex` with the end of an array, then shrinking the array by 1.
			# Example: [A,D,C | B]: B selected & "removed" from the "pool" because the `remainingCellCount` is decreased
			# The Dictionary becomes: swappedCellIndices[1] = D
			remainingCellCount -= 1
			swappedCellIndices[selectedCellIndex] = swappedCellIndices.get(remainingCellCount, remainingCellCount)

			# 1.4: The old last slot is now outside the available range, so it can be forgotten.
			# Example: [A,D,C]
			swappedCellIndices.erase(remainingCellCount)

			# 1.5: Convert the flat cell index back into x/y offset inside the TileMap Rect.
			# Then convert the offset inside the used rectangle to actual TileMap coordinates.
			coordinates = mapRect.position + Vector2i(
				cellIndex % mapRect.size.x,
				cellIndex / mapRect.size.x) # CHECK: Should we use `floori(float(cellIndex) / mapRect.size.x)`? Is floori() the same as integer trunctation anyway? e.g. 5 / 2 == 2 instead of 2.5
			
			# 1.6: On the next pass, [A,D,C] → Select A, swap with C → [C,D | A,B] and so on...

		# If the number of copies is the same as the total number of cells, just choose all cells sequentially
		else:
			coordinates = mapRect.position + Vector2i(
				count % mapRect.size.x,
				count / mapRect.size.x) # TBD: Use floori() with `float` cast?

		# 2: Position the new node
		if parent == map:
			newNode.position = map.map_to_local(coordinates)
		else:
			newNode.position = parent.to_local(
				map.to_global(
					map.map_to_local(coordinates)))

		if newNode is Entity and newNode.getComponent(TileBasedPositionComponent):
			newNode.components.TileBasedPositionComponent.currentCoordinates = coordinates

		# 3: Add
		NodeTools.addChildAndSetOwner(newNode, parent)
		if not groupToAddTo.is_empty(): newNode.add_to_group(groupToAddTo, true) # persistent
		nodesSpawned[coordinates] = newNode

	return nodesSpawned


## Creates instance copies of a specified Scene over a list of cells on a [TileMapLayer]'s grid.
## Returns a [Dictionary] of the nodes that were created, with their cell coordinates as the keys.
## TIP: Call [method TileMapTools.findTileMapCells] or [method TileMapTools.findRandomTileMapCells] to build an array of cells.
## TIP: To spawn scenes at random coordinates all over the map with a fixed number of copies, call [method TileMapTools.populateTileMap]
## NOTE: If [param cellCoordinates] contains duplicate coordinates, only 1 copy is created per coordinate,
## but the effective [param spawnChance] will be higher for duplicate coordinates!
static func populateTileMapCells(
	map:			TileMapLayer,
	cellCoordinates:Array[Vector2i],
	sceneToCopy:	PackedScene,
	maximumNumberOfCopies: int,
	spawnChance:	float 		 = 1.0,
	parentOverride:	Node2D		= null,
	groupToAddTo:	StringName	= &""
) -> Dictionary[Vector2i, Node2D]:

	# TBD: PERFORMANCE: Is it necessary to return all the spawned nodes?
	# May be a waste of memory and processing if callers rarely use the nodes right after populating, e.g. just for random terrain/Entity generation.
	# TIP: If a caller needs to access the spawned nodes, it could just iterate on the `groupToAddTo`

	# Validation

	if maximumNumberOfCopies < 1: return {}

	if spawnChance < 0 or is_zero_approx(spawnChance):
		Debug.printDebug(str("TileMapTools.populateTileMapCells(): spawnChance <= 0: ", spawnChance), map)
		return {}

	if cellCoordinates.is_empty():
		Debug.printWarning("TileMapTools.populateTileMapCells(): No cellCoordinates!", map)
		return {}

	if not sceneToCopy:
		Debug.printWarning("TileMapTools.populateTileMapCells(): No sceneToCopy", map)
		return {}

	# Spawn

	var parent:  Node2D = parentOverride if parentOverride else map
	var newNode: Node2D
	var nodesSpawned: Dictionary[Vector2i, Node2D]

	for coordinates in cellCoordinates:
		# maximumNumberOfCopies == 0 is guarded at the top of the function, 
		# so at least 1 `spawnChance` roll has to be made anyway, and we'll recheck the number of spawns at the end of this loop

		# Did we already spawn a node at the same coordinates?
		if nodesSpawned.has(coordinates):
			var existingNode := nodesSpawned[coordinates]
			# Is the node still valid?
			if is_instance_valid(existingNode):
				# Warn if the `cellCoordinates` array has duplicate items
				Debug.printWarning(str("TileMapTools.populateTileMapCells(): Node already spawned @", coordinates, ": ", nodesSpawned[coordinates]), map)
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

			if atlasSourceID == -1: # If the caller REALLY wants to just erase the cell no matter what, there's nothing else to check
				map.erase_cell(coordinates)
				return true

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
