extends Node2D


@onready var area: Area2D = %Area
@onready var shapeNode: CollisionShape2D = %ShapeNode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Debug.watchList.areaPositition = area.position
	Debug.watchList.areaGlobalPositition = area.global_position

	Debug.watchList.shapeNodePositition = shapeNode.position
	Debug.watchList.shapeNodeGlobalPositition = shapeNode.global_position

	var shapeBounds: Rect2 = Global.getShapeBounds(area)
	Debug.watchList.shapeBounds = shapeBounds

	var shapeBoundsInArea: Rect2 = Global.getShapeBoundsInArea(area)
	Debug.watchList.shapeBoundsInArea = shapeBoundsInArea

	var shapeGlobalBounds: Rect2 = Global.getShapeGlobalBounds(area)
	Debug.watchList.shapeGlobalBounds = shapeGlobalBounds
