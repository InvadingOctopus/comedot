## Sets the position of the parent Entity to the position of a tile in an associated [TileMapLayer].
## NOTE: Does NOT receive player control input, or perform path-finding or any other validation logic
## except checking the tile map bounds and tile collision.
## TIP: To provide player input, use [TileBasedControlComponent].
## Requirements: [TileMapLayerWithCellData] or separate [TileMapLayer] + [TileMapCellData]

class_name TileBasedPositionComponent
extends Component

# PLAN:
# * Store integer coordinates to remember which tile the entity is in.
# * Every frame,
# 	If the entity is not moving to another tile, snap the entity to the current tile's position, in case the TileMap is moving.
# 	If the entity is moving to another tile, interpolate the entity's position towards the new tile.

# TODO: Set occupancy of each tile along the way in _process()


#region Parameters

@export var isEnabled: bool = true:
	set(newValue):
		if newValue != isEnabled:
			isEnabled = newValue
			self.set_physics_process(isEnabled and (isMovingToNewCell or shouldSnapPositionEveryFrame))


@export_group("Tile Map")

@export var tileMap: TileMapLayer:
	set(newValue):
		if newValue != tileMap:
			printChange("tileMap", tileMap, newValue)

			# If we have a TileMap and are about to leave it, mark our cell as no longer occupied.
			if tileMap and not newValue: vacateCurrentCell()

			tileMap = newValue
			# NOTE: TBD: Don't need validateTileMap() here

			if not self.tileMapData: # Try to get the TileMapCellData if we don't already have it
				if tileMap is TileMapLayerWithCellData: self.tileMapData = tileMap.cellData
				else: printDebug(str("tileMapData not set & tileMap missing TileMapCellData: ", tileMap))
			# NOTE: Do not applyInitialCoordinates() here; it would mess up when switching between different TileMaps.

@export var tileMapData: TileMapCellData:
	set(newValue):
		if tileMapData != newValue:
			printChange("tileMapData", tileMapData, newValue)

			# If we have a TileMap and are about to leave it, mark our cell as no longer occupied.
			if tileMapData and not newValue: vacateCurrentCell()

			tileMapData = newValue
			if tileMapData: validateTileMap()
			# NOTE: Do not applyInitialCoordinates() here; it would mess up when switching between different TileMaps.

## If `true` and [member tileMap] is `null` then the current Scene will be searched and the first [TileMapLayerWithCellData] will be used, if any.
## WARNING: Caues bugs when dynamically moving between TileMaps or setting up new Entities.
## @experimental
@export var shouldSearchForTileMap: bool = false


@export_group("Initial Position")

@export var setInitialCoordinatesFromEntityPosition: bool = false
@export var initialDestinationCoordinates: Vector2i

## If `false`, the entity will be instantly positioned at the initial destination, otherwise it may be animated from where it was before this component is executed if `shouldMoveInstantly` is false.
@export var shouldSnapToInitialDestination: bool = true


@export_group("Movement")

## The speed of moving between tiles. Ignored if [member shouldMoveInstantly].
## WARNING: If this is slower than the movement of the [member tileMap] then the component will never be able to catch up to the destination tile's position.
@export_range(10.0, 1000.0, 1.0) var speed: float = 200.0

@export var shouldMoveInstantly: bool = false

@export var shouldClampToBounds: bool = true ## Keep the entity within the [member tileMap]'s region of "painted" cells?

## Should the Cell be marked as [constant Global.TileMapCustomData.isOccupied] by the parent Entity?
## Set to `false` to disable occupancy; useful for visual-only entities such as mouse cursors and other UI/effects.
@export var shouldOccupyCell: bool = true

## If `true` then [method snapEntityPositionToTile] is called every frame to keep the Entity locked to the [TileMapLayer] grid.
## ALERT: PERFORMANCE: Enable only if the Entity or [TileMapLayer] may be moved during runtime by other scripts or effects, to avoid unnecessary processing each frame.
@export var shouldSnapPositionEveryFrame: bool = false:
	set(newValue):
		if newValue != shouldSnapPositionEveryFrame:
			shouldSnapPositionEveryFrame = newValue
			self.set_physics_process(isEnabled and (isMovingToNewCell or shouldSnapPositionEveryFrame)) # PERFORMANCE: Update per-frame only when needed

