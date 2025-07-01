## Replaces the first [Control] child with a different child in response to a child button or another event.

class_name UINavigationContainer
extends Container

# TODO: More flexibility and reliability?
# TODO: A UI navigation system based on global signals?


#region Parameters
@export var backButton: Button ## The "Back" button to show and hide depending on the navigation history.
@export var debugMode:  bool = false
#endregion


#region State
## A stack of scene paths representing the UI navigation history.
## NOTE: The END of the array is the TOP of the stack, and is the most recent scene/node/control.
var navigationStack: PackedStringArray # Better performance than Array[String]
#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	resetHistory()
	if backButton:  connectBackButton()
	elif debugMode: Debug.printWarning("Missing backButton", self) # Suppress warning in case there is a different way to close, such as the PauseButton.


#region History Stack Management

## Clears the [member navigationStack] array and re-adds the first child as the first member.
## Returns: The first child of type [Control]
func resetHistory() -> Control:
	navigationStack.clear()

	var firstChild: Control = self.findFirstChildControl()
	if  firstChild: addNodeToHistory(firstChild.scene_file_path)

	updateBackButton()
	showDebugInfo()
	return firstChild


## Returns: The new size of the history array.
func addNodeToHistory(path: String) -> int:
	navigationStack.append(path)
	updateBackButton()
	showDebugInfo()
	return navigationStack.size()


## Returns `true` if the [member navigationStack] history successfully moved back, i.e. the stack size is > 1.
func goBack() -> bool:
	# GODOT: Why is there no pop_back() for PackedArrays??

	if debugMode: Debug.printTrace([self.get_children()], self)

	# Have to have at least 2 nodes to be able to go back in history.
	# NOTE: Do not store the size because it will change.
	if navigationStack.size() < 2: return false

	# Remove the currently displayed node
	navigationStack.remove_at(navigationStack.size() - 1)

	# Pop again to get the previous node
	var previousDestination: String = navigationStack[navigationStack.size() - 1]
	navigationStack.remove_at(navigationStack.size() - 1)
	# It will be appended to [navigationStack] again in displayNavigationDestination()

	self.displayNavigationDestination(previousDestination)
	return true

#endregion


#region Child Management

func findFirstChildControl() -> Control:
	return Tools.findFirstChildOfType(self, Control, false) # not includeParent


## Removes the first child, if any, and adds the specified [Control].
func replaceFirstChildControl(newControl: Control) -> bool:
	var childToReplace: Control = self.findFirstChildControl()

	if debugMode: Debug.printDebug(str("replaceFirstChildControl(): ", childToReplace, " → ", newControl), self)

	if childToReplace:
		if Tools.replaceChild(self, childToReplace, newControl):
			childToReplace.queue_free() # NOTE: Important, as [remove_child()] does not delete the child.
			return true
	else: # If there are no children, just add the new one.
		Tools.addChildAndSetOwner(newControl, self)
		return true

	showDebugInfo()
	return false


## Replaces the current first child of this container and displays a new control and pushes it onto the [member navigationStack].
## [param newDestination]: The path of the new sub-scene (UI container) to display in this container.
## IMPORTANT: The root node of the new child scene MUST be a [Control].
func displayNavigationDestination(newDestinationPath: String) -> bool:
	if  debugMode: Debug.printDebug("displayNavigationDestination(): " + newDestinationPath, self)
	var newDestinationScene: Node = SceneManager.instantiateSceneFromPath(newDestinationPath) #navigationDestination.instantiate()
	var result: bool

	if newDestinationScene is not Control:
		Debug.printWarning(str("newDestinationScene is not a Control: ", newDestinationScene, " @ ", newDestinationPath), self)
		return false

	# NOTE: Clear the UI focus if the Back Button is about to disappear, so [SetInitialFocus].gd can redirect the focus.
	if navigationStack.size() < 2: self.get_viewport().gui_release_focus()

	if self.replaceFirstChildControl(newDestinationScene):
		navigationStack.append(newDestinationPath)
		result = true
	else:
		result = false

	updateBackButton()
	if debugMode:
		showDebugInfo()
		Debug.printDebug(str("1st Child: ", self.findFirstChildControl(), " — History: ", navigationStack), self)
	return result

#endregion


#region User Input

func connectBackButton() -> void:
	if backButton: Tools.connectSignal(backButton.pressed, self.onBackButton_pressed)


func onBackButton_pressed() -> void:
	goBack()


func updateBackButton() -> void:
	if not is_instance_valid(backButton): return
	# Show the button if there is more than 1 node in the history.
	backButton.visible = navigationStack.size() > 1

#endregion


func showDebugInfo() -> void:
	if not debugMode: return
	Debug.watchList.navigationFirstChild = self.findFirstChildControl()
	Debug.watchList.navigationStack = "\n⬆ ".join(self.navigationStack)
