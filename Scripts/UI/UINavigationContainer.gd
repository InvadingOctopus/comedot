## Replaces the first [Control] child with a different child in response to a child button or another event.

class_name UINavigationContainer
extends Container

# TODO: More flexibility and reliability?


#region Parameters
@export var backButton: Button ## The "Back" button to show and hide depending on the navigation history.
@export var shouldShowDebugInfo: bool = false
#endregion


#region State
var navigationHistory: Array[String] # TBD: Is [PackedStringArray] better?
#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	resetHistory()
	connectBackButton()


func connectBackButton() -> void:
	backButton.pressed.connect(self.onBackButton_pressed)


## Clears the [member navigationHistory] array and re-adds the first child as the first member.
## Returns: The first child of type [Control]
func resetHistory() -> Control:
	navigationHistory.clear()

	var firstChild: Control = self.findFirstChildControl()
	if firstChild: addNodeToHistory(firstChild.scene_file_path)

	updateBackButton()
	showDebugInfo()
	return firstChild


## Returns: The new size of the history array.
func addNodeToHistory(path: String) -> int:
	navigationHistory.append(path)
	updateBackButton()
	showDebugInfo()
	return navigationHistory.size()


func findFirstChildControl() -> Control:
	return Tools.findFirstChildOfType(self, Control)


func replaceFirstChildControl(newControl: Control) -> bool:
	var childToReplace: Control = self.findFirstChildControl()

	if childToReplace:
		if Tools.replaceChild(self, childToReplace, newControl):
			childToReplace.queue_free() # NOTE: Important, as [remove_child()] does not delete the child.
			return true
	else:
		self.add_child(newControl)
		return true
	
	showDebugInfo()
	return false


func displayNavigationDestination(newDestination: String) -> bool:
	var newDestinationScene: Node = Tools.instantiateSceneFromPath(newDestination) #navigationDestination.instantiate()
	var result: bool
	
	if self.replaceFirstChildControl(newDestinationScene):
		navigationHistory.append(newDestination)
		result = true
	else:
		result = false
	
	updateBackButton()
	showDebugInfo()
	return result


func onBackButton_pressed() -> void:
	goBack()


func goBack() -> void:
	# Have to have at least 2 nodes to be able to go back in history.
	if navigationHistory.size() <= 1: return

	# Remove the currently displayed node
	navigationHistory.pop_back()

	# Pop again to get the previous node
	var previousDestination: String = navigationHistory.pop_back()
	# It will be appended to [navigationHistory] again in [displayNavigationDestination()]

	self.displayNavigationDestination(previousDestination)


func updateBackButton() -> void:
	if not is_instance_valid(backButton): return
	# Show the button if there is more than 1 node in the history.
	backButton.visible = navigationHistory.size() > 1


func showDebugInfo() -> void:
	if not shouldShowDebugInfo: return
	Debug.watchList.firstChild = self.findFirstChildControl()
	Debug.watchList.navigationHistory = "\n⬆ ".join(self.navigationHistory)
