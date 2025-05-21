## Calls [method Tools.randomizeTileMapCells] to randomize the cells in the specified region of the TileMap, with tiles from the specified region in the TileSet.

#class_name RandomizeTileMapCells
extends TileMapLayer


#region Parameters
@export var cellRegionStart:	Vector2i ## The upper-left corner of the rectangle region in the [TileMapLayer] MAP to modify the CELLS in.
@export var cellRegionEnd:		Vector2i ## The bottom-right corner of the rectangle region in the [TileMapLayer] MAP to modify the CELLS in.
@export var tileCoordinatesMin:	Vector2i ## The upper-left corner of the rectangle region in the [TileSet] to choose the TILES from.
@export var tileCoordinatesMax:	Vector2i ## The bottom-right corner of the rectangle region in the [TileSet] to choose the TILES from.

@export_range(0, 1.0, 0.01) var modificationChance:	float = 1.0 ## THe chance to modify rolled separately for each cell in the [member cellRegionStart] to [member cellRegionEnd] rectangle.
@export var skipEmptyCells:		bool = true ## Leave "unpainted" cells empty?
#endregion


func _ready() -> void:
	Tools.randomizeTileMapCells(self, cellRegionStart, cellRegionEnd, tileCoordinatesMin, tileCoordinatesMax, modificationChance, skipEmptyCells)
