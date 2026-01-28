## Sets the position of the parent Entity to the position of a grid cell in an associated [TileMapLayer].
## NOTE: Does NOT receive player control input, or perform path-finding or any other validation logic
## except checking the tile map bounds and tile vacancy/collision.
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

			# Are we about to leave a TileMap?
			if tileMap != null: # Doesn't matter if newValue is `null` or a new map
				if isMovingToNewCell: cancelMove() # Cancel the trip
				vacateCell(currentCoordinates) # Mark our previous/current cell as no longer occupied
				# NOTE: Vacate the cell AFTER cancelling the movement.
				# TBD:  Reset `destinationCoordinates`?

			tileMap = newValue
			# NOTE: TBD: Don't need validateTileMap() here

			# Use the new map's data to keep track of cell vacancy etc.
			# TBD: Should we keep using any existing `tileMapData` we have?
			if tileMap is TileMapLayerWithCellData: self.tileMapData = tileMap.cellData
			elif self.tileMapData == null: printDebug(str("tileMapData not set & tileMap missing TileMapCellData: ", tileMap))
			# NOTE: Do not applyInitialCoordinates() here; it would mess up when switching between different TileMaps.

@export var tileMapData: TileMapCellData:
	set(newValue):
		if tileMapData != newValue:
			printChange("tileMapData", tileMapData, newValue)

			# Do we have existing data and are about to abandon it?
			if tileMapData != null: # Doesn't matter if `newValue` is `null` or new data
				vacateCell(currentCoordinates) # Mark our previous/current cell as no longer occupied

			tileMapData = newValue
			if tileMapData and validateTileMap():
				# Reoccupy the cell in the new data
				if isMovingToNewCell: occupyCell(destinationCoordinates) # TBD: Should the destination cell be occupied in the new data?
				else: occupyCell(currentCoordinates)
			# NOTE: AVOID: Do not applyInitialCoordinates() here; it would mess up when switching between different TileMaps.

## If `true` and [member tileMap] is `null` then the current Scene will be searched and the first [TileMapLayerWithCellData] will be used, if any.
## WARNING: Caues bugs when dynamically moving between TileMaps or setting up new Entities.
## @experimental
@export var shouldSearchForTileMap: bool = false


@export_group("Initial Position")

@export var setInitialCoordinatesFromEntityPosition: bool = true
@export var initialDestinationCoordinates: Vector2i

## If `true`, the entity will be instantly repositioned at the initial destination, 
## otherwise it may be animated from where it was before this component is first executed.
@export var shouldSnapToInitialDestination: bool = true


@export_group("Movement")

## The speed of moving between tiles. Ignored if [member shouldMoveInstantly].
## WARNING: If this is slower than the movement of the [member tileMap] then the component will never be able to catch up to the destination tile's position.
@export_range(0, 1000, 1) var speed: float = 200

@export var shouldMoveInstantly: bool = false

@export var shouldClampToBounds: bool = true ## Keep the entity within the [member tileMap]'s region of "painted" cells?

## Should the grid cell be marked as [constant Global.TileMapCustomData.isOccupied] by the parent Entity?
## Set to `false` to disable occupancy; useful for visual-only entities such as mouse cursors and other UI/effects.
@export var shouldOccupyCell: bool = true

## If `true` then [method checkCellVacancy] is skipped, ignoring [constant Global.TileMapCustomData.isOccupied] and other entities.
## TIP: This may be used for "overlays" such as cursors etc. that do not care about "walkability" or "contesting" for TileMap cells.
@export var shouldIgnoreVacancy: bool = false

## If `true` then [method snapPositionToCell] is called every frame to keep the Entity locked to the [TileMapLayer] grid.
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

var currentCoordinates: Vector2i:
	set(newValue):
		if newValue != currentCoordinates:
			printChange("currentCoordinates", currentCoordinates, newValue)
			currentCoordinates = newValue

## The [TileMapLayer] grid cell that the entity should or is moving to.
## ALERT: Do NOT set this value directly! Call [method setDestinationCoordinates] to perform the necessary validation and update occupancy etc.
var destinationCoordinates: Vector2i:
	set(newValue):
		if newValue != destinationCoordinates:
			printChange("destinationCoordinates", destinationCoordinates, newValue)
			destinationCoordinates = newValue

