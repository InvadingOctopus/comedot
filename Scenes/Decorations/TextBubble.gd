## A text [Label] that floats up and disappears.
## Call the static method [method TextBubble.create] to add a text bubble to a node.
## Useful for showing health values etc. over a sprite.

class_name TextBubble
extends Node2D

# TODO: Support fitting within the screen; i.e. when emitted from a node at the left/right edges of the screen, the text is outside the screen.


#region State
static var scenePath: String:
	get:
		if not scenePath: scenePath = SceneManager.getScenePathFromClass(TextBubble)
		return scenePath

@onready var label: Label = $Label
#endregion


static func create(bubbleText: String, parentNode: Node = null, offset: Vector2 = Vector2(0, -16)) -> TextBubble:
	var newBubble: TextBubble = (load(scenePath) as PackedScene).instantiate()
	newBubble.position += offset # The default offset is above a 16-pixel sprite.
	if parentNode: parentNode.add_child(newBubble)
	newBubble.label.text = bubbleText
	# newBubble.owner = parentNode # TBD: No need for persistence across Save/Load, right?
	return newBubble


func _ready() -> void:
	await Animations.bubble(self).finished
	self.queue_free()
