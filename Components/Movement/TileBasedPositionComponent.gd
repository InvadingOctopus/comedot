## Sets the position of the parent Entity to the position of a tile in an associated [TileMapLayer].
## Does NOT receive player control input, or perform path-finding or any other validation logic
## except checking the tile map bounds and tile collision.
## NOTE: To provide player input, use [TileBasedControlComponent].
## Requirements: [TileMapLayerWithCustomCellData]

class_name TileBasedPositionComponent
extends Component

# PLAN:
# * Store integer coordinates to remember which tile the entity is in.
# * Every frame,
# 	If the entity is not moving to another tile, snap the entity to the current tile's position, in case the TileMap is moving.
# 	If the entity is moving to another tile, interpolate the entity's position towards the new tile.

# TODO: Set occupancy of each tile along the way in _process()


#region Parameters

@export var tileMap: TileMapLayerWithCustomCellData:
	set(newValue):
		if tileMap != newValue:
			printChange("tileMap", tileMap, newValue)
			tileMap = newValue

@export var setInitialCoordinatesFromEntityPosition: bool = false
@export var initialDestinationCoordinates: Vector2i

## If `false`, the entity will be instantly positioned at the initial destination, otherwise it may be animated from where it was before this component is executed if `shouldMoveInstantly` is false.
@export var shouldSnapToInitialDestination: bool = true

@export var shouldMoveInstantly: bool = false

## The speed of moving between tiles. Ignored if [member shouldMoveInstantly].
## WARNING: If this is slower than the movement of the [member tileMap] then the component will never be able to catch up to the destination tile's position.
@export_range(10.0, 1000.0, 1.0) var speed: float = 200.0

## Should the Cell be marked as [const Global.TileMapCustomData.isOccupied] by the parent Entity?
## Set to `false` to disable occupancy; useful for visual-only entities such as mouse cursors and other UI/effects.
@export var shouldOccupyCell: bool = true

## A [Sprite2D] or any other [Node2D] to temporarily display at the destination tile while moving, such as a square cursor etc.
## NOTE: An example cursor is provided in the component scene but not enabled by default. Enable `Editable Children` to use it.
@export var visualIndicator: Node2D

@export var isEnabled: bool = true

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

# var destinationTileGlobalPosition: Vector2i # NOTE: Not cached because the [TIleMapLayer] may move between frames.

var inputVector: Vector2i
	#set(newValue): # NOTE: This causes "flicker" between 0 and the other value, when reseting the `inputVector`, so just set it manually
		#if newValue != inputVector:
			#previousInputVector = inputVector
			#inputVector = newValue

var previousInputVector: Vector2i

var isMovingToNewCell: bool = false:
	set(newValue):
		if newValue != isMovingToNewCell:
			isMovingToNewCell = newValue
			updateIndicator()

#endregion


#region Signals
signal willStartMovingToNewCell(newDestination: Vector2i)
signal didArriveAtNewCell(newDestination: Vector2i)
#endregion


#region Life Cycle

func _ready() -> void:
	validateTileMap()

	if debugMode:
		self.willStartMovingToNewCell.connect(self.onWillStartMovingToNewTile)
		self.didArriveAtNewCell.connect(self.onDidArriveAtNewTile)

	if tileMap: # If this component was loaded dynamically at runtime, then the tileMap may be set later.
		applyInitialCoordinates()
	
	updateIndicator() # Fix the visually-annoying initial snap from the default position
	self.willRemoveFromEntity.connect(self.onWillRemoveFromEntity)


func onWillRemoveFromEntity() -> void:
	Tools.setCellOccupancy(tileMap, currentCellCoordinates, false, null)

#endregion


#region Validation

## Verifies [member tileMap].
func validateTileMap() -> bool:
	# TODO: If missing, try to use the first [TileMapLayerWithCustomCellData] found in the current scene, if any?

	if not tileMap:
		# printWarning("tileMap not specified! Searching for first TileMapLayerWithCustomCellData in current scene")
		# tileMap = Tools.findFirstChildOfType(get_tree().current_scene, TileMapLayerWithCustomCellData) # WARNING: Caues bugs! When dynamically moving between TileMaps or setting up new entities.
		if not tileMap: printWarning("Missing TileMapLayerWithCustomCellData")
		return false

	if not tileMap is TileMapLayerWithCustomCellData:
		printWarning(str("tileMap is not TileMapLayerWithCustomCellData: ", tileMap))
		return false

	return true