# var destinationTileGlobalPosition: Vector2i # NOTE: UNUSED: Not cached because the [TIleMapLayer] may move between frames.

var inputVector: Vector2i:
	set(newValue):
		if newValue != inputVector:
			if debugMode: Debug.printChange("inputVector", inputVector, newValue)
			# previousInputVector = inputVector # UNUSED: BUGFIXED: This causes "flicker" between 0 and the other value, when resetting the `inputVector`, so just set it manually
			inputVector = newValue

var previousInputVector: Vector2i

var isMovingToNewCell: bool = false:
	set(newValue):
		if newValue != isMovingToNewCell:
			isMovingToNewCell = newValue
			updateIndicator()
			self.set_physics_process(isEnabled and (isMovingToNewCell or shouldSnapPositionEveryFrame)) # PERFORMANCE: Update per-frame only when needed
			# Warn if we're trying to move with no speed
			if debugMode and isMovingToNewCell and is_zero_approx(speed): printDebug("isMovingToNewCell: true but speed is 0!")

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
	vacateCell()

#endregion


#region Validation

## Verifies [member tileMap] & [member tileMapData].
func validateTileMap(searchForTileMap: bool = self.shouldSearchForTileMap) -> bool:
	# TODO: If missing, try to use the first [TileMapLayerWithCellData] found in the current scene, if any?

	if not tileMap:
		if searchForTileMap:
			if debugMode: printDebug("tileMap not specified! Searching for first TileMapLayerWithCellData or TileMapLayer in current scene…")
			tileMap = Tools.findFirstChildOfAnyTypes(get_tree().current_scene, [TileMapLayerWithCellData, TileMapLayer], false) # not returnParentIfNoMatches # WARNING: Caues bugs when dynamically moving between TileMaps or setting up new Entities.

		# Warn only in debugMode, in case the tileMapData will be supplied by a different script.
		if debugMode and not tileMap: printWarning("Missing TileMapLayerWithCellData or TileMapLayer")

	# Set the TileMapCellData if not present

	if not tileMapData:
		if tileMap and tileMap is TileMapLayerWithCellData:
			self.tileMapData = tileMap.cellData

		if not tileMapData:
			printWarning(str("Missing tileMapData for tileMap: ", tileMap))

	return tileMap and tileMapData # Validation passes only if both objects are valid


## Ensures that the specified coordinates are within the [TileMapLayer]'s bounds if [member shouldClampToBounds] is set,
## and also calls [method checkCellVacancy].
## May be overridden by subclasses to perform additional checks.
## NOTE: Subclasses MUST call super to perform common validation.
func validateCoordinates(coordinates: Vector2i) -> bool:
	if not is_instance_valid(tileMap): return false # If there is no TileMap then nothing is valid :')
	
	var isValidBounds: bool = Tools.checkTileMapCoordinates(tileMap, coordinates) if shouldClampToBounds else true # All coordinates are valid if `shouldClampToBounds` is `false`
	var isTileVacant:  bool = shouldIgnoreVacancy or self.checkCellVacancy(coordinates) # Check the skip flag first to avoid a function call

	if debugMode: printDebug(str("@", coordinates, ": checkTileMapCoordinates(): ", isValidBounds, ", checkCellVacancy(): ", isTileVacant))

	return isValidBounds and isTileVacant


## Checks if the map grid cell may be moved into, by checking whether the [TileMapLayer] TILE TYPE is marked as "walkable" (i.e. not a rock or tree),
## and also whether the CELL is unoccupied by other characters.
## If [member shouldIgnoreVacancy] is set then all checks are skipped and this method always returns `true`.
## May be overridden by subclasses to perform different checks,
## such as testing custom data on a tile, e.g. [constant Global.TileMapCustomData.isWalkable],
## and custom data on a cell, e.g. [constant Global.TileMapCustomData.isOccupied],
## or performing a more rigorous physics collision detection.
func checkCellVacancy(coordinates: Vector2i) -> bool:
	# UNUSED: Tools.checkTileCollision(tileMap, parentEntity.body, coordinates) # The current implementation of the Global method always returns `true`.
	if shouldIgnoreVacancy: return true
	if tileMapData:
		return Tools.checkTileAndCellVacancy(tileMap, tileMapData, coordinates, parentEntity) # Ignore our own entity, just in case :')
	else:
		return Tools.checkTileVacancy(tileMap, coordinates)

