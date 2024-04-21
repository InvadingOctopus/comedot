extends Camera2D


## Choose an [Area2D] to clamp the camera's position within the rectangular bounds of the area.
@export var boundary: Area2D:
	set(newValue):
		if boundary != newValue:
			boundary = newValue
			clampToBoundary()


func _ready():
	if boundary: clampToBoundary()


func clampToBoundary():
	if not boundary: return

	var rect: Rect2 = Global.getShapeGlobalBounds(boundary)

	if not rect:
		Debug.printWarning("Cannot get a Rect2 from Area2D: " + str(boundary), str(self))

	self.limit_left   = rect.position.x
	self.limit_right  = rect.end.x
	self.limit_top	  = rect.position.y
	self.limit_bottom = rect.end.y


#func _process(delta):
	#printDebug()


func printDebug():
	Debug.watchList.boundary		= self.boundary.position
	Debug.watchList.limit_left  	= limit_left
	Debug.watchList.limit_right 	= limit_right
	Debug.watchList.limit_top		= limit_top
	Debug.watchList.limit_bottom	= limit_bottom
