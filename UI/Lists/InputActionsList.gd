## Creates a list of [InputActionUI] for the player to view or customize/remap Input Actions.
## Attach this script to any UI [Container] [Control] such as a [GridContainer] or [VBoxContainer],
## making sure to nest that container inside a [ScrollContainer].

class_name InputActionsList
extends Container

# TODO: Build a focus chain between list items and their [InputActionEventUI] subchildren
# TODO: Icons for keys & gamepad buttons


#region Constants
const inputActionUIScene := preload("res://UI/InputActionUI.tscn")
#endregion


func _ready() -> void:
	buildList()
	# Focus the first item
	if self.get_child_count() > 0:
		var firstUI: InputActionUI = get_child(0)
		firstUI.get_node(^"%AddButton").grab_focus() # TODO: Avoid janky string searching


func buildList() -> void:
	# Get ALL the input actions
	var inputActions: Array[StringName] = InputMap.get_actions()

	# Remove the actions that don't need to be customized or aren't used in a specific game.
	inputActions = inputActions.filter(checkActionInclusion)
	if inputActions.is_empty(): return

	# Start with a clean slate so we don't have any duplicates.
	Tools.removeAllChildren(self)

	# Add a Label for each Input Action
	for inputActionName in inputActions:
		var newActioUI: InputActionUI = inputActionUIScene.instantiate()
		newActioUI.inputAction = inputActionName
		Tools.addChildAndSetOwner(newActioUI, self)


## Used for filtering the list e.g. by excluding built-in Godot UI input actions.
func checkActionInclusion(inputActionName: StringName) -> bool:
	return  not inputActionName.begins_with(GlobalInput.Actions.uiPrefix) \
		and not GlobalInput.Actions.excludedFromCustomization.has(inputActionName)
