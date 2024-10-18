## Sets a random frame on a [Sprite2D] or [AnimatedSprite2D] from the list of its animation frames.
## Allows non-animated sprites to have variation, similar to TileMap tiles.

extends Node2D # Sprite2D or AnimatedSprite2D

# TODO: A better way to typecast both Sprite2D & AnimatedSprite2D


#region Properties

var totalFrames: int:
	get:
		if    isSprite: return selfAsSprite.hframes * selfAsSprite.vframes
		elif  isAnimatedSprite: return selfAsAnimatedSprite.sprite_frames.get_frame_count(selfAsAnimatedSprite.animation) - 1 # Frame 1 is index 0
		else: return 0

# Can't use `is` for some reason

var isSprite: bool:
	get: return is_instance_of(self, Sprite2D)

var isAnimatedSprite: bool:
	get: return is_instance_of(self, AnimatedSprite2D)

var selfAsSprite: Sprite2D:
	get: return self.get_node(^".") as Sprite2D

var selfAsAnimatedSprite: AnimatedSprite2D:
	get: return self.get_node(^".") as AnimatedSprite2D

#endregion


func _ready() -> void:
	if not checkSelfType(): return
	setRandomFrame()


func checkSelfType() -> bool:
	if isSprite or isAnimatedSprite:
		return true
	else:
		Debug.printWarning("Not Sprite2D or AnimatedSprite2D", self)
		return false


func setRandomFrame() -> void:
	self.frame = randi_range(0, self.totalFrames)
