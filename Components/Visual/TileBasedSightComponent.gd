## Determines a character's field of vision in a tile-based game, based on the Entity's coordinates on a [TileMapLayer] grid via a [TileBasedPositionComponent]
## Assigns each TileMap cell with a "visibility" or "brightness" level from 1.0 at the Entity's origin to 0.0 at the cell outside the assigned [member sightRange]
## The vision values may represent brightness from light sources, or fog etc.
## NOTE: Does NOT apply any visual effects; this is a DATA-ONLY component that only keeps track of the visibility/"light" level to apply to each [TileMapLayer] cell.
## TIP: Other nodes may use this component's data to build a "darkness" overlay or determine the ability to choose targets etc.
## Requires: [TileBasedPositionComponent]
## @experimental

class_name TileBasedSightComponent
extends Component

# DESIGN: The root Node type of this component's Scene should be [Node2D] in case subclasses want to include internal visual effects.
# DESIGN: The ideal goal is to let different Entities have a different "sight map", instead of just directly modifying the main [TileMapLayer] TileSet etc.
# For example, the player character may have vision around itself and around burning torches, but a certain kind of monster may be blind in torchlight,
# so they would each have different `cellVisibilityLevels`

#region Parameters

## The maximum sight range in number of [TileMapLayer] cells, centered on the Entity's [TileBasedPositionComponent] coordinates.
## [member rangeShape] determines whether this value represents the radius of a circle or half the length of a square's sides.
## The cell at the Entity's position will have a "visibility/brightness level" value of 1.0
## The first and subsequent [TileMapLayer] cells at this range away from the Entity will have a visibility of 0.0
@export_range(1, 64, 1) var sightRange: int = 8

## ALERT: Only [enum Tools.Shape.rectangle] or [enum Tools.Shape.circle] are valid options here.
@export var rangeShape: Tools.Shape = Tools.Shape.rectangle

## Sets the value in [member cellVisibilityLevels] at & above which a [TileMapLayer] cell will be considered "in sight" of the Entity.
## Other components & scripts may use this value to omit some cells from being rendered onscreen or be chosen as targets etc.
@export_range(0.0, 1.0, 0.01,  "or_less", "or_greater") var cellSightThreshold: float = 0.9

## Scales each [TileMapLayer] cell's "visibility/brightness" level as recorded in [member cellVisibilityLevels]
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
## Each (x,y) [Vector2i] coordinate key contains a [float] value ranging from 0.0 to 1.0 (or clamped to [member minVisibility] & [member maxVisibility]).
## DESIGN: This is not simply called a "brightness" level because it may used for other situations besides light/dark, such as fog etc..
## NOTE: This does NOT directly affect the onscreen RENDERING of the [TileMapLayer] unless other scripts use this data to affect rendering.
var cellVisibilityLevels: Dictionary[Vector2i, float] # TBD: `@export_storage`?
#endregion


#region Signals
signal didUpdateCellsInRange
#endregion


#region Dependencies
@onready var tileBasedPositionComponent: TileBasedPositionComponent = coComponents.TileBasedPositionComponent

func getRequiredComponents() -> Array[Script]:
	return [TileBasedPositionComponent]
#endregion


#region initialization

func _ready() -> void:
	if tileBasedPositionComponent: connectSignals()
	else: printWarning(str("Missing TileBasedPositionComponent in parentEntity: ", parentEntity.logFullName))


func connectSignals() -> void:
	Tools.connectSignal(tileBasedPositionComponent.willStartMovingToNewCell, self.onTileBasedPositionComponent_willStartMovingToNewCell)
	Tools.connectSignal(tileBasedPositionComponent.didArriveAtNewCell,		 self.onTileBasedPositionComponent_didArriveAtNewCell)

#endregion


#region Events

func onTileBasedPositionComponent_willStartMovingToNewCell(_newDestination: Vector2i) -> void:
	if not isEnabled: return
	if shouldUseDestinationWhenMoving: updateCellsInRange()


func onTileBasedPositionComponent_didArriveAtNewCell(_newDestination: Vector2i) -> void:
	if not isEnabled: return
	# TBD: Should we check `if not shouldUseDestinationWhenMoving` because we already updated on `willStartMovingToNewCell`?
	updateCellsInRange()

#endregion


#region Sight & Visibility

## Updates [member cellVisibilityLevels] for all the [TileMapLayer] cells within the [member sightRange] of the Entity's [TileBasedPositionComponent] coordinates.
## NOTE: Affected by [member isEnabled]
## @experimental
func updateCellsInRange() -> void:
	# TODO: Implement
	if not isEnabled: return
	didUpdateCellsInRange.emit()


## Calculates the visibility level associated for a single [TileMapLayer] cell at the specified coordinates,
## based on the cell's distance within the [member sightRange] from the Entity's [TileBasedPositionComponent] coordinates.
## NOTE: NOT affected by [member isEnabled]
## @experimental
func calculateVisibilityForCell(coordinates: Vector2i, shouldModifyState: bool = true) -> float:
	# TODO: Implement
	var visibility: float = 1.0
	if shouldModifyState: self.setCellVisibility(coordinates, visibility)
	return visibility


