## A list of text strings and associated colors, for basic NPC dialogues or "signboards" etc.
## @experimental

class_name ColoredTextSequence
extends TextSequence


#region Parameters
## The color to apply to each string. If this array is a different size than the text array, the colors will wrap around.
@export var colors: PackedColorArray
#endregion


#region State
var currentColorIndex:	int
#endregion


func incrementIndex(step: int = 1) -> void:
	# TBD: Cycle the colors or stop at the last color if there are fewer colors than strings?
	super.incrementIndex()

	currentColorIndex += absi(step)
	if  currentColorIndex >= colors.size():
		currentColorIndex = 0


func formatLabel(label: Control) -> void:
	if  label is Label:
		label.label_settings.font_color = colors[currentColorIndex] if not colors.is_empty() else Color.WHITE
	# TODO: RichTextLabel
