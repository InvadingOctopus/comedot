## Represents an [InputEvent]: A keyboard key, gamepad button, or joystick axis etc. for an "Input Action",
## and allows the player to remove this control from the Input Action.

class_name InputActionEventUI
extends Container

# DESIGN: Named "InputActionEvent" not "InputEventAction" because it shows one of the Events for an Action, not the other way around :)
# TODO:   Implement Save/Load
# CHECK:  PERFORMANCE: Could using potentially 100 [LongPressButton]s (including their [Timer]s) be problematic?


#region Parameters
@export var inputEvent:  InputEvent
@export var inputAction: StringName
#endregion


#region State
@onready var label: Label = $Label
#endregion


#region Signals
signal didDeleteInputEvent(inputAction: StringName, inputEvent: InputEvent) ## Also emitted by the [GlobalInput] AutoLoad.
#endregion


func _ready() -> void:
	if inputEvent: updateUI()
	else: Debug.printWarning("No inputEvent", self)


func updateUI() -> void:
	var eventControlText: String = inputEvent.as_text()
	eventControlText = Tools.replaceStrings(eventControlText, GlobalInput.eventTextReplacements) \
		.replacen("(Keyboard)", "Key") \
		.replacen("Motion on ", "")
	label.text = eventControlText


func deleteEvent() -> void:
	if not inputAction:
		Debug.printWarning("Missing inputAction", self)
		return

	InputMap.action_erase_event(self.inputAction, self.inputEvent)
	self.didDeleteInputEvent.emit(self.inputAction, self)
	GlobalInput.didDeleteInputEvent.emit(self.inputAction, self)
	self.queue_free()


func onDeleteButton_longPressed() -> void:
	deleteEvent()