## Sets the visibility level associated with a single [TileMapLayer] cell at the specified coordinates in [member cellVisibilityLevels]
## Multiplied by [member cellVisibilityMultiplier] and clamped by [member minVisibility] & [member maxVisibility]
## NOTE: NOT affected by [member isEnabled]
func setCellVisibility(coordinates: Vector2i, visibilityLevel: float) -> void:
	# TBD: Return the change in visibility?
	cellVisibilityLevels[coordinates] = clampf(visibilityLevel * cellVisibilityMultiplier, minVisibility, maxVisibility)


## Sets the visibility level associated with a single [TileMapLayer] cell at the specified offset from the Entity's [TileBasedPositionComponent] coordinates.
## i.e. an offset of (0,-1) means directly to the top of the Entity, and so on.
## Multiplied by [member cellVisibilityMultiplier] and clamped by [member minVisibility] & [member maxVisibility]
## NOTE: NOT affected by [member isEnabled]
func setCellVisibilityAtOffset(offset: Vector2i, visibilityLevel: float) -> void:
	var entityCoordinates: Vector2i = tileBasedPositionComponent.currentCoordinates if not shouldUseDestinationWhenMoving else tileBasedPositionComponent.destinationCoordinates
	setCellVisibility(entityCoordinates + offset, visibilityLevel)


## Returns the visibility level associated with a single [TileMapLayer] cell at the specified coordinates from [member cellVisibilityLevels]
## Returns NAN if the cell was never stored in [member cellVisibilityLevels]
## NOTE: NOT affected by [member isEnabled]
func getCellVisibility(coordinates: Vector2i) -> float:
	if cellVisibilityLevels.has(coordinates): return cellVisibilityLevels[coordinates] # NOTE: `cellVisibilityMultiplier` & clamping should have been applied already when setting the visibility values.
	else: return NAN


## Returns the visibility level associated with a single [TileMapLayer] cell at the specified offset from the Entity's [member tileBasedPositionComponent] coordinates.
## i.e. an offset of (0,-1) means directly to the top of the Entity, and so on.
## Returns NAN if the cell was never stored in [member cellVisibilityLevels]
## NOTE: NOT affected by [member isEnabled]
func getCellVisibilityAtOffset(offset: Vector2i) -> float:
	var entityCoordinates: Vector2i = tileBasedPositionComponent.currentCoordinates if not shouldUseDestinationWhenMoving else tileBasedPositionComponent.destinationCoordinates
	return getCellVisibility(entityCoordinates + offset)


## Returns `true` if the visibility level associated with the specified [TileMapLayer] cell is at or above [member cellSightThreshold]
## Returns `false` if the cell was never stored in [member cellVisibilityLevels]
## NOTE: NOT affected by [member isEnabled]
func isCellInSight(coordinates: Vector2i) -> bool:
	if not cellVisibilityLevels.has(coordinates): return false
	var visibilityLevel: float = getCellVisibility(coordinates)
	return visibilityLevel > self.cellSightThreshold or is_equal_approx(visibilityLevel, self.cellSightThreshold)


## Returns `true` if the visibility level associated with a [TileMapLayer] cell is at or above [member cellSightThreshold]
## The offset is relative to the Entity's [member tileBasedPositionComponent] coordinates, e.g. an offset of (0,-1) means directly to the top of the Entity.
## Returns `false` if the cell was never stored in [member cellVisibilityLevels]
## NOTE: NOT affected by [member isEnabled]
func isCellInSightAtOffset(offset: Vector2i) -> bool:
	var entityCoordinates: Vector2i = tileBasedPositionComponent.currentCoordinates if not shouldUseDestinationWhenMoving else tileBasedPositionComponent.destinationCoordinates
	return isCellInSight(entityCoordinates + offset)


## Copies the [member cellVisibilityLevels] TO the [TileMapLayer] [TileMapCellData] associated with the [TileBasedPositionComponent]
## NOTE: NOT affected by [member isEnabled]
## @experimental
func applyVisibilityLevelsToTileMapData() -> void:
	var tileMapData: TileMapCellData = tileBasedPositionComponent.tileMapData
	if not tileMapData: 
		printWarning("TileBasedPositionComponent missing TileMapCellData")
		return
	# TODO: Implement


## Replaces the [member cellVisibilityLevels] with visibility data FROM the [TileMapLayer] [TileMapCellData] associated with the [TileBasedPositionComponent]
## NOTE: NOT affected by [member isEnabled]
## @experimental
func getVisibilityLevelsFromTileMapData() -> void:
	var tileMapData: TileMapCellData = tileBasedPositionComponent.tileMapData
	if not tileMapData: 
		printWarning("TileBasedPositionComponent missing TileMapCellData")
		return
	# TODO: Implement

#endregion
