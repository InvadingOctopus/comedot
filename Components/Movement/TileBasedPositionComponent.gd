## Sets the position of the parent Entity to the position of a tile in an associated [TileMapLayer].
## Does NOT receive player control input, or perform path-finding or any other validation logic
## except checking the tile map bounds and tile collision.
## NOTE: To provide player input, use [TileBasedControlComponent].

class_name TileBasedPositionComponent
extends Component

# PLAN:
# * Store integer coordinates to remember which tile the entity is in.
# * Every frame,
# 	If the entity is not moving to another tile, snap the entity to the current tile's position, in case the TileMap is moving.
# 	If the entity is moving to another tile, interpolate the entity's position towards the new tile.

# TODO: Set occupancy of each tile along the way in _process()


#region Parameters

@export var tileMap: TileMapLayerWithCustomCellData
@export var initialDestinationCoordinates: Vector2i

## If `false`, the entity will be instantly positioned at the initial destination, otherwise it may be animated from where it was before this component is executed if `shouldMoveInstantly` is false.
@export var shouldSnapToInitialDestination: bool = true

@export var shouldMoveInstantly: bool = false

## The speed of moving between tiles. Ignored if [member shouldMoveInstantly].
## WARNING: If this is slower than the movement of the [member tileMap] then the component will never be able to catch up to the destination tile's position.
@export_range(10.0, 1000.0, 1.0) var speed: float = 200.0

## A [Sprite2D] or any other [Node2D] to temporarily display at the destination tile while moving, such as a square cursor etc.
## NOTE: An example cursor is provided in the component scene but not enabled by default. Enable `Editable Children` to use it.
@export var visualIndicator: Node2D

@export var isEnabled: bool = true
@export var shouldShowDebugInfo: bool = false

#endregion


#region State

# TODO: TBD: @export_storage

var currentTileCoordinates: Vector2i:
	set(newValue):
		if newValue != currentTileCoordinates:
			if shouldShowDebugInfo: printDebug(str("currentTileCoordinates: ", currentTileCoordinates, " → ", newValue))
			currentTileCoordinates = newValue

var destinationTileCoordinates: Vector2i:
	set(newValue):
		if newValue != destinationTileCoordinates:
			if shouldShowDebugInfo: printDebug(str("destinationTileCoordinates: ", destinationTileCoordinates, " → ", newValue))
			destinationTileCoordinates = newValue

# var destinationTileGlobalPosition: Vector2i # NOTE: Not cached because the [TIleMapLayer] may move between frames.

var inputVector: Vector2i
	#set(newValue): # NOTE: This causes "flicker" between 0 and the other value, when reseting the `inputVector`, so just set it manually
		#if newValue != inputVector:
			#previousInputVector = inputVector
			#inputVector = newValue

var previousInputVector: Vector2i

var isMovingToNewTile: bool = false:
	set(newValue):
		if newValue != isMovingToNewTile:
			isMovingToNewTile = newValue
			updateIndicator()

#endregion


#region Signals
signal willStartMovingToNewTile(newDestination: Vector2i)
signal didArriveAtNewTile(newDestination: Vector2i)
#endregion


func _ready() -> void:
	if not tileMap: printError("tileMap not specified!")
	
	# Get the entity's starting coordinates
	updateCurrentTileCoordinates()
	
	# NOTE: Directly setting `destinationTileCoordinates = initialDestinationCoordinates` beforehand prevents the movement
	# because the functions check for a change between coordinates.
	
	if shouldSnapToInitialDestination:
		snapEntityPositionToTile(initialDestinationCoordinates)
	else: 
		setDestinationTileCoordinates(initialDestinationCoordinates)

	
	
	if shouldShowDebugInfo:
		self.willStartMovingToNewTile.connect(self.onWillStartMovingToNewTile)
		self.didArriveAtNewTile.connect(self.onDidArriveAtNewTile)


## Set the tile coordinates corresponding to the parent Entity's [member Node2D.global_position]
## and set the cell's occupancy.
func updateCurrentTileCoordinates() -> Vector2i:
	self.currentTileCoordinates = tileMap.local_to_map(tileMap.to_local(parentEntity.global_position))
	Global.setTileOccupancy(tileMap, currentTileCoordinates, true, parentEntity)
	return currentTileCoordinates 


## Instantly sets the entity's position to a tile's position.
## If [param destinationOverride] is omitted then [member currentTileCoordinates] is used.
func snapEntityPositionToTile(tileCoordinates: Vector2i = self.currentTileCoordinates) -> void:
	if not isEnabled: return

	var tileGlobalPosition: Vector2 = Global.getTileGlobalPosition(tileMap, tileCoordinates)

	if parentEntity.global_position != tileGlobalPosition:
		parentEntity.global_position = tileGlobalPosition
	
	self.currentTileCoordinates = tileCoordinates


## This method must be called by a control component upon receiving player input.
## EXAMPLE: `inputVector = Vector2i(Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown))`
func processMovementInput(inputVectorOverride: Vector2i = self.inputVector) -> void:
	# TODO: Check for TileMap bounds.
	# Don't accept input if already moving to a new tile.
	if (not isEnabled) or self.isMovingToNewTile: return
	setDestinationTileCoordinates(self.currentTileCoordinates + inputVectorOverride)


