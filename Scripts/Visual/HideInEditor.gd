## Hides a node in the Godot Editor only. Useful for reducing visual clutter during development or not wasting performance on expensive shaders etc.

@tool
class_name HideInEditor
extends CanvasItem


#region Parameters
@export var shouldHideInEditor: bool = false:
	set(newValue):
		shouldHideInEditor = newValue
		updateVisibility()
#endregion


func _ready() -> void:
	# TODO: FIXME: Not working when the script is first attached.
	updateVisibility()


func updateVisibility() -> void:
	if Engine.is_editor_hint():
		self.visible = not shouldHideInEditor
	else:
		self.visible = true


