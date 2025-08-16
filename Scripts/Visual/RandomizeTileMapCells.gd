## Calls [method Tools.randomizeTileMapCells] to randomize the cells in the specified region of the TileMap, with tiles from the specified region in the TileSet.

#class_name RandomizeTileMapCells
extends TileMapLayer


#region Parameters

## Overrides [member cellRegionStart] & [member cellRegionEnd].
## WARNING: If there are NO "painted" cells in the map, then the size of the map will be (0,0) which means NO cells will be modified!
## TIP: To quickly set the "size" of a [TileMapLayer], just place 1 transparent tile on the bottom-right cell.
@export var shouldUseEntireMap: 	bool = false

@export var cellRegionStart:		Vector2i ## The upper-left corner of the rectangle region in the [TileMapLayer] MAP to modify the CELLS in.
@export var cellRegionEnd:			Vector2i ## The bottom-right corner of the rectangle region in the [TileMapLayer] MAP to modify the CELLS in.
@export var atlasCoordinatesMin:	Vector2i ## The upper-left corner of the rectangle region in the [TileSet] atlas to choose the TILES from.
@export var atlasCoordinatesMax:	Vector2i ## The bottom-right corner of the rectangle region in the [TileSet] atlas to choose the TILES from.

@export var shouldSkipEmptyCells:	bool = true ## Leave "unpainted" cells empty?
@export_range(0, 1.0, 0.01) var modificationChance:	float = 1.0 ## THe chance to modify rolled separately for each cell in the [member cellRegionStart] to [member cellRegionEnd] rectangle.
#endregion


func _ready() -> void:
	if shouldUseEntireMap:
		var mapArea: Rect2i = self.get_used_rect()
		if mapArea.has_area():
			Debug.printDebug(str("RandomizeTileMapCells.gd: shouldUseEntireMap: Map area: ", mapArea), self)
			cellRegionStart = mapArea.position
			cellRegionEnd   = mapArea.end
		else:
			Debug.printWarning(str("RandomizeTileMapCells.gd: shouldUseEntireMap: Map has cells = no area!"), self)

	Tools.randomizeTileMapCells(self, cellRegionStart, cellRegionEnd, atlasCoordinatesMin, atlasCoordinatesMax, modificationChance, shouldSkipEmptyCells)