#endregion


#region Positioning

func applyInitialCoordinates() -> void:
	# Get the entity's starting coordinates in the scene in relation to the [TileMapLayer],
	# NOTE: BUT do NOT use updateCurrentCoordinates() because we don't want to  "occupy" the cell yet! 
	# because the initial cell may be different than the entity's starting pixel position,
	# so only that destination cell where the entity will end up in should be marked as "occupied"
	currentCoordinates = getNearestCoordinates()

	if setInitialCoordinatesFromEntityPosition:
		initialDestinationCoordinates = currentCoordinates

	# Even if we `setInitialCoordinatesFromEntityPosition`, we must snap the entity to the CENTER of the cell

	# NOTE: Directly setting `destinationCoordinates = initialDestinationCoordinates` beforehand prevents the movement
	# because the functions check for a change between coordinates.

	if shouldSnapToInitialDestination:
		if validateCoordinates(initialDestinationCoordinates):
			destinationCoordinates = initialDestinationCoordinates # Update directly, just in case, to avoid inconsistencies later, e.g. with cancelMove() etc.
			snapPositionToCell(initialDestinationCoordinates)
			occupyCell()
		else:
			printWarning(str("applyInitialCoordinates() @", initialDestinationCoordinates, " failed validateCoordinates()"))
	else:
		setDestinationCoordinates(initialDestinationCoordinates, true) # skipDifferenceCheck
		# TBD: Think of a more elegant and less brute way to apply the initial coordinates?


## Returns the coordinates of the [TileMapLayer] grid cell nearest to the entity's global position.
func getNearestCoordinates() -> Vector2i:
	return tileMap.local_to_map(tileMap.to_local(parentEntity.global_position))


## Sets the cell coordinates corresponding to the entity's [member Node2D.global_position]
## and sets the cell's occupancy to be "claimed" by the entity.
func updateCurrentCoordinates() -> Vector2i:
	self.currentCoordinates = tileMap.local_to_map(tileMap.to_local(parentEntity.global_position))
	occupyCell()
	return currentCoordinates


## Instantly sets the entity's position to a tile's position.
## NOTE: Does NOT validate coordinates or check the cell's vacancy etc.
## TIP: May be useful for UI elements like cursors etc.
## If [param destinationOverride] is omitted then [member currentCoordinates] is used.
func snapPositionToCell(tileCoordinates: Vector2i = self.currentCoordinates) -> void:
	if not isEnabled: return

	var tileGlobalPosition: Vector2 = Tools.getCellGlobalPosition(tileMap, tileCoordinates)

	if  parentEntity.global_position != tileGlobalPosition:
		parentEntity.global_position  = tileGlobalPosition

	self.currentCoordinates = tileCoordinates


## "Claims" a [TileMapLayer] cell to be "occupied" by the entity, if [member shouldOccupyCell] is `true`,
## at the [member currentCoordinates] by default, so that other entities cannot enter the same cell.
## RETURNS: Fails and returns `false` if [member shouldOccupyCell] is not set,
## or if there is no [TileMapLayerWithCellData] [member tileMapData].
## or if the cell is already occupied by another entity and [param replaceOtherOccupants] is not set.
## ALERT: [param replaceOtherOccupants] is `true` by default if [member shouldOccupyCell] and [member shouldIgnoreVacancy] are both `true`.
func occupyCell(coordinates: Vector2i = self.currentCoordinates, replaceOtherOccupants: bool = shouldOccupyCell and shouldIgnoreVacancy) -> bool:
	# TBD: Should this function be part of Tools.gd?
	
	if debugMode: printDebug(str("occupyCell() @", coordinates, ", shouldOccupyCell: ", shouldOccupyCell, ", replaceOtherOccupants: ", replaceOtherOccupants))

	if not shouldOccupyCell: return false # TBD: Return `true` or `false` if we're not supposed to occupy? # DESIGN: It should probably be `false`, as it doesn not accomplish the intent of occupying a cell.

	if not is_instance_valid(tileMapData): return false # TBD: Log warning?

	# See if someone else has already set up shop
	var previousOccupant: Entity = Tools.getCellOccupant(tileMapData, coordinates)
	if  previousOccupant and previousOccupant != parentEntity: # Ignore `null`
		printDebug(str("occupyCell() @",coordinates, " has existing occupant: ", previousOccupant, ", replaceOtherOccupants: ", replaceOtherOccupants)) # TBD: Should this be a warning?
		if not replaceOtherOccupants: return false

	# Take over! 

	Tools.setCellOccupancy(tileMapData, coordinates, true, parentEntity) # isOccupied
	return true


