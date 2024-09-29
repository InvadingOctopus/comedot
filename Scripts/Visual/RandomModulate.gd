## Sets a random [member CanvasItem.modulate] [Color] for a node.

class_name RandomModulate
extends CanvasItem


#region Parameters
@export_range(0, 1.0) var redMin:	float = 0
@export_range(0, 1.0) var redMax:	float = 1.0

@export_range(0, 1.0) var greenMin:	float = 0
@export_range(0, 1.0) var greenMax:	float = 1.0

@export_range(0, 1.0) var blueMin:	float = 0
@export_range(0, 1.0) var blueMax:	float = 1.0

@export var shouldRandomizeEveryFrame: bool = false
#endregion


func _ready() -> void:
	randomizeModulate()


func _process(_delta: float) -> void:
	if shouldRandomizeEveryFrame:
		randomizeModulate()


func randomizeModulate() -> void:
	self.modulate = Color(
		randf_range(redMin,   redMax),
		randf_range(greenMin, greenMax),
		randf_range(blueMin,  blueMax),
		1.0)
