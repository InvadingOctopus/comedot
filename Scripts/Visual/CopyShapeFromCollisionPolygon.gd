## Sets the shape of this polygon to a CollisionPolygon2D.

extends Polygon2D

@export var collisionPolygon: CollisionPolygon2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Try to find a sibling named "CollisionPolygon2D" (the default Godot name)
	if collisionPolygon == null:
		collisionPolygon = get_node("../CollisionPolygon2D")

	self.polygon   = collisionPolygon.polygon
	self.position  = collisionPolygon.position
	self.scale     = collisionPolygon.scale
	self.rotation  = collisionPolygon.rotation
	self.skew      = collisionPolygon.skew
	self.transform = collisionPolygon.transform


# TODO: Option to match shapes every frame?
#func _process(delta):
#	pass
