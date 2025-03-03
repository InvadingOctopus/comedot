extends Start


@onready var area: Area2D = %Area
@onready var shapeNode: CollisionShape2D = %ShapeNode



func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	Debug.watchList.areaPositition = area.position
	Debug.watchList.areaGlobalPositition = area.global_position

	Debug.watchList.shapeNodePositition = shapeNode.position
	Debug.watchList.shapeNodeGlobalPositition = shapeNode.global_position

	var shapeBounds: Rect2 = Tools.getShapeBounds(area)
	Debug.watchList.shapeBounds = shapeBounds

	var shapeBoundsInArea: Rect2 = Tools.getShapeBoundsInArea(area)
	Debug.watchList.shapeBoundsInArea = shapeBoundsInArea

	var shapeGlobalBounds: Rect2 = Tools.getShapeGlobalBounds(area)
	Debug.watchList.shapeGlobalBounds = shapeGlobalBounds