## A [Sprite2D] or any other [Node2D] to temporarily display at the destination tile while moving, such as a square cursor etc.
## NOTE: An example cursor is provided in the component scene but not enabled by default. Enable `Editable Children` to use it.
@export var visualIndicator: Node2D

#endregion


#region State

# TODO: TBD: @export_storage

var currentCellCoordinates: Vector2i:
	set(newValue):
		if newValue != currentCellCoordinates:
			printChange("currentCellCoordinates", currentCellCoordinates, newValue)
			currentCellCoordinates = newValue

var destinationCellCoordinates: Vector2i:
	set(newValue):
		if newValue != destinationCellCoordinates:
			printChange("destinationCellCoordinates", destinationCellCoordinates, newValue)
			destinationCellCoordinates = newValue

# var destinationTileGlobalPosition: Vector2i # NOTE: UNUSED: Not cached because the [TIleMapLayer] may move between frames.

var inputVector: Vector2i:
	set(newValue):
		if newValue != inputVector:
			if debugMode: Debug.printChange("inputVector", inputVector, newValue)
			# previousInputVector = inputVector # NOTE: This causes "flicker" between 0 and the other value, when resetting the `inputVector`, so just set it manually
			inputVector = newValue

var previousInputVector: Vector2i

var isMovingToNewCell: bool = false:
	set(newValue):
		if newValue != isMovingToNewCell:
			isMovingToNewCell = newValue
			updateIndicator()
			self.set_physics_process(isEnabled and (isMovingToNewCell or shouldSnapPositionEveryFrame)) # PERFORMANCE: Update per-frame only when needed

#endregion


#region Signals
signal willStartMovingToNewCell(newDestination: Vector2i)
signal didArriveAtNewCell(newDestination: Vector2i)

signal willSetNewMap(previousMap: TileMapLayer, currentCoordinates: Vector2i, newMap: TileMapLayer, newCoordinates: Vector2i)
signal didSetNewMap(previousMap:  TileMapLayer, currentCoordinates: Vector2i, newMap: TileMapLayer, newCoordinates: Vector2i)
#endregion


#region Life Cycle

func _ready() -> void:
	validateTileMap()

	if debugMode:
		self.willStartMovingToNewCell.connect(self.onWillStartMovingToNewCell)
		self.didArriveAtNewCell.connect(self.onDidArriveAtNewCell)

	# The tileMap may be set later, if this component was loaded dynamically at runtime, or initialized by another script.
	if tileMap: applyInitialCoordinates()

	updateIndicator() # Fix the visually-annoying initial snap from the default position
	self.willRemoveFromEntity.connect(self.onWillRemoveFromEntity)


func onWillRemoveFromEntity() -> void:
	# Set our cell as vacant before this component or entity is removed.
	vacateCurrentCell()

#endregion


#region Validation

## Verifies [member tileMap] & [member tileMapData].
func validateTileMap(searchForTileMap: bool = self.shouldSearchForTileMap) -> bool:
	# TODO: If missing, try to use the first [TileMapLayerWithCellData] found in the current scene, if any?

	if not tileMap:
		if searchForTileMap:
			if debugMode: printDebug("tileMap not specified! Searching for first TileMapLayerWithCellData or TileMapLayer in current scene…")
			self.tileMap = Tools.findFirstChildOfAnyTypes(get_tree().current_scene, [TileMapLayerWithCellData, TileMapLayer], false) # not returnParentIfNoMatches # WARNING: Caues bugs when dynamically moving between TileMaps or setting up new Entities.

		# Warn only in debugMode, in case the tileMapData will be supplied by a different script.
		if debugMode and not tileMap: printWarning("Missing TileMapLayerWithCellData or TileMapLayer")

	# Set the TileMapCellData if not present

	if not tileMapData:
		if tileMap and tileMap is TileMapLayerWithCellData:
			self.tileMapData = tileMap.cellData

		if not tileMapData:
			printWarning(str("Missing tileMapData for tileMap: ", tileMap))

	return tileMap and tileMapData # Validation passes only if both objects are valid


## Ensures that the specified coordinates are within the [TileMapLayer]'s bounds
## and also calls [method checkCellVacancy].
## May be overridden by subclasses to perform additional checks.
## NOTE: Subclasses MUST call super to perform common validation.
func validateCoordinates(coordinates: Vector2i) -> bool:
	var isValidBounds: bool = Tools.checkTileMapCoordinates(tileMap, coordinates)
	var isTileVacant:  bool = self.checkCellVacancy(coordinates)

	if debugMode: printDebug(str("@", coordinates, ": checkTileMapCoordinates(): ", isValidBounds, ", checkCellVacancy(): ", isTileVacant))

	return isValidBounds and isTileVacant


