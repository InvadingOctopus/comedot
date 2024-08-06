## Stores custom data during runtime for the individual cells of a [TileMapLayer].
## NOTE: "CELLS" are the individual grid elements, NOT the "TILES";
## Tiles are the permanent resources in a [TileSet]. A single Tile is used to paint multiple Cells of a [TileMapLayer].
## [TileSet]s can specify custom data per Tile, but a [TileMapLayer] cannot add custom data per grid Cell without this script.

class_name TileMapLayerWithCustomCellData
extends TileMapLayer


#region Parameters & State
## A Dictionary of Dictionaries. { CellCoordinates : {Key : Value} }
## Each (x,y) [Vector2i] coordinate key contains a Dictionary of {[StringName]: [Variant]}.
@export var dataDictionary := { Vector2i(0,0): {&"key": 0} }

@export var shouldShowDebugInfo: bool = false
#endregion


func setCellData(coordinates: Vector2i, key: StringName, value: Variant) -> void:
	if shouldShowDebugInfo: Debug.printDebug(str("setCellData() @", coordinates, " ", key, " = ", value), str(self))

	# NOTE: Do NOT assign an entire dictionary here or that will overrite all other keys!
	
	# Get the data dictionary for the cell, or add an empty dictionary.
	var cellData: Variant = dataDictionary.get_or_add(coordinates, {}) # Cannot type this as a `Dictionary` if the coordinate key is missing :(
	
	cellData[key] = value


func getCellData(coordinates: Vector2i, key: StringName) -> Variant:
	var cellData: Variant = dataDictionary.get(coordinates) # Cannot type this as a `Dictionary` if the coordinate key is missing :(
	var value: Variant
	
	if cellData is Dictionary:
		value = (cellData as Dictionary).get(key)
	else:
		value = null
	
	if shouldShowDebugInfo: Debug.printDebug(str("getCellData() @", coordinates, " ", key, ": ", value), str(self))
	return value
