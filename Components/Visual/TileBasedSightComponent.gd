## Determines a character's field of vision in a tile-based game, based on the Entity's coordinates on a [TileMapLayer] grid via a [TileBasedPositionComponent]
## Assigns each TileMap cell with a "visibility level" from 1.0 at the Entity's origin to 0.0 at the cell outside the assigned [member sightRange]
## The vision values may represent brightness from light sources, or fog etc.
## NOTE: Does NOT apply any visual effects; this is a DATA-ONLY component that only keeps track of the visibility/"light" level to apply to each [TileMapLayer] cell.
## TIP: Other nodes may use this component's data to build a "darkness" overlay or determine the ability to choose starget etc.
## Requires: [TileBasedPositionComponent]
## @experimental

class_name TileBasedSightComponent
extends Component

# DESIGN: The root Node type of this component's Scene should be [Node2D] in case subclasses want to include internal visual effects.


#region Parameters

## The maximum sight range in number of [TileMapLayer] cells, centered on the Entity's [TileBasedPositionComponent] coordinates.
## [member rangeShape] determines whether this value represents the length of a square's sides or the radius of a circle.
## THe cell at the Entity's position will have a "visibility level" value of 1.0
## The first and subsequent [TileMapLayer] cells at this range away from the Entity will have a visibility of 0.0
@export_range(1, 64, 1) var sightRange: int = 8

## ALERT: Only [enum Tools.Shape.rectangle] or [enum Tools.Shape.circle] are valid options here.
@export var rangeShape: Tools.Shape = Tools.Shape.rectangle

## Scales each [TileMapLayer] cell's "visiblity level" as recorded in [member cellVisibilityLevels]
## This scalar may be positive or negative, effectively buffing or debuffing the player's vision.
@export_range(-2.0, 2.0, 0.01, "or_less", "or_greater") var cellVisibilityMultiplier: float = 1.0

@export_range(0.0, 1.0, 0.01,  "or_less", "or_greater") var minVisibility: float = 0.0 ## Clamps each cell's visibility level after applying the [member sightRange] & [member cellVisibilityMultiplier]
@export_range(0.0, 1.0, 0.01,  "or_less", "or_greater") var maxVisibility: float = 1.0 ## Clamps each cell's visibility level after applying the [member sightRange] & [member cellVisibilityMultiplier]

## If `true`, vision updates will use [member TileBasedPositionComponent.destinationCoordinates] when [signal TileBasedPositionComponent.willStartMovingToNewCell]
@export var shouldUseDestinationWhenMoving: bool = false

@export var isEnabled: bool = true # TODO: Recalculate vision when re-enabled

#endregion


#region State
## A [Dictionary] representing a grid: `{Coordinates : Cell Visibility Level}`
## Each (x,y) [Vector2i] coordinate key contains a [float] value ranging from 0.0 to 1.0 (or clamped to [member minVisibility] & [member minVisibility]) .
var cellVisibilityLevels: Dictionary[Vector2i, float] # TBD: `@export_storage`?
#endregion


#region Signals
signal didUpdateCellVisibility
#endregion


#region Dependencies
@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent
#endregion


#region initialization

func _ready() -> void:
	if tileBasedPositionComponent: connectSignals()
	else: printWarning(str("Missing TileBasedPositionComponent in parentEntity: ", parentEntity.logFullName))


func connectSignals() -> void:
	Tools.connectSignal(tileBasedPositionComponent.willStartMovingToNewCell, self.ontileBasedPositionComponent_willStartMovingToNewCell)
	Tools.connectSignal(tileBasedPositionComponent.didArriveAtNewCell, self.ontileBasedPositionComponent_didArriveAtNewCell)

#endregion


#region Events

func ontileBasedPositionComponent_willStartMovingToNewCell() -> void:
	if shouldUseDestinationWhenMoving: updateCellVisibilityInRange()


func ontileBasedPositionComponent_didArriveAtNewCell() -> void:
	# TBD: Should we check `if not shouldUseDestinationWhenMoving` because we already updated on `willStartMovingToNewCell`?
	updateCellVisibilityInRange()

#endregion


#region Sight & Visibility

## Updates [member cellVisibilityLevels] for all the [TileMapLayer] cells within the [member sightRange] of the Entity's [TileBasedPositionComponent] coordinates.
## @experimental
func updateCellVisibilityInRange() -> void:
	# TODO: Implement
	pass


## Sets the visibility level for a single [TileMapLayer] cell at the specified offset from the Entity's [TileBasedPositionComponent] coordinates.
## i.e. an offset of (0,-1) means directly to the top of the Entity, and so on.
## Multiplied by [member cellVisibilityMultiplier] and clamped by [member minVisibility] & [member maxVisibility]
func setCellVisibilityAtOffset(xOffset: int, yOffset: int, visibilityLevel: float) -> void:
	# TBD: Return the change in visibility?
	var entityCoordinates: Vector2i = tileBasedPositionComponent.currentCoordinates if not shouldUseDestinationWhenMoving else tileBasedPositionComponent.destinationCoordinates
	var offsetCoordinates: Vector2i = entityCoordinates + Vector2i(xOffset, yOffset)
	cellVisibilityLevels[offsetCoordinates] = clampf(visibilityLevel * cellVisibilityMultiplier, minVisibility, maxVisibility)


## Returns the visibility level for a single [TileMapLayer] cell at the specified offset from the Entity's [member tileBasedPositionComponent.currentCoordinates]
## i.e. an offset of (0,-1) means directly to the top of the Entity, and so on.
## Multiplied by [member cellVisibilityMultiplier] and clamped by [member minVisibility] & [member maxVisibility]
func getCellVisibilityAtOffset(xOffset: int, yOffset: int) -> float:
	var entityCoordinates: Vector2i = tileBasedPositionComponent.currentCoordinates if not shouldUseDestinationWhenMoving else tileBasedPositionComponent.destinationCoordinates
	var offsetCoordinates: Vector2i = entityCoordinates + Vector2i(xOffset, yOffset)
	if  cellVisibilityLevels.has(offsetCoordinates):
		return clampf(cellVisibilityLevels[offsetCoordinates] * cellVisibilityMultiplier, minVisibility, maxVisibility)
	else:
		return NAN

#endregion