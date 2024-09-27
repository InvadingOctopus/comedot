## Creates a list of [InputActionUI] for the player to view or customize/remap Input Actions.
## Attach this script to any UI [Container] [Control] such as a [GridContainer] or [VBoxContainer],
## making sure to nest that container inside a [ScrollContainer].

class_name InputActionsList
extends Container


#region Constants
const inputActionUIScene  := preload("res://UI/InputActionUI.tscn")
const uiInputActionPrefix := &"ui_"
#endregion


#region Parameters
#endregion


func _ready() -> void:
	buildList()


func buildList() -> void:
	# Get ALL the input actions
	var inputActions: Array[StringName] = InputMap.get_actions()

	# Remove all the built-in Godot UI input actions, because they don't need to be customized them in a game
	inputActions = inputActions.filter(isNotUIAction)

	# Add a Label for each Input Action
	for inputActionName in inputActions:
		var newActioUI: InputActionUI = inputActionUIScene.instantiate()
		newActioUI.inputAction = inputActionName
		Tools.addChildAndSetOwner(newActioUI, self)


## Used for filtering the list by exclusing built-in Godot UI input actions.
func isNotUIAction(inputActionName: StringName) -> bool:
	return not inputActionName.begins_with(uiInputActionPrefix)
