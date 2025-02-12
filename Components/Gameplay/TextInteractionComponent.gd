## Displays and cycles through a list of text strings.
## May be used for signboards and static NPC dialogues.

class_name TextInteractionComponent
extends InteractionComponent


#region Parameters
## The list of text strings to display in turn. If the player interacts again after the last string, the index will wrap around and the first string will be shown.
@export var textStrings: PackedStringArray = ["String1", "String2", "String3"]

## The color to apply to each string. This array may be a different size than the text array; the list will just wrap around.
@export var textColors:  Array[Color]  = [Color.WHITE, Color.YELLOW]
#endregion


#region State
var currentTextIndex:  int
var currentColorIndex: int
#endregion


#region Signals
signal didDisplayFinalText
#endregion


func _ready() -> void:
	super._ready()
	applyTextFromArray()
	updateLabel()


## Returns the updated label text.
@warning_ignore("unused_parameter")
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> String:
	displayNextText()
	return self.label


## This function may be called by a [Timer] or other scripts to automate the text display.
func displayNextText() -> void:
	incrementIndices()
	applyTextFromArray()
	updateLabel()


@warning_ignore("unused_parameter")
func applyTextFromArray(indexOverride: int = self.currentTextIndex) -> void:
	self.label = self.textStrings[currentTextIndex]
	
	var labelControl: Label = self.interactionIndicator as Label
	if labelControl:
		labelControl.label_settings.font_color = textColors[currentColorIndex]
	
	if currentTextIndex == textStrings.size() - 1: # The last index
		didDisplayFinalText.emit()


func incrementIndices() -> void:
	# TBD: Should this be a `Tools.incrementAndWrapArrayIndex()` or would that be slower? :)
	currentTextIndex += 1
	if currentTextIndex >= textStrings.size():
		currentTextIndex = 0
		
	currentColorIndex += 1
	if currentColorIndex >= textColors.size():
		currentColorIndex = 0
	
