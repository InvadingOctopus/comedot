## A text [Label] that floats up and disappears.
## Call the static method [method TextBubble.create] to add a text bubble to a node.
## Useful for showing health values etc. over a sprite.
## TIP: For "bubbles" for [Stat]s and other [GameplayResourceBase]-derived Resources, use [GameplayResourceBubble]

class_name TextBubble
extends BubbleBase

# TODO: Support fitting within the screen; i.e. when emitted from a node at the left/right edges of the screen, the text is outside the screen.


#region State
static var scenePath: String:
	get:
		if not scenePath: scenePath = SceneManager.getScenePathFromClass(TextBubble)
		return scenePath

## IMPORTANT: Use [method get_node] instead of this property to avoid a crash when accessing the [Label] before [method _ready]
@onready var label: Label = $Label
#endregion


## Creates & returns a new [TextBubble].
## TIP: The [param offset] is applied to the default position of 0,0 so the offset may also be used as a absolute position.
static func create(bubbleText: String, parentNode: Node = null, offset: Vector2 = Vector2(0, -16)) -> TextBubble: # The default offset is above a 16-pixel sprite.
	var newBubble: TextBubble = (load(scenePath) as PackedScene).instantiate()
	newBubble.position += offset
	if parentNode: parentNode.add_child(newBubble)
	newBubble.get_node(^"Label").text = bubbleText
	# newBubble.owner = parentNode # TBD: No need for persistence across Save/Load, right?
	return newBubble


## Creates & returns a new [TextBubble] displaying the name of a [Stat] and its change in value.
## TIP: Use [GameplayResourceBubble] for more features.
static func createForStatChange(stat: Stat, textToApped: String, parentNode: Node = null, offset: Vector2 = Vector2(0, -16), colorBubble: bool = true) -> TextBubble:
	var bubble: TextBubble = TextBubble.create(stat.displayName + textToApped, parentNode, offset)
	if colorBubble:
		if   stat.previousChange > 0: bubble.get_node(^"Label").label_settings.font_color = Color.GREEN
		elif stat.previousChange < 0: bubble.get_node(^"Label").label_settings.font_color = Color.ORANGE
	return bubble
