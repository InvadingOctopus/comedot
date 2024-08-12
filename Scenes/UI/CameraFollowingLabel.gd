## A [Label] which follows the [Camera2D] for a limited time then "sticks" to a fixed position.
## Deleted when offscreen. May be used for help or tutorial text or other forms of temporary alerts.

class_name CameraFollowingLabel
extends Label


#region Parameters

## The list of text to display in turn when the [Timer] ticks.
@export var textStrings: Array[String] = [
	"Initial Text",
	"2nd Text",
	"Final Text"
]

## If unspecified, gets the player Entity's [Camera2D] via [member GameState.players].
@export var camera: Camera2D

#endregion


#region State
var textIndex: int = 0

@onready var labelContainer: Container = %LabelContainer
@onready var labelTimer: Timer = %LabelTimer # FIXED: Need to store a reference because the unique name seems to be invalid after reparenting.
#endregion


func _ready() -> void:
	self.text = getTextAtIndex()
	if not camera:
		camera = GameState.players.front().findFirstChildOfType(Camera2D)


func getTextAtIndex(indexOverride: int = self.textIndex) -> String:
	if indexOverride >= 0 and indexOverride < textStrings.size():
		return textStrings[indexOverride]
	else:
		return ""


func onLabelTimer_timeout() -> void:
	textIndex += 1

	# Did we reach the last string?
	if textIndex == textStrings.size():
		# "Flatten" the label into the world; drop the feather to the ground :)
		var newParent := get_tree().current_scene
		var screenTopLeft := Tools.getScreenTopLeftInCamera(camera)

		labelContainer.reparent(newParent, false)
		labelContainer.owner = newParent
		labelContainer.global_position = screenTopLeft
		labelTimer.stop()
	else:
		self.text += "\n" + getTextAtIndex()
