## Creates flipped/mirrored copies of a node horizontally (X) and/or vertically (Y).
## The flags may be used in conjunction with each other to create 2 copies.
## NOTE: The flags do NOT create copies of the flipped copy created by other flags!
## NOTE: The copies are created WITHOUT duplicating this script, to avoid infinite copies.

class_name CreateFlippedCopy
extends Node2D


#region Parameters
@export var flipHorizontally: bool = false:
	set(newValue):
		if newValue != flipHorizontally:
			flipHorizontally = newValue
			if flipHorizontally and self.get_parent(): createHorizontalCopy() # Make sure we have a parent, in case the setter is called before _ready()

@export var flipVertically:   bool = false:
	set(newValue):
		if newValue != flipVertically:
			flipVertically = newValue
			if flipVertically and self.get_parent(): createVerticalCopy() # Make sure we have a parent, in case the setter is called before _ready()
#endregion


#region State
var horizontallyFlippedCopy: Node2D
var verticallyFlippedCopy:   Node2D
#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# NOTE: Use call_deferred() to avoid error: "Parent node is busy setting up children"
	if flipHorizontally: createHorizontalCopy.call_deferred()
	if flipVertically:   createVerticalCopy.call_deferred()


## Creates and assigns a [member horizontallyFlippedCopy].
func createHorizontalCopy() -> Node2D:
	if is_instance_valid(horizontallyFlippedCopy): return horizontallyFlippedCopy
	# NOTE: Avoid infinite recursion by not duplicating this script!
	self.horizontallyFlippedCopy = Tools.createScaledCopy(self, Vector2(-self.scale.x, self.scale.y), DuplicateFlags.DUPLICATE_GROUPS + DuplicateFlags.DUPLICATE_SIGNALS + DuplicateFlags.DUPLICATE_USE_INSTANTIATION)
	Tools.addChildAndSetOwner(horizontallyFlippedCopy, self.get_parent())
	return horizontallyFlippedCopy


## Creates and assigns a [member verticallyFlippedCopy].
func createVerticalCopy() -> Node2D:
	if is_instance_valid(verticallyFlippedCopy): return verticallyFlippedCopy
	# NOTE: Avoid infinite recursion by not duplicating this script!
	self.verticallyFlippedCopy = Tools.createScaledCopy(self, Vector2(self.scale.x, -self.scale.y), DuplicateFlags.DUPLICATE_GROUPS + DuplicateFlags.DUPLICATE_SIGNALS + DuplicateFlags.DUPLICATE_USE_INSTANTIATION)
	Tools.addChildAndSetOwner(verticallyFlippedCopy, self.get_parent())
	return verticallyFlippedCopy
