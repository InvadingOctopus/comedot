## A text [Label] that floats up and disappears.
## Call the static method [method TextBubble.create] to add a text bubble to a node.
## Useful for showing health values etc. over a sprite.

class_name TextBubble
extends Node2D


#region State
static var scenePath: String:
	get:
		if not scenePath: scenePath = SceneManager.getScenePathFromClass(TextBubble)
		return scenePath

@onready var label: Label = $Label
#endregion


static func create(parentNode: Node2D, bubbleText: String) -> TextBubble:
	var newBubble: TextBubble = (load(scenePath) as PackedScene).instantiate()
	parentNode.add_child(newBubble)
	newBubble.label.text = bubbleText
	# newBubble.owner = parentNode # TBD: No need for persistence across Save/Load, right?
	return newBubble


func _ready() -> void:
	await Animations.bubble(self).finished
	self.queue_free()
