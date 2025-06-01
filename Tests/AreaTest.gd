extends Start


@onready var area: Area2D = %TestArea
@onready var shapeNode: CollisionShape2D = %TestShapeNode


func _ready() -> void:
	super._ready()
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	Debug.watchList.areaPosition = area.position
	Debug.watchList.areaGlobalPosition = area.global_position

	Debug.watchList.shapeNodePosition = shapeNode.position
	Debug.watchList.shapeNodeGlobalPosition = shapeNode.global_position

	var shapeBounds: Rect2 = Tools.getShapeBounds(area)
	Debug.watchList.shapeBounds = shapeBounds

	var shapeBoundsInArea: Rect2 = Tools.getShapeBoundsInArea(area)
	Debug.watchList.shapeBoundsInArea = shapeBoundsInArea

	var shapeGlobalBounds: Rect2 = Tools.getShapeGlobalBounds(area)
	Debug.watchList.shapeGlobalBounds = shapeGlobalBounds
