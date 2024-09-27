## UI representing an Input Action along with all its [InputEvent]s for the player to customize and reassign different controls to.

class_name InputActionUI
extends Container

# TODO: Implement saving


#region Constants
const inputActionEventUIScene := preload("res://UI/InputActionEventUI.tscn")
#endregion


#region Parameters
@export var inputAction: StringName
#endregion


#region State
var isAddingNewControl: bool = false

@onready var label: Label = %Label
@onready var eventsList: Container = $EventsList
#endregion


#region Signals
@warning_ignore("unused_signal")
signal didAddInputEvent(inputAction: StringName, inputEvent: InputEvent) ## Also emitted by the [GlobalInput] AutoLoad.
#endregion


func _ready() -> void:
	if InputMap.has_action(self.inputAction):
		updateUI()
	else:
		Debug.printWarning(str("Invalid inputAction: ", inputAction), str(self))


func updateUI() -> void:
	label.text = self.inputAction.capitalize() # Format the names to be more palatable
	buildEventsList()


# Rebuilds the [InputEvent]s list.
func buildEventsList() -> void:
	var inputEvents: Array[InputEvent] = InputMap.action_get_events(inputAction)

	Tools.removeAllChildren(eventsList)

	for event in inputEvents:
		createEventUI(event)


func createEventUI(event: InputEvent) -> InputActionEventUI:
	var newEventUI: InputActionEventUI = inputActionEventUIScene.instantiate()
	newEventUI.inputAction = self.inputAction
	newEventUI.inputEvent  = event
	Tools.addChildAndSetOwner(newEventUI, eventsList)
	return newEventUI


func onAddButton_pressed() -> void:
	if isAddingNewControl: return
	else: receiveNewControl()


func receiveNewControl() -> void:
	if isAddingNewControl: return
	isAddingNewControl = true


func _input(event: InputEvent) -> void:
	if not isAddingNewControl: return
	if event.is_pressed():
		addNewControl(event)
		isAddingNewControl = false


func addNewControl(newEvent: InputEvent) -> void:
	InputMap.action_add_event(self.inputAction, newEvent)
	createEventUI(newEvent)
	self.didAddInputEvent.emit(self.inputAction, newEvent)
	GlobalInput.didAddInputEvent.emit(self.inputAction, newEvent)