## Ensures that the specified coordinates are within the [TileMapLayer]'s bounds
## and also calls [method checkTileVacancy].
## May be overridden by subclasses to perform additional checks.
## NOTE: Subclasses MUST call super to perform common validation.
func validateCoordinates(coordinates: Vector2i) -> bool:
	var isValidBounds: bool = Tools.checkTileMapBounds(tileMap, coordinates)
	var isTileVacant:  bool = self.checkTileVacancy(coordinates)

	if debugMode: printDebug(str("@", coordinates, ": checkTileMapBounds(): ", isValidBounds, ", checkTileVacancy(): ", isTileVacant))

	return isValidBounds and isTileVacant


## Checks if the tile may be moved into.
## May be overridden by subclasses to perform different checks,
## such as testing custom data on a tile, e.g. [const Global.TileMapCustomData.isWalkable],
## and custom data on a cell, e.g. [const Global.TileMapCustomData.isOccupied],
## or performing a more rigorous physics collision detection.
func checkTileVacancy(coordinates: Vector2i) -> bool:
	# UNUSED: Tools.checkTileCollision(tileMap, parentEntity.body, coordinates) # The current implementation of the Global method always returns `true`.
	return Tools.checkTileVacancy(tileMap, coordinates, self.parentEntity) # Ignore our own entity, just in case :')

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
	if shouldOccupyCell: Tools.setCellOccupancy(tileMap, currentCellCoordinates, true, parentEntity)
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
	# NOTE: Always clear the previous cell even if not `shouldOccupyCell`, in case it is toggled at runtime.
	Tools.setCellOccupancy(tileMap, currentCellCoordinates, false, null)

	# TODO: Occupy each tile along the way in _process()
	if shouldOccupyCell: Tools.setCellOccupancy(tileMap, newDestinationTileCoordinates, true, parentEntity)

	# Should we teleport?

	if shouldMoveInstantly:
		snapEntityPositionToTile(destinationCellCoordinates)

	return true


## Cancels the current move.
func cancelDestination() -> void:
	# Were we on the way to a different destination tile?
	if isMovingToNewCell:
		# Then snap back to the current tile coordinates.
		# TODO: Option to animate back?
		self.snapEntityPositionToTile(self.currentCellCoordinates)

	self.destinationCellCoordinates = self.currentCellCoordinates
	self.isMovingToNewCell = false

#endregion


#region Per-Frame Updates

func _physics_process(delta: float) -> void:
	if not isEnabled: return

	if isMovingToNewCell:
		moveTowardsDestinationTile(delta)
		checkForArrival()
	elif tileMap != null:
		# If we are already at the destination, keep snapping to the current tile coordinates,
		# to ensure alignment in case the TileMap node is moving.
		snapEntityPositionToTile()

	if debugMode: showDebugInfo()


func moveTowardsDestinationTile(delta: float) -> void:
	# TODO: Handle physics collisions
	var destinationTileGlobalPosition: Vector2 = Tools.getCellGlobalPosition(tileMap, self.destinationCellCoordinates) # NOTE: Not cached because the TIleMap may move between frames.
	parentEntity.global_position = parentEntity.global_position.move_toward(destinationTileGlobalPosition, speed * delta)


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
	visualIndicator.global_position = Tools.getCellGlobalPosition(tileMap, self.destinationCellCoordinates)
	visualIndicator.visible = isMovingToNewCell

#endregion


#region Debugging

func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList.entityPosition		= parentEntity.global_position
	Debug.watchList.currentTile			= currentCellCoordinates
	Debug.watchList.vector				= inputVector
	Debug.watchList.previousVector		= previousInputVector
	Debug.watchList.isMovingToNewCell	= isMovingToNewCell
	Debug.watchList.destinationTile		= destinationCellCoordinates
	Debug.watchList.destinationPosition	= Tools.getCellGlobalPosition(tileMap, destinationCellCoordinates)


func onWillStartMovingToNewTile(newDestination: Vector2i) -> void:
	if showDebugInfo: printDebug(str("onWillStartMovingToNewTile(): ", newDestination))


func onDidArriveAtNewTile(newDestination: Vector2i) -> void:
	if showDebugInfo: printDebug(str("onDidArriveAtNewTile(): ", newDestination))

#endregion
