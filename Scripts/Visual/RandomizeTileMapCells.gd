## Calls [method TileMapTools.findRandomTileMapCells] & [method TileMapTools.randomizeTileMapCells] to randomize the cells in the specified region of a [TileMapLayer], with tiles from the specified range in the [TileSet] atlas.
## NOTE: If [member atlasSourceID] is set to -1, or [member atlasCoordinatesMin] & [member atlasCoordinatesMax] are BOTH set to (-1,-1), the cells will be ERASED.

#class_name RandomizeTileMapCells
extends TileMapLayer


#region Parameters

@export_range(0, 1.0, 0.01) var modificationChance:	float = 1.0 ## The chance to modify rolled separately for each cell in the [member cellRegionStart] to [member cellRegionEnd] rectangle.

@export var shouldIncludeUsedCells:  bool = true ## Modify already "painted" cells?
@export var shouldIncludeEmptyCells: bool = true ## If `false`, leave "unpainted" cells empty.

@export_group("TileMap Region")

## If `false` then [param cellRegionStart] & [param cellRegionEnd] are ignored, and the entire grid containing all the "painted" cells of the TileMap is used.
## WARNING: If there are NO "painted" cells in the map, then the size of the map will be (0,0) which means NO cells will be modified!
## TIP: To quickly set the "size" of a [TileMapLayer], just place 1 transparent tile on the bottom-right cell.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var shouldUseRegion:	bool
@export var cellRegionStart:		Vector2i ## The upper-left corner of the rectangle region in the [TileMapLayer] MAP to modify the CELLS in.
@export var cellRegionEnd:			Vector2i ## The bottom-right corner of the rectangle region in the [TileMapLayer] MAP to modify the CELLS in.

@export_group("TileSet Atlas")

@export var atlasCoordinatesMin:	Vector2i ## The upper-left corner of the rectangle region in the [TileSet] atlas to choose the TILES from. If both min & max coordinates are (-1,-1) then all cells will be ERASED.
@export var atlasCoordinatesMax:	Vector2i ## The bottom-right corner of the rectangle region in the [TileSet] atlas to choose the TILES from. If both min & max coordinates are (-1,-1) then all cells will be ERASED.
@export var atlasSourceID:			int = 0  ## A [TileSetSource] identifier. See [method TileSet.set_source_id]. If -1 then all cells will be ERASED.

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

	if shouldUseRegion and cellRegionEnd < cellRegionStart:
		Debug.printWarning("cellRegionEnd < cellRegionStart", self)
		return []

	# If certain arguments are -1, erase all cells in the list 
	var shouldEraseCells: bool = atlasSourceID == -1 \
		or (atlasCoordinatesMin == Vector2i(-1, -1)  \
		and atlasCoordinatesMax == Vector2i(-1, -1))

	if not shouldEraseCells \
	and (atlasCoordinatesMax.x < atlasCoordinatesMin.x \
	or   atlasCoordinatesMax.y < atlasCoordinatesMin.y): # FIXED: Compare x,y separately otherwise min:(0,10) < max:(1,2) will pass validation then potentially call randi_range(10, 2) for y, if just comparing the whole vectors
		Debug.printWarning("atlasCoordinatesMax < atlasCoordinatesMin", self)
		return []

	recentlyModifiedCells = TileMapTools.findRandomTileMapCells(self,
		modificationChance, shouldIncludeUsedCells, shouldIncludeEmptyCells,
		shouldUseRegion, cellRegionStart, cellRegionEnd)

	TileMapTools.randomizeTileMapCells(self, recentlyModifiedCells, atlasCoordinatesMin, atlasCoordinatesMax, atlasSourceID)

	return recentlyModifiedCells
