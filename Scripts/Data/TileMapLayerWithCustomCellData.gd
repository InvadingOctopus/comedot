## A [TileMapLayer] with a [TileMapCellData] Resource to store custom data during runtime for individual cells,
## such as whether a cell is occupied by an Entity or its "health" if it's destructible etc.

class_name TileMapLayerWithCustomCellData
extends TileMapLayer


#region Parameters & State

@export var cellData: TileMapCellData ## If `null` then a new structure is created on [method _ready]

@export var debugMode: bool = false:
	set(newValue):
		if newValue != debugMode:
			debugMode = newValue
			if cellData: cellData.debugMode = self.debugMode

#endregion


func _ready() -> void:
	if not cellData:
		if debugMode: Debug.printDebug("No TileMapCellData, creating new.", self)
		self.cellData = TileMapCellData.new()
		cellData.debugMode = self.debugMode


#region Data Interface

func setCellData(coordinates: Vector2i, key: StringName, value: Variant) -> void:
	if cellData: cellData.setCellData(coordinates, key, value)
	else: Debug.printWarning("setCellData(): No TileMapCellData!", self)


func getCellData(coordinates: Vector2i, key: StringName) -> Variant:
	if cellData: 
		return cellData.getCellData(coordinates, key)
	else: 
		Debug.printWarning("getCellData(): No TileMapCellData!", self)
		return null

#endregion
