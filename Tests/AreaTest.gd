extends Start


@onready var testArea: Area2D = %TestArea
@onready var testShapeNode: CollisionShape2D = %TestShapeNode
@onready var spriteArea: Area2D = %SpriteArea
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

	var shapeBounds: Rect2 = CollisionTools.getFirstShapeBounds(testArea)
	Debug.watchList.shapeBounds = shapeBounds

	var shapeBoundsInArea: Rect2 = CollisionTools.getAllShapeBounds(testArea)
	Debug.watchList.shapeBoundsInArea = shapeBoundsInArea

	var shapeGlobalBounds: Rect2 = CollisionTools.getShapeGlobalBounds(testArea)
	Debug.watchList.shapeGlobalBounds = shapeGlobalBounds

	Debug.watchList.displacementOutsideZone2 = RectTools.getRectOffsetOutsideContainer(areaContactComponent.areaBoundsGlobal, CollisionTools.getShapeGlobalBounds(%Zone2))
	Debug.watchList.spriteAreaGlobalBounds	 = CollisionTools.getShapeGlobalBounds(spriteArea)
	Debug.watchList.nearestAreaToSprite		 = Tools.findNearestArea(spriteArea, [testArea, %Zone1, %Zone2, %Zone3])


func _draw() -> void:
	var mapsAndColors: Dictionary[TileMapLayer, Color] = {
		$TileMapLayer1: Color(Color.GREEN_YELLOW, 0.5),
		$TileMapLayer2: Color(Color.CYAN, 0.5),
		$TileMapLayer3: Color(Color.YELLOW, 0.5),
		$TileMapLayer4: Color(Color.VIOLET, 0.5)}

	var spriteAreaRect:	 Rect2 = CollisionTools.getShapeGlobalBounds(spriteArea)
	var mapRect:		 Rect2
	var isTestAreaInMap: bool

	for map in mapsAndColors:
		mapRect = TileMapTools.getTileMapScreenBounds(map)
		isTestAreaInMap = TileMapTools.isRectInTileMap(spriteAreaRect, map, false) # not checkOriginAndEnd
		draw_rect(mapRect, mapsAndColors[map] if not isTestAreaInMap else Color.RED, true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: self.queue_redraw()
