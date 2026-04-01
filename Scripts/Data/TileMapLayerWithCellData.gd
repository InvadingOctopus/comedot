## A [TileMapLayer] with a [TileMapCellData] Resource to store custom data during runtime for individual cells,
## such as whether a cell is occupied by an Entity or its "health" if it's destructible etc.

class_name TileMapLayerWithCellData
extends TileMapLayer


#region Parameters & State

@export var cellData: TileMapCellData ## If `null` then a new structure is created on [method _ready]

@export var shouldCreateCellData: bool = true

@export var debugMode: bool = false:
	set(newValue):
		if newValue != debugMode:
			debugMode = newValue
			if cellData: cellData.debugMode = self.debugMode

#endregion


func _ready() -> void:
	if  not cellData and shouldCreateCellData:
		if debugMode: Debug.printDebug("No TileMapCellData, creating new.", self)
		self.cellData = TileMapCellData.new()
	
	if  cellData: # A separate `if` in case a `cellData` was created by the previous `if`
		cellData.debugMode = self.debugMode


#region Data Interface

func setCellData(coordinates: Vector2i, key: StringName, value: Variant) -> void:
	if cellData: cellData.setCellData(coordinates, key, value)
	else: Debug.printWarning("setCellData(): No TileMapCellData!", self)


## Returns the value for the [param key] stored in the cell at [param coordinates]
## ALERT: Make sure the cell data exists by callig [method hasCell] first! Otherwise a missing cell will also return `null`, which is indistinguishable from a cell that exists but has `null` as its data! 
func getCellData(coordinates: Vector2i, key: StringName) -> Variant:
	if cellData: 
		return cellData.getCellData(coordinates, key)
	else: 
		Debug.printWarning("getCellData(): No TileMapCellData!", self)
		return null


## Wrapper for [method TileMapCellData.hasCellData]
func hasCellData(coordinates: Vector2i, key: StringName = "") -> bool:
	return cellData.hasCellData(coordinates, key) if cellData else false


## Wrapper for [method TileMapCellData.eraseCellData]
func eraseCellData(coordinates: Vector2i, key: StringName) -> bool:
	return cellData.eraseCellData(coordinates, key) if cellData else false

#endregion
