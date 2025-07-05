## A visual "bubble" for [GameplayResourceBase]-derived resources such as [Stat], which shows the Resource's icon, "friendly" name and any extra text such as the change in a [Stat]'s value.
## Call the static method [method GameplayResourceBubble.create] to add a bubble to a node.
## Useful for showing resource loss or loot pickup values etc. over a sprite.
## TIP: For basic text "bubbles", use [TextBubble].

class_name GameplayResourceBubble
extends Node2D

# TODO: Support fitting within the screen; i.e. when emitted from a node at the left/right edges of the screen, the text is outside the screen.


#region State
static var scenePath: String:
	get:
		if not scenePath: scenePath = SceneManager.getScenePathFromClass(GameplayResourceBubble)
		return scenePath

@onready var ui: GameplayResourceUI = $GameplayResourceUI
var tween: Tween ## The default animation [Tween] that starts on [method _ready]. May be modified or cancelled by custom scripts.
#endregion


## Creates & returns a new [GameplayResourceUI].
## TIP: The [param offset] is applied to the default position of 0,0 so the offset may also be used as a absolute position.
static func create(resource: GameplayResourceBase, text: String, parentNode: Node = null, offset: Vector2 = Vector2(0, -16), appendDisplayName: bool = true) -> GameplayResourceBubble: # The default offset is above a 16-pixel sprite.
	# TODO: Replace string-dependence!
	var newBubble:	GameplayResourceBubble	= (load(scenePath) as PackedScene).instantiate()
	var bubbleUI:	GameplayResourceUI		= newBubble.get_node(^"GameplayResourceUI")

	bubbleUI.get_node(^"Icon").texture	=  resource.icon
	bubbleUI.get_node(^"Label").text	= (resource.displayName if appendDisplayName else "") + text # SOLVED: Use get_node() to avoid crash if there is no `parentNode` yet, therefore no @onready
	newBubble.position += offset

	if parentNode: parentNode.add_child(newBubble)
	# newBubble.owner = parentNode # TBD: No need for persistence across Save/Load, right?

	return newBubble


## Creates & returns a new [GameplayResourceBubble] displaying the name of a [Stat] and its change in value.
## TIP: For bubbles that don't need to display the change in value, use [method GameplayResourceBubble.create].
static func createForStatChange(stat: Stat, parentNode: Node = null, offset: Vector2 = Vector2(0, -16), appendDisplayName: bool = true, colorBubble: bool = true) -> GameplayResourceBubble:
	var bubble: GameplayResourceBubble = GameplayResourceBubble.create(stat, "%+d" % stat.previousChange, parentNode, offset, appendDisplayName)
	if colorBubble: # Tint the icon along with the label
		if   stat.previousChange > 0: bubble.modulate = Color.GREEN
		elif stat.previousChange < 0: bubble.modulate = Color.ORANGE
	return bubble


func _ready() -> void:
	self.tween = Animations.bubble(self)
	await tween.finished
	self.queue_free()
