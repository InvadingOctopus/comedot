## A [Component] which manipulates a [Area2D] of the parent [Entity].
## This does NOT necessarily mean that this component HAS an area or must BE an area.

class_name AreaComponent
extends Component


## If `null` then it will be acquired from the parent [Entity] on [method _enter_tree()]
@export var area: Area2D = null:
	get:
		if area == null:
			printWarning("area is null! Call parentEntity.getArea() to find and remember the Entity's Area2D")
		return area


## This avoids the superfluous warning when checking the [member body] for the first time in [method _enter_tree()].
var skipFirstWarning := true


# Called whenever the node enters the scene tree.
func _enter_tree() -> void:
	super._enter_tree()
	if parentEntity != null and self.area == null:
			self.area = parentEntity.getArea()
	skipFirstWarning = false

