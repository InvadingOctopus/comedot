## A [Component] which manipulates a [CharacterBody2D] of the parent [Entity].
## This does NOT necessarily mean that this component HAS a body or must BE a body.

class_name BodyComponent
extends Component


## If `null` then it will be acquired from the parent [Entity] on [method _enter_tree()]
@export var body: CharacterBody2D:
	get:
		if body == null and not skipFirstWarning:
			printWarning("body is null! Call parentEntity.getBody() to find and remember the Entity's CharacterBody2D")
		return body


## This avoids the superfluous warning when checking the [member body] for the first time in [method _enter_tree()].
var skipFirstWarning := true


# Called whenever the node enters the scene tree.
func _enter_tree() -> void:
	super._enter_tree()
	if self.body == null and parentEntity != null:
			self.body = parentEntity.getBody()
	skipFirstWarning = false
