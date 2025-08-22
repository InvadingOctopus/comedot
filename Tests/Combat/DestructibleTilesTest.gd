extends Start


func _ready() -> void:
	super._ready()
	Tools.randomizeTileMapCells($TileMapLayerWithCellData,
		Tools.findRandomTileMapCells($TileMapLayerWithCellData,
			0.1, true, true,
			Vector2i(2, 2), Vector2i(20, 20)),
	Vector2i(42, 14),
	Vector2i(47, 15))
