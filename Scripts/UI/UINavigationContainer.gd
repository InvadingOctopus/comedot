## Replaces the first [Control] child with a different child in response to a child button or another event.

class_name UINavigationContainer
extends Container


# TODO: More flexibility and reliability?

var navigationHistory: Array[String] # TBD: Is [PackedStringArray] better?


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	resetHistory()


## Clears the [member navigationHistory] array and re-adds the first child as the first member.
## Returns: The first child of type [Control]
func resetHistory() -> Control:
	navigationHistory.clear()

	var firstChild: Control = self.findFirstChildControl()
	if firstChild: addNodeToHistory(firstChild.scene_file_path)

	return firstChild


func addNodeToHistory(path: String):
	navigationHistory.append(path)


func findFirstChildControl() -> Control:
	return Global.findFirstChildOfType(self, Control)


func replaceFirstChildControl(newControl: Control) -> bool:
	var childToReplace: Control = self.findFirstChildControl()

	if childToReplace:
		if Global.replaceChild(self, childToReplace, newControl):
			childToReplace.queue_free() # NOTE: Important, as [remove_child()] does not delete the child.
			return true
	else:
		self.add_child(newControl)
		return true

	return false


func displayNavigationDestination(newDestination: String) -> bool:
	var newDestinationScene: Node = Global.instantiateSceneFromPath(newDestination) #navigationDestination.instantiate()

	if self.replaceFirstChildControl(newDestinationScene):
		navigationHistory.append(newDestination)
		return true
	else:
		return false


func onBackButton_pressed() -> void:
	goBack()


func goBack() -> void:
	# Have to have at least 2 nodes to be able to go back in history.
	if navigationHistory.size() <= 1: return

	# Remove the currently displayed node
	navigationHistory.pop_back()

	# Pop again to get the previous node
	var previousDestination = navigationHistory.pop_back()
	# It will be appended to [navigationHistory] again in [displayNavigationDestination()]

	self.displayNavigationDestination(previousDestination)


# DEBUG

#func _process(delta: float):
	#Debug.watchList.firstChild = self.findFirstChildControl()
	#Debug.watchList.navigationHistory = "\n⬆ ".join(self.navigationHistory)