## Releases the entity's "claim" on a [TileMapLayer] grid cell, at the [member currentCoordinates] by default,
## so that other entities may enter that cell.
## Fails and returns `false` if the cell is occupied by a DIFFERENT entity, or if there is no [TileMapLayerWithCellData] [member tileMapData].
## NOTE: This method does not check [member shouldOccupyCell].
func vacateCell(coordinates: Vector2i = self.currentCoordinates) -> bool:
	# TBD: Should this function be part of Tools.gd?
	
	if debugMode: printDebug(str("vacateCell() @", coordinates))

	if not is_instance_valid(tileMapData): return false # TBD: Return `true` if `shouldOccupyCell` is not set? # TBD: Log warning?

	var occupant: Entity = Tools.getCellOccupant(tileMapData, coordinates)

	# NOTE: Do not check `shouldOccupyCell` because cleanup should always be done, and the flag may have changed during runtime.	
	# NOTE: Make sure our entity still "owns" the cell so we don't accidentally wipe out someone else's space!
	if occupant == parentEntity:
		Tools.setCellOccupancy(tileMapData, coordinates, false, null) # isOccupied, occupant
		return true

	elif occupant == null:
		# DESIGN: Return `true` if just trying to vacate an already vacant cell,
		# because that would be the behavior expected by any caller of this method: The intent of vacating a cell is already accomplished.
		return true

	elif shouldOccupyCell:
		# NOTE: Warn if we tried to vacate a cell occupied by a different entity,
		# because if this case happens then there's probably a bug somewhere,
		# BUT check `shouldOccupyCell` to avoid superfluous warnings if we weren't supposed to occupy in the first place!
		printWarning(str("Tried to vacate cell that was not occupied by this entity! ", tileMap, " @", coordinates, " occupant: ", occupant))
	
	return false

#endregion


#region Control

## This method must be called by a control component upon receiving player input.
## EXAMPLE: `inputVector = Vector2i(Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown))`
func processInput(inputVectorOverride: Vector2i = inputVector) -> void:
	# TODO: Check for TileMap bounds.
	# Don't accept input if already moving to a new tile.
	if (not isEnabled) or isMovingToNewCell: return
	# TBD: Update previousInputVector = inputVectorOverride or should it only be a temporary override?
	setDestinationCoordinates(currentCoordinates + inputVectorOverride)


