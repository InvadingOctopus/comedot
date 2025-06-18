extends Start


@onready var testArea: Area2D = %TestArea
@onready var testShapeNode: CollisionShape2D = %TestShapeNode
@onready var areaContactComponent: AreaContactComponent = %AreaContactComponent

func _ready() -> void:
	super._ready()
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	Debug.watchList.areaPosition = testArea.position
	Debug.watchList.areaGlobalPosition = testArea.global_position

	Debug.watchList.shapeNodePosition = testShapeNode.position
	Debug.watchList.shapeNodeGlobalPosition = testShapeNode.global_position

	var shapeBounds: Rect2 = Tools.getShapeBounds(testArea)
	Debug.watchList.shapeBounds = shapeBounds

	var shapeBoundsInArea: Rect2 = Tools.getShapeBoundsInArea(testArea)
	Debug.watchList.shapeBoundsInArea = shapeBoundsInArea

	var shapeGlobalBounds: Rect2 = Tools.getShapeGlobalBounds(testArea)
	Debug.watchList.shapeGlobalBounds = shapeGlobalBounds

	Debug.watchList.displacementOutsideZone2 = Tools.getRectOffsetOutsideContainer(areaContactComponent.areaBoundsGlobal, Tools.getShapeGlobalBounds(%Zone2))


func _draw() -> void:
	draw_rect(Tools.getTileMapScreenBounds($TileMapLayer1), Color(Color.GREEN_YELLOW, 0.5), true)
	draw_rect(Tools.getTileMapScreenBounds($TileMapLayer2), Color(Color.CYAN, 0.5), true)
	draw_rect(Tools.getTileMapScreenBounds($TileMapLayer3), Color(Color.YELLOW, 0.5), true)
	draw_rect(Tools.getTileMapScreenBounds($TileMapLayer4), Color(Color.VIOLET, 0.5), true)
