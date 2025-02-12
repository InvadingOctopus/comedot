## A [Label] that cycles through multiple strings of text at a [Timer] interval.

class_name TextCyclingLabel
extends Label


#region Parameters

## The list of text to display in turn when the [Timer] ticks.
@export var textStrings: PackedStringArray = [
	"Text Cycling Label",
	"2nd Text",
	"Final Text"
]

## If `true`, each new string is appended instead of overwriting any existing text.
## NOTE: New lines are NOT automatically inserted; they must be added to the source strings.
@export var shouldAppendText: bool = false

## If `true`, the label will be removed from the scene when the [Timer] ticks after the last string is displayed.
## NOTE: This flag supercedes [member shouldWarpToFirstString].
@export var shouldDeleteAfterLastString: bool = false

## If `true` and not [member shouldDeleteAfterLastString], the first string will be displayed when the [Timer] ticks after the last string is displayed.
@export var shouldWarpToFirstString: bool = false

#endregion


#region State
var textIndex: int = 0
#endregion


#region Signals
signal didDisplayFinalString
signal didWarpToFirstString
#endregion


#region Dependencies
@onready var timer: Timer = %TextTimer
#endregion


func _ready() -> void:
	displayTextAtIndex()


func getTextAtIndex(indexOverride: int = self.textIndex) -> String:
	if indexOverride >= 0 and indexOverride < textStrings.size():
		return textStrings[indexOverride]
	else:
		Debug.printDebug(str("Invalid index: ", indexOverride))
		return ""


func onTextTimer_timeout() -> void:
	## Increment the index first, because the first string should already be displayed in `_ready()`
	cycleIndex()
	if textIndex < textStrings.size(): displayTextAtIndex() # NOTE: Check index here to avoid logging the error message after we just displayed the last string.


func cycleIndex() -> void:
	textIndex += 1

	# Did the index go past the last string?
	if textIndex >= textStrings.size(): # The array size is 1 greater than the last valid index
		didDisplayFinalString.emit()
		
		if shouldDeleteAfterLastString:
			textIndex = textStrings.size() - 1 # Keep the index at the valid end, just in case some other object tries to access it.
			timer.stop()
			self.queue_free()

		elif shouldWarpToFirstString:
			textIndex = 0
			didWarpToFirstString.emit()
		

func displayTextAtIndex() -> void:
	if shouldAppendText: self.text += getTextAtIndex()
	else: self.text = getTextAtIndex()