## Returns: `false if the new destination coordinates are not valid within the TileMap bounds.
func setDestinationTileCoordinates(newDestinationTileCoordinates: Vector2i) -> bool:

	# Is the new destination the same as the current destination? Then there's nothing to change.
	if newDestinationTileCoordinates == self.destinationTileCoordinates: return true

	# Is the new destination the same as the current tile? i.e. was the previous move cancelled?
	if newDestinationTileCoordinates == self.currentTileCoordinates:
		cancelDestination()
		return true # NOTE: Return true because arriving at the specified coordinates should be considered a success, even if already there. :)

	# Validate the new destination?
	
	if not validateCoordinates(newDestinationTileCoordinates):
		return false
	
	# Move Your Body ♪
	
	willStartMovingToNewTile.emit(newDestinationTileCoordinates)
	self.destinationTileCoordinates = newDestinationTileCoordinates
	self.isMovingToNewTile = true
	
	# Vacate the current (to-be previous) tile
	Global.setTileOccupancy(tileMap, currentTileCoordinates, false, null)
	
	# TODO: Occupy each tile along the way in _process()
	Global.setTileOccupancy(tileMap, newDestinationTileCoordinates, true, parentEntity)
	
	# Should we teleport?
	
	if shouldMoveInstantly:
		snapEntityPositionToTile(destinationTileCoordinates)
	
	return true


## Ensures that the specified coordinates are within the [TileMapLayer]'s bounds
## and also calls [method checkCollision].
## May be overridden by subclasses to perform additional checks.
## NOTE: Subclasses MUST call super to perform common validation.
func validateCoordinates(coordinates: Vector2i) -> bool:
	var isValidBounds: bool = Global.checkTileMapBounds(tileMap, coordinates)
	var isTileVacant: bool = self.checkTileVacancy(coordinates)
	
	if shouldShowDebugInfo: printDebug(str("@", coordinates, ": checkTileMapBounds(): ", isValidBounds, ", checkTileVacancy(): ", isTileVacant))
		
	return isValidBounds and isTileVacant


## Checks if the tile may be moved into.
## May be overridden by subclasses to perform different checks, 
## such as testing custom data on a tile, like [const Global.TileMapCustomData.isWalkable],
## or performing a more rigorous physics collision detection.
func checkTileVacancy(coordinates: Vector2i) -> bool:
	# UNUSED: Global.checkTileCollision(tileMap, parentEntity.body, coordinates) # The current implementation of the Global method always returns `true`. 
	return Global.checkTileVacancy(tileMap, coordinates) 


## Cancels the current move.
func cancelDestination() -> void:
	# Were we on the way to a different destination tile?
	if isMovingToNewTile:
		# Then snap back to the current tile coordinates.
		# TODO: Option to animate back?
		self.snapEntityPositionToTile(self.currentTileCoordinates)

	self.destinationTileCoordinates = self.currentTileCoordinates
	self.isMovingToNewTile = false
	

func _physics_process(delta: float) -> void:
	if not isEnabled: return
	
	if isMovingToNewTile:
		moveTowardsDestinationTile(delta)
		checkForArrival()
	else:
		# If we are already at the destination, keep snapping to the current tile coordinates,
		# to ensure alignment in case the TileMap node is moving.
		snapEntityPositionToTile()

	if shouldShowDebugInfo: showDebugInfo()


func moveTowardsDestinationTile(delta: float) -> void:
	# TODO: Handle physics collisions
	var destinationTileGlobalPosition: Vector2 = Global.getTileGlobalPosition(tileMap, self.destinationTileCoordinates) # NOTE: Not cached because the TIleMap may move between frames.
	parentEntity.global_position = parentEntity.global_position.move_toward(destinationTileGlobalPosition, speed * delta)


## Are we there yet?
func checkForArrival() -> bool:
	var destinationTileGlobalPosition: Vector2 = Global.getTileGlobalPosition(tileMap, self.destinationTileCoordinates)
	if parentEntity.global_position == destinationTileGlobalPosition:
		self.currentTileCoordinates = self.destinationTileCoordinates
		self.isMovingToNewTile = false
		didArriveAtNewTile.emit(currentTileCoordinates)
		previousInputVector = inputVector
		inputVector = Vector2i.ZERO
		return true
	else:
		self.isMovingToNewTile = true
		return false


func updateIndicator() -> void:
	if not visualIndicator: return
	visualIndicator.global_position = Global.getTileGlobalPosition(tileMap, self.destinationTileCoordinates)
	visualIndicator.visible = isMovingToNewTile


func showDebugInfo() -> void:
	if not shouldShowDebugInfo: return
	Debug.watchList.entityPosition		= parentEntity.global_position
	Debug.watchList.currentTile			= currentTileCoordinates
	Debug.watchList.vector				= inputVector
	Debug.watchList.previousVector		= previousInputVector
	Debug.watchList.isMovingToNewTile	= isMovingToNewTile
	Debug.watchList.destinationTile		= destinationTileCoordinates
	Debug.watchList.destinationPosition	= Global.getTileGlobalPosition(tileMap, destinationTileCoordinates)


func onWillStartMovingToNewTile(newDestination: Vector2i) -> void:
	if showDebugInfo: printDebug(str("onWillStartMovingToNewTile(): ", newDestination))


func onDidArriveAtNewTile(newDestination: Vector2i) -> void:
	if showDebugInfo: printDebug(str("onDidArriveAtNewTile(): ", newDestination))
