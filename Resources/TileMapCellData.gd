## Stores custom data during runtime for each cell of a [TileMapLayer].
## Used by components such as [TileBasedPositionComponent] e.g. to determine whether a cell is currently occupied or its remaining "health" if it's destructible.
## NOTE: "CELLS" are the individual grid elements, NOT the "TILES";
## Tiles are the permanent resources in a [TileSet]. A single Tile is used to paint multiple Cells of a [TileMapLayer].
## [TileSet]s can specify custom data per Tile, but a [TileMapLayer] cannot add custom data per grid Cell without this script.
## For a standalone [TileMapLayer] with built-in support for custom data, see [TileMapLayerWithCellData]

class_name TileMapCellData
extends Resource


#region Parameters & State

## A Dictionary of Dictionaries. { CellCoordinates : {Key : Value} }
## Each (x,y) [Vector2i] coordinate key contains a Dictionary of {[StringName]: [Variant]}.
## NOTE: This data is set dynamically during gameplay by components such as [TileBasedPositionComponent] e.g. to determine whether a cell is currently occupied or not.
@export_storage var gridDictionary: Dictionary[Vector2i, Dictionary]

@export var debugMode: bool = false

#endregion


#region State
# UNUSED: BUGRISK: May cuase circular-references & memory leaks, with little utility: var associatedTileMaps: Array[TileMapLayer] ## The list of [TileMapLayer]s that this data structure represents. Set by [TileBasedPositionComponent] etc.
#endregion


#region Data Interface

func setCellData(coordinates: Vector2i, key: StringName, value: Variant) -> void:
	if debugMode: Debug.printDebug(str("setCellData() @", coordinates, " ", key, " = ", value), self)

	# NOTE: Do NOT assign an entire dictionary here or that will override all other keys!

	# Get the data dictionary for the cell, or add an empty dictionary.
	var cellData: Variant = gridDictionary.get_or_add(coordinates, {}) # Cannot type this as a `Dictionary` if the coordinate key is missing :(

	cellData[key] = value


## Returns the value for the [param key] stored in the cell at [param coordinates]
## ALERT: Make sure the cell data exists by callig [method hasCellData] first! Otherwise a missing cell will also return `null`, which is indistinguishable from a cell that exists but has `null` as its data! 
func getCellData(coordinates: Vector2i, key: StringName) -> Variant:
	if not gridDictionary.has(coordinates):
		if debugMode: Debug.printDebug(str("getCellData() @", coordinates, ": gridDictionary has no such key!"), self)
		return null

	var cellData: Variant = gridDictionary.get(coordinates) # Cannot type this as a `Dictionary` if the coordinate key is missing :(
	var value:    Variant

	# The "grid" is a [Dictionary] of "cells" and each cell must also have a [Dictionary] of values
	# So if a cell does not have a [Dictionary] as its value, return `null`
	if cellData is Dictionary: value = (cellData as Dictionary).get(key)
	else: value = null

	if debugMode: Debug.printDebug(str("getCellData() @", coordinates, " ", key, ": ", value), self)
	return value


## Returns whether a cell has been associated with a [Dictionary], and that the [Dictionary] has the specified [param key], even if it's `null`
## which is different from the cell or key never having been set i.e. the [member gridDictionary] never having such a [Vector2i] key.
## If [param key] is omitted, then only the existence of the [param coordinates] is checked.
func hasCellData(coordinates: Vector2i, key: StringName = "") -> bool:
	if not gridDictionary.has(coordinates): return false
	if not key.is_empty():
		var cellData: Variant = gridDictionary[coordinates]
		return cellData is Dictionary \
			and (cellData as Dictionary).has(key)
	else:
		return true # If no `key` has been asked, but a cell with `coordinates` exists, then return `true`


## Deletes the specified [Dictionary] [param key] from the corresponding [Vector2i] cell.
## If [param key] is empty, the ENTIRE cell and ALL its data is deleted from the [member gridDictionary]
## Returns `true` if the cell/key previously existed, or `false` if the [member gridDictionary] did not have a matching [Vector2i] key, if the cell's [Dictionary] did not have the specified [param key]
func eraseCellData(coordinates: Vector2i, key: StringName) -> bool:
	if not gridDictionary.has(coordinates): return false
	if not key.is_empty():
		var cellData: Variant = gridDictionary.get(coordinates) # Cannot type this as a `Dictionary` if the coordinate key is missing :(
		if cellData is Dictionary: return cellData.erase(key)
		else: return false
	else: # If there is no `key` then delete the ENTIRE cell and ALL its data!
		return gridDictionary.erase(coordinates)

#endregion
