extends Start


func _ready() -> void:
	super._ready()
	Tools.randomizeTileMapCells($TileMapLayerWithCustomCellData, Vector2i(2, 2), Vector2i(20, 20), Vector2i(42, 14), Vector2i(47, 15), 0.2)
