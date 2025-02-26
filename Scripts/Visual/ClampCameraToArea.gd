## Confines a [Camera2D] within a rectangular [Area2D].
## TIP: For a camera attached to an [Entity], use [CameraComponent]

extends Camera2D


## Choose an [Area2D] to clamp the camera's position within the rectangular bounds of the area.
@export var boundary: Area2D:
	set(newValue):
		if boundary != newValue:
			boundary = newValue
			clampToBoundary()


func _ready() -> void:
	if boundary: clampToBoundary()


func clampToBoundary() -> void:
	if not boundary: return

	var rect: Rect2 = Tools.getShapeGlobalBounds(boundary)

	if not rect:
		Debug.printWarning("Cannot get a Rect2 from Area2D: " + str(boundary), self)

	self.limit_left   = int(rect.position.x)
	self.limit_right  = int(rect.end.x)
	self.limit_top	  = int(rect.position.y)
	self.limit_bottom = int(rect.end.y)


#func _process(delta):
	#showDebugInfo()


func showDebugInfo() -> void:
	Debug.watchList.boundary		= self.boundary.position
	Debug.watchList.limit_left  	= limit_left
	Debug.watchList.limit_right 	= limit_right
	Debug.watchList.limit_top		= limit_top
	Debug.watchList.limit_bottom	= limit_bottom
