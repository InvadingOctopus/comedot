## Draws vector shapes and shit.
## @experimental

class_name ShapeDrawComponent
extends Component

# TODO: More shapes


#region Parameters
# @export var lines: Array[Tools.Line] # UNUSED: Godot doesn't support custom class @export yet :(
@export var linePoints: PackedVector2Array ## Pairs of start and end points for disconnected lines.
@export var lineColors: PackedColorArray ## A [Color] for each line in [member linePoints]
@export var lineWidth:	float = -1.0 ## A negative means the line will remain a "2-point primitive" i.e. always be a 1-width line regardless of scaling.

@export var isEnabled: bool = true
#endregion


#region State
@onready var selfAsCanvasItem: CanvasItem = self.get_node(^".") as CanvasItem
#endregion


func _draw() -> void:
	if not isEnabled: return
	selfAsCanvasItem.draw_multiline_colors(linePoints, lineColors, lineWidth, false) # not antialiased because we're pixel-art by default!
	
	# UNUSED: Godot doesn't support custom class @export yet :(
	# for line: Tools.Line in lines:
	# 	selfAsCanvasItem.draw_line(line.start, line.end, line.color, line.width, false) 