## Checks if the tile may be moved into.
## May be overridden by subclasses to perform different checks,
## such as testing custom data on a tile, e.g. [constant Global.TileMapCustomData.isWalkable],
## and custom data on a cell, e.g. [constant Global.TileMapCustomData.isOccupied],
## or performing a more rigorous physics collision detection.
func checkCellVacancy(coordinates: Vector2i) -> bool:
	# UNUSED: Tools.checkTileCollision(tileMap, parentEntity.body, coordinates) # The current implementation of the Global method always returns `true`.
	if tileMapData:
		return Tools.checkTileAndCellVacancy(tileMap, tileMapData, coordinates, self.parentEntity) # Ignore our own entity, just in case :')
	else:
		return Tools.checkTileVacancy(tileMap, coordinates)

#endregion


#endregion Positioning

func applyInitialCoordinates() -> void:
	# Get the entity's starting coordinates
	updateCurrentTileCoordinates()

	if setInitialCoordinatesFromEntityPosition:
		initialDestinationCoordinates = currentCellCoordinates

	# Even if we `setInitialCoordinatesFromEntityPosition`, snap the entity to the center of the cell

	# NOTE: Directly setting `destinationCellCoordinates = initialDestinationCoordinates` beforehand prevents the movement
	# because the functions check for a change between coordinates.

	if shouldSnapToInitialDestination:
		snapEntityPositionToTile(initialDestinationCoordinates)
	else:
		setDestinationCellCoordinates(initialDestinationCoordinates)


## Set the tile coordinates corresponding to the parent Entity's [member Node2D.global_position]
## and set the cell's occupancy.
func updateCurrentTileCoordinates() -> Vector2i:
	self.currentCellCoordinates = tileMap.local_to_map(tileMap.to_local(parentEntity.global_position))
	if shouldOccupyCell and tileMapData: Tools.setCellOccupancy(tileMapData, currentCellCoordinates, true, parentEntity)
	return currentCellCoordinates


## Instantly sets the entity's position to a tile's position.
## NOTE: Does NOT validate coordinates or check the cell's vacancy etc.
## TIP: May be useful for UI elements like cursors etc.
## If [param destinationOverride] is omitted then [member currentCellCoordinates] is used.
func snapEntityPositionToTile(tileCoordinates: Vector2i = self.currentCellCoordinates) -> void:
	if not isEnabled: return

	var tileGlobalPosition: Vector2 = Tools.getCellGlobalPosition(tileMap, tileCoordinates)

	if parentEntity.global_position != tileGlobalPosition:
		parentEntity.global_position = tileGlobalPosition

	self.currentCellCoordinates = tileCoordinates

#endregion


#region Control

## This method must be called by a control component upon receiving player input.
## EXAMPLE: `inputVector = Vector2i(Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown))`
func processMovementInput(inputVectorOverride: Vector2i = self.inputVector) -> void:
	# TODO: Check for TileMap bounds.
	# Don't accept input if already moving to a new tile.
	if (not isEnabled) or self.isMovingToNewCell: return
	setDestinationCellCoordinates(self.currentCellCoordinates + inputVectorOverride)


## Returns: `false if the new destination coordinates are not valid within the TileMap bounds.
func setDestinationCellCoordinates(newDestinationTileCoordinates: Vector2i) -> bool:

	# Is the new destination the same as the current destination? Then there's nothing to change.
	if newDestinationTileCoordinates == self.destinationCellCoordinates: return true

	# Is the new destination the same as the current tile? i.e. was the previous move cancelled?
	if newDestinationTileCoordinates == self.currentCellCoordinates:
		cancelDestination()
		return true # NOTE: Return true because arriving at the specified coordinates should be considered a success, even if already there. :)

	# Validate the new destination?

	if not validateCoordinates(newDestinationTileCoordinates):
		return false

	# Move Your Body ♪

	willStartMovingToNewCell.emit(newDestinationTileCoordinates)
	self.destinationCellCoordinates = newDestinationTileCoordinates
	self.isMovingToNewCell = true

	# Vacate the current (to-be previous) tile
	# NOTE: Always clear the previous cell even if not `shouldOccupyCell`, in case it was toggled true→false at runtime.
	if tileMapData: Tools.setCellOccupancy(tileMapData, currentCellCoordinates, false, null)

	# TODO: TBD: Occupy each cell along the way too each frame?
	if shouldOccupyCell and tileMapData: Tools.setCellOccupancy(tileMapData, newDestinationTileCoordinates, true, parentEntity)

	# Should we teleport?
	if shouldMoveInstantly: snapEntityPositionToTile(destinationCellCoordinates)

	return true


