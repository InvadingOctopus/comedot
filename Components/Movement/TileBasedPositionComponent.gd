## Sets the position of the parent Entity to the position of a tile in an associated [TileMapLayer]
## Does NOT perform path-finding or any other validation logic except checking the TileMap bounds.


class_name TileBasedPositionComponent
extends Component


#region Parameters

# TODO: Optional choice between animating or snapping to initial coordinates.

@export var tileMap: TileMapLayer
@export var initialTileCoordinates: Vector2i

## The speed of moving between tiles.
@export_range(10.0, 1000.0, 1.0) var speed: float = 200.0

@export var isEnabled := true
#endregion


#region State

var currentTileCoordinates: Vector2i
var destinationTileCoordinates: Vector2i

# var destinationTileGlobalPosition: Vector2i # NOTE: Not cached because the TIleMap may move between frames.

var isMovingToNewTile: bool = false
#endregion


#region Signals
signal willStartMovingToNewTile(newDestination: Vector2i)
signal didArriveAtNewTile(newDestination: Vector2i)
#endregion


func _ready():
	if not tileMap: printError("tileMap not specified!")
	self.destinationTileCoordinates = initialTileCoordinates
	snapEntityPositionToTile()


func _input(event: InputEvent):
	# TODO: Improve

	# Don't accept input if already moving to a new tile.

	if (not isEnabled) or self.isMovingToNewTile or (not event.is_action_type()): return

	# NOTE: DESIGN: We don't want only "input released" events; movement must begin as soon as a button is pressed.

	var inputVector: Vector2 = Input.get_vector(GlobalInput.Actions.moveLeft, GlobalInput.Actions.moveRight, GlobalInput.Actions.moveUp, GlobalInput.Actions.moveDown)
	processMovementInput(Vector2i(inputVector))


func processMovementInput(inputVector: Vector2i):
	# TODO: Check for TileMap bounds.
	# Don't accept input if already moving to a new tile.
	if (not isEnabled) or self.isMovingToNewTile: return
	setDestinationTileCoordinates(self.currentTileCoordinates + Vector2i(inputVector))


## Returns: `false if the new destination coordinates are not valid within the TileMap bounds.
func setDestinationTileCoordinates(newDestinationTileCoordinates: Vector2i) -> bool:

	# Is the new destination the same as the current destination? Then there's nothing to change.
	if newDestinationTileCoordinates == self.destinationTileCoordinates: return true

	# Is the new destination the same as the current tile? i.e. was the previous move cancelled?
	if newDestinationTileCoordinates == self.currentTileCoordinates:
		cancelDestination()
		return true # Done!

	# Do we have a new destination?

	# TODO: Validate TileMap bounds

	self.destinationTileCoordinates = newDestinationTileCoordinates
	self.isMovingToNewTile = true

	return true


## Cancels the current move.
func cancelDestination():
	# Were we on the way to a different destination tile?
	if isMovingToNewTile:
		# Then snap back to the current tile coordinates.
		# TODO: Option to animate back?
		self.snapEntityPositionToTile(self.currentTileCoordinates)

	self.destinationTileCoordinates = self.currentTileCoordinates
	self.isMovingToNewTile = false


func _process(delta: float):
	if not isEnabled: return

	# Keep snapping to the current tile coordinates,
	# to ensure alignment in case the TileMap node is moving.

	moveTowardsDestinationTile(delta) # or snapEntityPositionToTile()
	checkForArrival()


func moveTowardsDestinationTile(delta: float):
	var destinationTileGlobalPosition: Vector2 = getTileGlobalPosition(self.destinationTileCoordinates) # NOTE: Not cached because the TIleMap may move between frames.
	parentEntity.global_position = parentEntity.global_position.move_toward(destinationTileGlobalPosition, speed * delta)


## Instantly sets the entity's position to a tile's position.
## If [param destinationOverride] is omitted then [member destinationTileCoordinates] is used.
func snapEntityPositionToTile(destinationOverride: Vector2i = self.destinationTileCoordinates):
	if not isEnabled: return
	var destination: Vector2i = destinationOverride if destinationOverride else self.destinationTileCoordinates

	var destinationTileGlobalPosition: Vector2 = getTileGlobalPosition(destination)

	if parentEntity.global_position != destinationTileGlobalPosition:
		parentEntity.global_position = destinationTileGlobalPosition


func getTileGlobalPosition(tileCoordinates: Vector2i) -> Vector2:
	var tilePosition: Vector2 = tileMap.map_to_local(tileCoordinates)
	var tileGlobalPosition: Vector2 = tileMap.to_global(tilePosition)
	return tileGlobalPosition


## Are we there yet?
func checkForArrival() -> bool:
	var destinationTileGlobalPosition: Vector2 = getTileGlobalPosition(self.destinationTileCoordinates)
	if parentEntity.global_position == destinationTileGlobalPosition:
		self.currentTileCoordinates = self.destinationTileCoordinates
		self.isMovingToNewTile = false
		return true
	else:
		self.isMovingToNewTile = true
		return false