## Begins movement towards a new cell and updates the occupancy of the previous and new cells.
## Returns `false if the new destination coordinates are not valid within the [TileMapLayer]'s grid bounds, or if the cell is not a "walkable" tile and [member shouldIgnoreVacancy] is not set.
func setDestinationCoordinates(newDestinationTileCoordinates: Vector2i, skipDifferenceCheck: bool = false) -> bool:
	if debugMode: printDebug(str("setDestinationCoordinates() ", destinationCoordinates, " → ", newDestinationTileCoordinates))

	var isNewDestination: bool = destinationCoordinates != newDestinationTileCoordinates

	# `skipDifferenceCheck` is for cases such as when setting the initial coordinates,
	# to move the entity regardless of the old and new coordinates being the same, e.g. when initializing to (0,0)
	# TBD: Think of a more elegant and less brute way to apply the initial coordinates?
	if not skipDifferenceCheck:
	
		# Is the new destination the same as the current destination? Then there's nothing to change.
		# WARNING: If the values were modified manually, then the rest of the validation and updates may be skipped!
		if not isNewDestination: return true

		# Is the new destination the same as the current tile? i.e. was the previous move cancelled?
		if newDestinationTileCoordinates == currentCoordinates:
			cancelMove()
			return true # NOTE: Return true because arriving at the specified coordinates should be considered a success, even if already there :)

	# Validate the new destination
	if not validateCoordinates(newDestinationTileCoordinates):
		return false

	# Move Your Body ♪

	if isNewDestination:
		# TBD: Emit signal regardless of difference in destination?
		# TBD: A different signal for changing destination during movement?
		willStartMovingToNewCell.emit(newDestinationTileCoordinates)

	# Were we already moving and chose a new destination mid-way?
	if isMovingToNewCell:
		# Then vacate the previous destination!
		if isNewDestination:
			vacateCell(destinationCoordinates)
			destinationCoordinates = newDestinationTileCoordinates
			updateIndicator()
	else:
		destinationCoordinates = newDestinationTileCoordinates
		
		# Vacate the current (to-be previous) tile
		# NOTE: Always clear the previous cell even if not `shouldOccupyCell`, in case it was toggled true→false at runtime.
		vacateCell(currentCoordinates)
		
		isMovingToNewCell = true # Calls updateIndicator()

	# Claim our soon-to-be new home!
	# TBD: Should we occupy each cell along the way too, during each frame?
	# TODO: Check if destination cell was occupied by another entity during our move!
	occupyCell(newDestinationTileCoordinates)
	
	# Should we teleport?
	if shouldMoveInstantly:
		snapPositionToCell(destinationCoordinates)
		checkForArrival() # Update all flags etc.

	return true


## Aborts the current movement, vacates the previous [member destinationCoordinates] and snaps back to the [member currentCoordinates] if needed.
## WARNING: If another entity occupied the starting cell during the movie, then this entity will NOT re-occupy the [member currentCoordinates]!
func cancelMove(snapToCurrentCell: bool = true) -> void:
	# First, clear the previous destination's occupancy in case we hogged it
	# NOTE: Vacate regardless of `shouldOccupyCell`
	vacateCell(destinationCoordinates)
	
	# Were we on the way to a different destination tile?
	if isMovingToNewCell and snapToCurrentCell:
		# Then snap back to the current tile coordinates.
		# TODO: Option to animate back?
		snapPositionToCell(currentCoordinates)

	destinationCoordinates = currentCoordinates # Cancel the destination 
	# NOTE: If another entity moved into our starting cell before we cancelled the move, do NOT re-occupy the cell.
	# TBD:  A better way to resolve conflicts?
	occupyCell(currentCoordinates) # Reoccupy the current cell if empty

	isMovingToNewCell = false