## Cancels the current move and vacates the previous [member destinationCellCoordinates] if needed.
func cancelDestination(snapToCurrentCell: bool = true) -> void:
	# First, clear the previous destination's occupancy in case we hogged it
	# NOTE: Vacate regardless of `shouldOccupyCell`
	if tileMapData and Tools.getCellOccupant(tileMapData, self.destinationCellCoordinates) == parentEntity:
		Tools.setCellOccupancy(tileMapData, self.destinationCellCoordinates, false, null)

	# Were we on the way to a different destination tile?
	if isMovingToNewCell and snapToCurrentCell:
		# Then snap back to the current tile coordinates.
		# TODO: Option to animate back?
		self.snapEntityPositionToTile(self.currentCellCoordinates)

	self.destinationCellCoordinates = self.currentCellCoordinates
	if shouldOccupyCell and tileMapData: Tools.setCellOccupancy(tileMapData, self.currentCellCoordinates, true, parentEntity) # Reoccupy the current cell
	self.isMovingToNewCell = false


func vacateCurrentCell() -> void:
	if tileMapData: Tools.setCellOccupancy(tileMapData, currentCellCoordinates, false, null)


## Uses a new [TileMapLayer] and preserves the current PIXEL position onscreen, but may get different CELL coordinates on the new map's grid.
## NOTE: Verifies if the new cell coordinates are unoccupied in the new map, but bounds are NOT validated; the current pixel position may be outside the new map's grid.
## Returns: The DIFFERENCE between the previous cell coordinates on the old map vs the updated cell coordinates on the new map.
func setMapAndKeepPosition(newMap: TileMapLayer, useNewData: bool = true) -> Vector2i:
	if not newMap or newMap == self.tileMap:
		if debugMode: printDebug(str("setMapAndKeepPosition(): newMap == current map or null: ", newMap))
		return Vector2i.ZERO # Nothing to do if nowhere to move!

	var previousCoordinates: Vector2i = self.currentCellCoordinates
	var previousDestination: Vector2i = self.destinationCellCoordinates
	var newCoordinates:		 Vector2i = Tools.convertCoordinatesBetweenTileMaps(self.tileMap, self.currentCellCoordinates, newMap)
	var isNewCellVacant:	 bool

	# NOTE: Only check vacancy, NOT bounds, so that overlapping maps of different sizes may be transitioned
	if newMap is TileMapLayerWithCellData and newMap.cellData: isNewCellVacant = Tools.checkTileAndCellVacancy(newMap, newMap.cellData, newCoordinates, self.parentEntity) # Ignore our own entity
	else: isNewCellVacant = Tools.checkTileVacancy(newMap, newCoordinates)

	if debugMode: printDebug(str("setMapAndKeepPosition(): ", self.tileMap, " @", previousCoordinates, ", pixel global position: ", parentEntity.global_position, " → ", newMap, " @", newCoordinates, ", isNewCellVacant: ", isNewCellVacant, ", within bounds: ", Tools.checkTileMapCoordinates(newMap, newCoordinates)))

	if isNewCellVacant: # Don't move if shouldn't move
		willSetNewMap.emit(self.tileMap, previousCoordinates, newMap, newCoordinates)

		# Vacate the current (to-be previous) tile from the current [TileMapCellData]
		if self.tileMapData:
			# As well as cancel any movement first
			self.cancelDestination(false) # not snapToCurrentCell # NOTE: This function reoccupies `currentCellCoordinates`
			Tools.setCellOccupancy(self.tileMapData, previousCoordinates, false, null) # isOccupied, occupant

		# NOTE: Do not replace our own data until the movement has been validated and the previous cell has been vacated.
		if useNewData and newMap is TileMapLayerWithCellData:
			if debugMode: printDebug(str("setMapAndKeepPosition() useNewData: ", self.tileMapData, " → ", newMap.cellData))
			if newMap.cellData:
				self.tileMapData = newMap.cellData
			else:
				printWarning(str("setMapAndKeepPosition() useNewData: true but newMap has no cellData: ", newMap))
				self.tileMapData = null # NOTE: Yes, clear the data if the new map doesn't have any, to avoid unexpected blocking in empty cells etc.

		# Move over

		var previousMap: TileMapLayer = self.tileMap # Let the TileMap change before changing `currentCellCoordinates`, just in case the property getters/setters do anything.
		self.tileMap = newMap
		self.validateTileMap(false) # not searchForTileMap # TBD: Is this necessary?
		self.currentCellCoordinates = newCoordinates

		# NOTE: Use the actual `currentCellCoordinates` from hereon instead of `newCoordinates`, which may not have been applied if there was an error or bug.
		if shouldOccupyCell and tileMapData: Tools.setCellOccupancy(tileMapData, self.currentCellCoordinates, true, parentEntity)

		# TBD: If we were on the way to a different cell during the previous map, keep moving to ensure smooth animations etc.
		var newDestination: Vector2i = Tools.convertCoordinatesBetweenTileMaps(previousMap, previousDestination, self.tileMap)
		if newDestination != self.currentCellCoordinates: self.setDestinationCellCoordinates(newDestination)

		if debugMode: printDebug(str("setMapAndKeepPosition() coordinates: ", previousCoordinates, " → ", self.currentCellCoordinates))
		didSetNewMap.emit(previousMap, previousCoordinates, newMap, self.currentCellCoordinates)
		return self.currentCellCoordinates - previousCoordinates
	# else
	return Vector2i.ZERO # No movement if we didn't move


