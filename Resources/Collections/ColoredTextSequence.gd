## A list of text strings and associated colors, for basic NPC dialogues or "signboards" etc.
## WARNING: Modifying the font/color/etc. of a [LabelSettings] will affect ALL [Label]s that use the same [LabelSettings] unless that [Resource] is set "Local to Scene"
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


## Advances [member currentStringIndex] and [member currentColorIndex] and wraps around to 0 + remainder if either exceeds its associated array's size.
## NOTE: [param step] will always be converted to a positive integer.
## NOTE: If [member colors] is of a different size than [member strings], the colors may drift, which may be an intentional effect or not.
func incrementIndex(step: int = 1) -> void:
	super.incrementIndex(step)
	currentColorIndex = Tools.wrapArrayIndex(colors, currentColorIndex, absi(step)) # Wrap to 0 + remainder


## Resets the indices
func reset() -> void:
	super.reset()
	currentColorIndex = 0


## WARNING: Modifying the font/color/etc. of a [LabelSettings] will affect ALL [Label]s that use the same [LabelSettings] unless that [Resource] is set "Local to Scene"
func formatLabel(label: Control) -> void:
	if  label is Label:
		label.label_settings.font_color = colors[currentColorIndex] if not colors.is_empty() else Color.WHITE
	# TODO: RichTextLabel
