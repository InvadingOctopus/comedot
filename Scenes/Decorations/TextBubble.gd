## A text [Label] that floats up and disappears.
## Call the static method [method TextBubble.create] to add a text bubble to a node.
## Useful for showing health values etc. over a sprite.

class_name TextBubble
extends Label

@onready var animationPlayer: AnimationPlayer = $AnimationPlayer


static func create(parentNode: Node2D, bubbleText: String) -> TextBubble:
	var scenePath := Global.getScenePathFromClass(TextBubble)
	var newBubble: TextBubble = (load(scenePath) as PackedScene).instantiate()
	newBubble.text = bubbleText
	parentNode.add_child(newBubble)
	newBubble.owner = parentNode
	return newBubble


func _ready() -> void:
	animationPlayer.play(&"bubble") # TBD: Remove hardcoding?
	await animationPlayer.animation_finished
	self.queue_free()