## Uses a new [TileMapLayer] and preserves the current PIXEL position onscreen, but may get different CELL coordinates on the new map's grid.
## NOTE: Verifies if the new cell coordinates are unoccupied in the new map, but bounds are NOT validated; the current pixel position may be outside the new map's grid.
## Returns: The DIFFERENCE between the previous cell coordinates on the old map vs the updated cell coordinates on the new map.
func setMapAndKeepPosition(newMap: TileMapLayer, useNewData: bool = true) -> Vector2i:

	# If we're not currently on any [valid] map, then this operation is invalid.
	# TBD: Should we treat this as our first map in this case?
	if not is_instance_valid(self.tileMap):
		printWarning("setMapAndKeepPosition() current `tileMap` is invalid: Initialize `tileMap` before changing maps.")
		return Vector2i.ZERO
	# or is the new map invalid?
	elif not is_instance_valid(newMap) or newMap == self.tileMap:
		if debugMode: printDebug(str("setMapAndKeepPosition(): newMap == current map or null/invalid: ", newMap))
		return Vector2i.ZERO # Nothing to do if nowhere to move!

	var previousCoordinates: Vector2i = self.currentCoordinates
	var previousDestination: Vector2i = self.destinationCoordinates
	var newCoordinates:		 Vector2i = Tools.convertCoordinatesBetweenTileMaps(self.tileMap, self.currentCoordinates, newMap)
	var isNewCellVacant:	 bool

	# NOTE: Only check vacancy, NOT bounds, so that overlapping maps of different sizes may be transitioned
	if newMap is TileMapLayerWithCellData and newMap.cellData: isNewCellVacant = shouldIgnoreVacancy or Tools.checkTileAndCellVacancy(newMap, newMap.cellData, newCoordinates, self.parentEntity) # Ignore our own entity
	else: isNewCellVacant = Tools.checkTileVacancy(newMap, newCoordinates)

	if debugMode: printDebug(str("setMapAndKeepPosition(): ", self.tileMap, " @", previousCoordinates, ", pixel global position: ", parentEntity.global_position, " → ", newMap, " @", newCoordinates, ", isNewCellVacant: ", isNewCellVacant, ", within bounds: ", Tools.checkTileMapCoordinates(newMap, newCoordinates)))

	if isNewCellVacant: # Don't move if shouldn't move
		willSetNewMap.emit(self.tileMap, previousCoordinates, newMap, newCoordinates)

		# Vacate the current (to-be previous) tile from the current [TileMapCellData]
		if self.tileMapData:
			# As well as cancel any movement first
			self.cancelMove(false) # not snapToCurrentCell # NOTE: This function reoccupies `currentCoordinates`
			vacateCell(previousCoordinates)

		# NOTE: Do not replace our own data until the movement has been validated and the previous cell has been vacated.
		if useNewData and newMap is TileMapLayerWithCellData:
			if debugMode: printDebug(str("setMapAndKeepPosition() useNewData: ", self.tileMapData, " → ", newMap.cellData))
			if newMap.cellData:
				self.tileMapData = newMap.cellData
			else:
				printWarning(str("setMapAndKeepPosition() useNewData: true but newMap has no cellData: ", newMap))
				self.tileMapData = null # NOTE: Yes, clear the data if the new map doesn't have any, to avoid unexpected blocking in empty cells etc.

		# Move over

		var previousMap: TileMapLayer = self.tileMap # Let the TileMap change before changing `currentCoordinates`, just in case the property getters/setters do anything.
		self.tileMap = newMap
		self.validateTileMap(false) # not searchForTileMap # TBD: Is this necessary?
		self.currentCoordinates = newCoordinates

		# NOTE: Use the actual `currentCoordinates` from hereon instead of `newCoordinates`, which may not have been applied if there was an error or bug.
		occupyCell()

		# TBD: If we were on the way to a different cell during the previous map, keep moving to ensure smooth animations etc.
		var newDestination: Vector2i = Tools.convertCoordinatesBetweenTileMaps(previousMap, previousDestination, self.tileMap)
		if newDestination != self.currentCoordinates: self.setDestinationCoordinates(newDestination)

		if debugMode: printDebug(str("setMapAndKeepPosition() coordinates: ", previousCoordinates, " → ", self.currentCoordinates))
		didSetNewMap.emit(previousMap, previousCoordinates, newMap, self.currentCoordinates)
		return self.currentCoordinates - previousCoordinates
	# else
	return Vector2i.ZERO # No movement if we didn't move


