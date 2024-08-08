## Flips this node to match the flip of a [Sprite2D] or [AnimatedSprite2D] node.
## Useful for placing child nodes at front of or behind a sprite, for example.

#class_name FlipToMatchSprite
extends Node2D

# TODO: PERFORMANCE: Update only when the flip property changes; not every frame!
# TODO: Vertical flipping
# TODO: How to best support both [Sprite2D] & [AnimatedSprite2D]? They're not related by inheritance...


#region parameters

## The sprite to match the orientation of.
## If `null`, the parent of this node is used.
## NOTE: We cannot type for both [Sprite2D] & [AnimatedSprite2D] as they are not related by inheritance. We just have to assume that the [Node2D] will have a [flip_h] or [flip_v] property :')
@export var spriteToMatch: Node2D:
	get:
		# Try to match [AnimatedSprite2D] first as that would be most common :')
		if not spriteToMatch: spriteToMatch = self.get_parent() as AnimatedSprite2D
		if not spriteToMatch: spriteToMatch = self.get_parent() as Sprite2D
		return spriteToMatch

@export var isEnabled: bool = true

#endregion


func _process(_delta: float) -> void:
	# TODO: flip_v
	# TODO: A more accurate and reliable implementation
	if not isEnabled or not spriteToMatch: return

	if spriteToMatch.flip_h:
		self.rotation = PI
	else:
		self.rotation = 0
