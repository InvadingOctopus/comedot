## Flips this node's [member Node2D.scale] to match the flip of a [Sprite2D] or [AnimatedSprite2D] node.
## Useful for placing child nodes at front of or behind a sprite in a platformer game, for example.

#class_name FlipToMatchSprite
extends Node2D

# TODO: PERFORMANCE: Update only when the flip property changes; not every frame!
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

## The base scale which to multiply by the [member xScalar] and [member yScalar] to flip the axes.
## If 0, it is initialized to this node's [member Node2D.scale].
@export var baseScale: Vector2 = Vector2(1, 1)

@export var isEnabled: bool = true

#endregion


#region State
var xScalar: int = 1 ## If the [member Sprite2D.flip_h] is `true`, this is set to -1, and this node's [member Node2D.scale.x] is set to [member baseScale.x] * -1, achieving a horizontal flip.
var yScalar: int = 1 ## If the [member Sprite2D.flip_v] is `true`, this is set to -1, and this node's [member Node2D.scale.y] is set to [member baseScale.y] * -1, achieving a vertical flip.
#endregion


func _ready() -> void:
	if is_zero_approx(self.baseScale.x): self.baseScale.x = self.scale.x
	if is_zero_approx(self.baseScale.y): self.baseScale.y = self.scale.y


func _process(_delta: float) -> void:
	# TBD: A more accurate and reliable implementation
	if not isEnabled or not spriteToMatch: return

	xScalar = -1 if spriteToMatch.flip_h else 1
	yScalar = -1 if spriteToMatch.flip_v else 1
	
	self.scale = Vector2(
		self.baseScale.x * xScalar,
		self.baseScale.y * yScalar)