## Uses a new [TileMapLayer] and preserves the current CELL coordinates, but may move the Entity to a new PIXEL position on the screen.
## NOTE: Verifies if the current coordinates are unoccupied in the new map, but bounds are NOT validated; the coordinates may be outside the new map's grid.
## Returns: The DIFFERENCE between the Entity's previous global position and the new global position.
func setMapAndKeepCoordinates(newMap: TileMapLayer, useNewData: bool = true) -> Vector2:

	# If we're not currently on any [valid] map, then this operation is invalid.
	# TBD: Should we treat this as our first map in this case?
	if not is_instance_valid(self.tileMap):
		printWarning("setMapAndKeepCoordinates() current `tileMap` is invalid: Initialize `tileMap` before changing maps.")
		return Vector2.ZERO
	# or is the new map invalid?
	if not newMap or newMap == self.tileMap:
		if debugMode: printDebug(str("setMapAndKeepCoordinates(): newMap == current map or null: ", newMap))
		return Vector2.ZERO # Nothing to do if nowhere to move!

	var isNewCellVacant: bool

	# NOTE: Only check vacancy, NOT bounds, so that overlapping maps of different sizes may be transitioned
	if newMap is TileMapLayerWithCellData and newMap.cellData: isNewCellVacant = shouldIgnoreVacancy or Tools.checkTileAndCellVacancy(newMap, newMap.cellData, self.currentCoordinates, self.parentEntity) # Ignore our own entity
	else: isNewCellVacant = Tools.checkTileVacancy(newMap, self.currentCoordinates)

	if debugMode: printDebug(str("setMapAndKeepCoordinates(): ", self.tileMap, " → ", newMap, " @", self.currentCoordinates, ", isNewCellVacant: ", isNewCellVacant, ", within bounds: ", Tools.checkTileMapCoordinates(newMap, self.currentCoordinates)))

	if isNewCellVacant: # Don't move if shouldn't move
		var previousPosition: Vector2 = parentEntity.global_position
		willSetNewMap.emit(self.tileMap, self.currentCoordinates, newMap, self.currentCoordinates)

		# Vacate the current (to-be previous) tile from the current [TileMapCellData]
		if self.tileMapData:
			# As well as cancel any movement first
			self.cancelMove(false) # not snapToCurrentCell # NOTE: This function reoccupies `currentCoordinates`
			vacateCell(self.currentCoordinates)

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
		occupyCell()

		# Animate movement to a new pixel position if needed.
		if shouldMoveInstantly:
			snapPositionToCell(self.currentCoordinates)
			self.isMovingToNewCell = false
		else:
			self.destinationCoordinates = self.currentCoordinates # TBD: Necessary?
			self.isMovingToNewCell = true

		if debugMode: printDebug(str("setMapAndKeepCoordinates() position: ", previousPosition, " → ", parentEntity.global_position))
		didSetNewMap.emit(previousMap, self.currentCoordinates, newMap, self.currentCoordinates)
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
		snapPositionToCell()

	if debugMode: showDebugInfo()


## Called every frame to move the parent Entity towards the [member destinationCoordinates]'s onscreen position.
## IMPORTANT: Other scripts should NOT call this method directly; use [method setDestinationCoordinates] to specify a new map grid cell.
func moveTowardsDestinationCell(delta: float) -> void:
	# TODO: Handle physics collisions
	# TODO: TBD: Occupy each cell along the way too?
	var destinationTileGlobalPosition: Vector2 = Tools.getCellGlobalPosition(tileMap, self.destinationCoordinates) # NOTE: Not cached because the TIleMap may move between frames.
	parentEntity.global_position = parentEntity.global_position.move_toward(destinationTileGlobalPosition, self.speed * delta)
	parentEntity.reset_physics_interpolation() # CHECK: Necessary?


## Are we there yet?
## WARNING: If the [TileMapLayer] moves or transforms, or the destination position keeps changing, then this method will AWLAYS return `false`!
func checkForArrival() -> bool:
	var destinationTileGlobalPosition: Vector2 = Tools.getCellGlobalPosition(tileMap, self.destinationCoordinates)
	if parentEntity.global_position.is_equal_approx(destinationTileGlobalPosition):
		self.currentCoordinates = self.destinationCoordinates
		self.isMovingToNewCell = false
		self.didArriveAtNewCell.emit(currentCoordinates)
		self.previousInputVector = self.inputVector
		self.inputVector = Vector2i.ZERO
		return true
	else:
		self.isMovingToNewCell = true
		return false


func updateIndicator() -> void:
	if not visualIndicator: return
	if tileMap:
		visualIndicator.global_position = Tools.getCellGlobalPosition(tileMap, self.destinationCoordinates)
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
		currentCell			= currentCoordinates,
		input				= inputVector,
		previousInput		= previousInputVector,
		isMovingToNewCell	= isMovingToNewCell,
		destinationCell		= destinationCoordinates,
		destinationPosition	= Tools.getCellGlobalPosition(tileMap, destinationCoordinates) if tileMap else Vector2.ZERO,
		})


func onWillStartMovingToNewCell(newDestination: Vector2i) -> void:
	if debugMode: printDebug(str("willStartMovingToNewCell(): ", newDestination))


func onDidArriveAtNewCell(newDestination: Vector2i) -> void:
	if debugMode: printDebug(str("onDidArriveAtNewCell(): ", newDestination))

#endregion
