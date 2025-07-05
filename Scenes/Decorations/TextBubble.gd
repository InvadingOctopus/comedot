## A text [Label] that floats up and disappears.
## Call the static method [method TextBubble.create] to add a text bubble to a node.
## Useful for showing health values etc. over a sprite.
## TIP: For "bubbles" for [Stat]s and other [GameplayResourceBase]-derived Resources, use [GameplayResourceBubble].

class_name TextBubble
extends Node2D

# TODO: Support fitting within the screen; i.e. when emitted from a node at the left/right edges of the screen, the text is outside the screen.


#region State
static var scenePath: String:
	get:
		if not scenePath: scenePath = SceneManager.getScenePathFromClass(TextBubble)
		return scenePath

@onready var label: Label = $Label
var tween: Tween ## The default animation [Tween] that starts on [method _ready]. May be modified or cancelled by custom scripts.
#endregion


## Creates & returns a new [TextBubble].
## TIP: The [param offset] is applied to the default position of 0,0 so the offset may also be used as a absolute position.
static func create(bubbleText: String, parentNode: Node = null, offset: Vector2 = Vector2(0, -16)) -> TextBubble: # The default offset is above a 16-pixel sprite.
	var newBubble: TextBubble = (load(scenePath) as PackedScene).instantiate()
	newBubble.position += offset
	if parentNode: parentNode.add_child(newBubble)
	newBubble.get_node(^"Label").text = bubbleText # SOLVED: Use get_node() to avoid crash if there is no `parentNode` yet, therefore no @onready
	# newBubble.owner = parentNode # TBD: No need for persistence across Save/Load, right?
	return newBubble


## Creates & returns a new [TextBubble] displaying the name of a [Stat] and its change in value.
## TIP: Use [GameplayResourceBubble] for more features.
static func createForStatChange(stat: Stat, textToApped: String, parentNode: Node = null, offset: Vector2 = Vector2(0, -16), colorBubble: bool = true) -> TextBubble:
	var bubble: TextBubble = TextBubble.create(stat.displayName + textToApped, parentNode, offset)
	if colorBubble:
		if   stat.previousChange > 0: bubble.label.label_settings.font_color = Color.GREEN
		elif stat.previousChange < 0: bubble.label.label_settings.font_color = Color.ORANGE
	return bubble


func _ready() -> void:
	self.tween = Animations.bubble(self)
	await tween.finished
	self.queue_free()