## Uses a new [TileMapLayer] and preserves the current CELL coordinates, but may move the Entity to a new PIXEL position on the screen.
## NOTE: Verifies if the current coordinates are unoccupied in the new map, but bounds are NOT validated; the coordinates may be outside the new map's grid.
## Returns: The DIFFERENCE between the Entity's previous global position and the new global position.
func setMapAndKeepCoordinates(newMap: TileMapLayer, useNewData: bool = true) -> Vector2:
	if not newMap or newMap == self.tileMap:
		if debugMode: printDebug(str("setMapAndKeepCoordinates(): newMap == current map or null: ", newMap))
		return Vector2.ZERO # Nothing to do if nowhere to move!

	var isNewCellVacant: bool

	# NOTE: Only check vacancy, NOT bounds, so that overlapping maps of different sizes may be transitioned
	if newMap is TileMapLayerWithCellData and newMap.cellData: isNewCellVacant = Tools.checkTileAndCellVacancy(newMap, newMap.cellData, self.currentCellCoordinates, self.parentEntity) # Ignore our own entity
	else: isNewCellVacant = Tools.checkTileVacancy(newMap, self.currentCellCoordinates)

	if debugMode: printDebug(str("setMapAndKeepCoordinates(): ", self.tileMap, " → ", newMap, " @", self.currentCellCoordinates, ", isNewCellVacant: ", isNewCellVacant, ", within bounds: ", Tools.checkTileMapCoordinates(newMap, self.currentCellCoordinates)))

	if isNewCellVacant: # Don't move if shouldn't move
		var previousPosition: Vector2 = parentEntity.global_position
		willSetNewMap.emit(self.tileMap, self.currentCellCoordinates, newMap, self.currentCellCoordinates)

		# Vacate the current (to-be previous) tile from the current [TileMapCellData]
		if self.tileMapData:
			# As well as cancel any movement first
			self.cancelDestination(false) # not snapToCurrentCell # NOTE: This function reoccupies `currentCellCoordinates`
			Tools.setCellOccupancy(self.tileMapData, self.currentCellCoordinates, false, null) # isOccupied, occupant

		# NOTE: Do not replace our own data until the movement has been validated and the previous cell has been vacated.
		if useNewData and newMap is TileMapLayerWithCellData:
			if debugMode: printDebug(str("setMapAndKeepCoordinates() useNewData: ", self.tileMapData, " → ", newMap.cellData))
			if newMap.cellData:
				self.tileMapData = newMap.cellData
			else:
				printWarning(str("setMapAndKeepCoordinates() useNewData: true but newMap has no cellData: ", newMap))
				self.tileMapData = null # NOTE: Yes, clear the data if the new map doesn't have any, to avoid unexpected blocking in empty cells etc.

		# Move over
		var previousMap: TileMapLayer = self.tileMap
		self.tileMap = newMap
		self.validateTileMap(false) # not searchForTileMap # TBD: Is this necessary?
		if shouldOccupyCell and tileMapData: Tools.setCellOccupancy(tileMapData, self.currentCellCoordinates, true, parentEntity)

		# Animate movement to a new pixel position if needed.
		if shouldMoveInstantly:
			snapEntityPositionToTile(self.currentCellCoordinates)
			self.isMovingToNewCell = false
		else:
			self.destinationCellCoordinates = self.currentCellCoordinates # TBD: Necessary?
			self.isMovingToNewCell = true

		if debugMode: printDebug(str("setMapAndKeepCoordinates() position: ", previousPosition, " → ", parentEntity.global_position))
		didSetNewMap.emit(previousMap, self.currentCellCoordinates, newMap, self.currentCellCoordinates)
		return parentEntity.global_position - previousPosition
	# else
	return Vector2.ZERO # No movement if we didn't move

