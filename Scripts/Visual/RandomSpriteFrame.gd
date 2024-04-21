## Sets a random frame from the list of animation frames.
## Allows non-animated sprites to have variation, similar to tilemap tiles.

extends Sprite2D


var totalFrames: int:
	get: return self.hframes * self.vframes


func _ready():
	setRandomFrame()


func setRandomFrame():
	self.frame = randi_range(0, self.totalFrames)
