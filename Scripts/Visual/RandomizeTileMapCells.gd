## Calls [method Tools.findRandomTileMapCells] & [method Tools.randomizeTileMapCells] to randomize the cells in the specified region of a [TileMapLayer], with tiles from the specified range in the [TileSet] atlas.

#class_name RandomizeTileMapCells
extends TileMapLayer


#region Parameters

## Overrides [member cellRegionStart] & [member cellRegionEnd].
## WARNING: If there are NO "painted" cells in the map, then the size of the map will be (0,0) which means NO cells will be modified!
## TIP: To quickly set the "size" of a [TileMapLayer], just place 1 transparent tile on the bottom-right cell.
@export var shouldUseEntireMap:		 bool = false

@export var shouldIncludeUsedCells:  bool = true ## Modify already "painted" cells?
@export var shouldIncludeEmptyCells: bool = true ## Leave "unpainted" cells empty?

@export var cellRegionStart:		Vector2i ## The upper-left corner of the rectangle region in the [TileMapLayer] MAP to modify the CELLS in.
@export var cellRegionEnd:			Vector2i ## The bottom-right corner of the rectangle region in the [TileMapLayer] MAP to modify the CELLS in.

@export var atlasCoordinatesMin:	Vector2i ## The upper-left corner of the rectangle region in the [TileSet] atlas to choose the TILES from.
@export var atlasCoordinatesMax:	Vector2i ## The bottom-right corner of the rectangle region in the [TileSet] atlas to choose the TILES from.

@export_range(0, 1.0, 0.01) var modificationChance:	float = 1.0 ## THe chance to modify rolled separately for each cell in the [member cellRegionStart] to [member cellRegionEnd] rectangle.

#endregion


#region State
var recentlyModifiedCells: Array[Vector2i] # TBD: PERFORMANCE: Is this useful?
#endregion


func _ready() -> void:
	repaintCells()


func repaintCells() -> Array[Vector2i]:
	if (not shouldIncludeUsedCells and not shouldIncludeEmptyCells):
		Debug.printWarning("shouldIncludeUsedCells & shouldIncludeEmptyCells are both off!", self)
		return []
	
	if is_zero_approx(modificationChance) or modificationChance < 0:
		Debug.printWarning("modificationChance <= 0", self)
		return []

	if cellRegionEnd < cellRegionStart:
		Debug.printWarning("cellRegionEnd < cellRegionStart", self)
		return []

	if atlasCoordinatesMax < atlasCoordinatesMin:
		Debug.printWarning("atlasCoordinatesMax < atlasCoordinatesMin", self)
		return []

	if shouldUseEntireMap:
		var mapArea: Rect2i = self.get_used_rect()
		if mapArea.has_area():
			Debug.printDebug(str("RandomizeTileMapCells.gd: shouldUseEntireMap: Map area: ", mapArea), self)
			cellRegionStart = mapArea.position
			cellRegionEnd   = mapArea.end
		else:
			Debug.printWarning(str("RandomizeTileMapCells.gd: shouldUseEntireMap: Map has cells = no area!"), self)

	recentlyModifiedCells = Tools.findRandomTileMapCells(self, cellRegionStart, cellRegionEnd, modificationChance, shouldIncludeUsedCells, shouldIncludeEmptyCells)
	Tools.randomizeTileMapCells(self, recentlyModifiedCells, atlasCoordinatesMin, atlasCoordinatesMax)
	return recentlyModifiedCells