#endregion


#region Per-Frame Updates

func _physics_process(delta: float) -> void:
	# TODO: TBD: Occupy each cell along the way too?
	if not isEnabled: return

	if isMovingToNewCell:
		moveTowardsDestinationCell(delta)
		checkForArrival()
	elif shouldSnapPositionEveryFrame and tileMap != null:
		# If we are already at the destination, keep snapping to the current tile coordinates,
		# to ensure alignment in case the TileMap node is moving.
		snapEntityPositionToTile()

	if debugMode: showDebugInfo()


## Called every frame to move the parent Entity towards the [member destinationCellCoordinates]'s onscreen position.
## IMPORTANT: Other scripts should NOT call this method directly; use [method setDestinationCellCoordinates] to specify a new map grid cell.
func moveTowardsDestinationCell(delta: float) -> void:
	# TODO: Handle physics collisions
	# TODO: TBD: Occupy each cell along the way too?
	var destinationTileGlobalPosition: Vector2 = Tools.getCellGlobalPosition(tileMap, self.destinationCellCoordinates) # NOTE: Not cached because the TIleMap may move between frames.
	parentEntity.global_position = parentEntity.global_position.move_toward(destinationTileGlobalPosition, speed * delta)
	parentEntity.reset_physics_interpolation() # CHECK: Necessary?


## Are we there yet?
func checkForArrival() -> bool:
	var destinationTileGlobalPosition: Vector2 = Tools.getCellGlobalPosition(tileMap, self.destinationCellCoordinates)
	if parentEntity.global_position == destinationTileGlobalPosition:
		self.currentCellCoordinates = self.destinationCellCoordinates
		self.isMovingToNewCell = false
		didArriveAtNewCell.emit(currentCellCoordinates)
		previousInputVector = inputVector
		inputVector = Vector2i.ZERO
		return true
	else:
		self.isMovingToNewCell = true
		return false


func updateIndicator() -> void:
	if not visualIndicator: return
	if tileMap:
		visualIndicator.global_position = Tools.getCellGlobalPosition(tileMap, self.destinationCellCoordinates)
		visualIndicator.visible = isMovingToNewCell
	else:
		visualIndicator.position = Vector2.ZERO # TBD: Necessary?
		visualIndicator.visible = false

#endregion


#region Debugging

func showDebugInfo() -> void:
	if not debugMode: return
	Debug.addComponentWatchList(self, {
		tileMap				= tileMap,
		entityPosition		= parentEntity.global_position,
		currentCell			= currentCellCoordinates,
		input				= inputVector,
		previousInput		= previousInputVector,
		isMovingToNewCell	= isMovingToNewCell,
		destinationCell		= destinationCellCoordinates,
		destinationPosition	= Tools.getCellGlobalPosition(tileMap, destinationCellCoordinates) if tileMap else Vector2.ZERO,
		})


func onWillStartMovingToNewCell(newDestination: Vector2i) -> void:
	if debugMode: printDebug(str("willStartMovingToNewCell(): ", newDestination))


func onDidArriveAtNewCell(newDestination: Vector2i) -> void:
	if debugMode: printDebug(str("onDidArriveAtNewCell(): ", newDestination))

#endregion
