## Moves in a straight line in one of the 8 compass directions on a [TileMapLayer] grid.
## Requirements: [TileBasedPositionComponent]

class_name TileBasedLinearMotionComponent
extends Component


#region Parameters

## The "speed" scalar to multiply [member direction] by.
## WARNING: A non‑integer scale may truncate the distance (e.g. 0.5 → 0) causing [method move] to  fail!
## NOTE: Tiles "in the way" are not checked whether they are blocked or vacant; the entity will effectively "teleport" to the destination cell.
@export_range(-10, 10, 0.5) var movementScale: float = 1.0 # TBD: Should this be integer only?

## One of the 8 compass directions. Multiplied by [member movementScale].
@export var direction: Vector2i = Vector2i.ZERO

@export var isEnabled: bool = true

#endregion


#region Signals
## Emitted if [method TileBasedPositionComponent.validateCoordinates] or [method TileBasedPositionComponent.setDestinationCoordinates] fails
## after calling [method move] with a non-zero [member direction] and [member movementScale].
## This may indicate cases like reaching the edge of the board or not having an unoccupied cell to move into.
signal didFailToMove
#endregion


#region Dependencies

@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent

## Returns a list of required component types that this component depends on.
func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent]

#endregion


## Uses the [TileBasedPositionComponent] to reposition the entity to the new [TileMapLayer] coordinates as specified by [member direction] or [param directionOverride], multiplied by [member movementScale].
## Returns the DIFFERENCE (offset) between the previous and the (attempted) new cell coordinates.
## TIP: May be wired up to a [signal Timer.timeout] to repeat the movement.
func move(directionOverride: Vector2i = self.direction) -> Vector2i:
	if not isEnabled: return Vector2i.ZERO

	var offset: Vector2i = directionOverride * movementScale

	# Some checks and warnings to catch potentially tricky bugs
	if debugMode:
		printDebug(str("move() ", directionOverride, " * ", movementScale, " = ", offset))
		if not tileBasedPositionComponent.isEnabled: printWarning(str("TileBasedPositionComponent is disabled: ", tileBasedPositionComponent))
		if tileBasedPositionComponent.isMovingToNewCell:
			printWarning(str("move() called while TileBasedPositionComponent.isMovingToNewCell: ", tileBasedPositionComponent.currentCoordinates, " → ", tileBasedPositionComponent.destinationCoordinates))

	if offset.length_squared() > 0: # Is there a non-zero distance to move?
		var previousCoordinates:Vector2i = tileBasedPositionComponent.currentCoordinates
		var newCoordinates:		Vector2i = previousCoordinates + offset

		if debugMode: emitDebugBubble(str(previousCoordinates, "->", newCoordinates), randomDebugColor, true) # emitFromEntity

		if tileBasedPositionComponent.validateCoordinates(newCoordinates):
			if not tileBasedPositionComponent.setDestinationCoordinates(newCoordinates):
				didFailToMove.emit() # Coordinates valid but setting the destination failed?
		else:
			didFailToMove.emit() # Coordinates invalid?

	return offset
