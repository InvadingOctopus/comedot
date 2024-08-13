## A [Label] which follows the [Camera2D] for a limited time then "sticks" to a fixed position.
## Deleted when offscreen. May be used for help or tutorial text or other forms of temporary alerts.
## Extends [TextCyclingLabel].

class_name CameraFollowingLabel
extends TextCyclingLabel


#region Parameters
## If unspecified, gets the player Entity's [Camera2D] via [member GameState.players].
@export var camera: Camera2D
#endregion


#region State
@onready var labelContainer: Container = %LabelContainer
#endregion


func _ready() -> void:
	super._ready()
	if not camera:
		camera = GameState.players.front().findFirstChildOfType(Camera2D)
	self.didDisplayFinalString.connect(onDidDisplayFinalString)


func onDidDisplayFinalString() -> void:
	# "Flatten" the label into the world; drop the feather to the ground :)
	var newParent := get_tree().current_scene
	var screenTopLeft := Tools.getScreenTopLeftInCamera(camera)

	labelContainer.reparent(newParent, false)
	labelContainer.owner = newParent
	labelContainer.global_position = screenTopLeft
	self.timer.stop()

