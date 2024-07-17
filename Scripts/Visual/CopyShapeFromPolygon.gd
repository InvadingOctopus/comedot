## Copies the shape of another polygon to this polygon.

extends CollisionPolygon2D

@export var polygonToCopy: Polygon2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Try to find a sibling named "Polygon2D" (the default Godot name)
	if polygonToCopy == null:
		polygonToCopy = get_node("../Polygon2D")

	self.polygon   = polygonToCopy.polygon
	self.position  = polygonToCopy.position
	self.scale     = polygonToCopy.scale
	self.rotation  = polygonToCopy.rotation
	self.skew      = polygonToCopy.skew
	self.transform = polygonToCopy.transform


# TODO: Option to match shapes every frame?
#func _process(delta):
#	pass
