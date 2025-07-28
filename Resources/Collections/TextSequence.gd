## Represents a list of text strings.
## e.g. for conversation dialogues, tutorial help, "signboards" or other information etc.
## TIP: For basic formatting, see pColoredTextSequence].
## @experimental

class_name TextSequence
extends Collection


#region Parameters
@export var strings: PackedStringArray ## The list of text strings to display in turn.
#endregion


#region State
var currentStringIndex:	int # TBD: Should this just be "index" or "currentIndex"? or would that be ambiguous in subclasses like [ColoredTextSequence]?
var previousString:		String
#endregion


#region Collection Implementation

func getCurrentItem() -> String:
	return getItem(currentStringIndex)


func getNextItem() -> String:
	incrementIndex()
	return getItem(currentStringIndex)


func getItem(index: int = currentStringIndex) -> String:
	if   index == 0: willReturnFirstItem.emit()
	elif index == strings.size() - 1: willReturnFinalItem.emit() # The last index
	return strings[index] if Tools.validateArrayIndex(strings, index) else ""


func getPreviousItem() -> String:
	return previousString


func getSize() -> int:
	return strings.size()


## NOTE: [param step] will always be converted to a positive integer.
func incrementIndex(step: int = 1) -> void:
	# TBD: Should we call `Tools.incrementAndWrapArrayIndex()` or would that be slower? :')
	previousString = strings[currentStringIndex] if Tools.validateArrayIndex(strings, currentStringIndex) else ""
	currentStringIndex += absi(step)
	if  currentStringIndex >= strings.size():
		currentStringIndex = 0

#endregion


#region String Alias Methods

func getCurrentString() -> String:
	return getCurrentItem() as String


func getNextString() -> String:
	return getNextItem() as String


func getPreviousString() -> String:
	return getPreviousItem() as String


func getString(index: int = currentStringIndex) -> String:
	return getItem(index) as String

#endregion


#region Abstract Methods
@warning_ignore_start("unused_parameter")

## Optional. Formats a [Label] or [RichTextLabel] according to the current message.
func formatLabel(label: Control) -> void:
	return

#endregion
