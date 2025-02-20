## A view for an entry in the custom log, with interactive details about the object that emitted the message.
## @experimental

class_name CustomLogEntryUI
extends Control

# TODO: Add log entry nodes to groups depending on their object's category, e.g. `logEntity` or `logComponent` etc.
# TODO: Get caller function via Debug.getCaller()

#region Parameters

## NOTE: Call [method CustomLogEntryUI.updateUI] after changing this dictionary.
var logEntry: Dictionary[String, Variant] # Doesn't need to be @exported (to disk)

var isShowingExtraDetails: bool = false: # Doesn't need to be @exported (to disk)
	set(newValue):
			isShowingExtraDetails    = newValue
			detailsControl.visible   = not isShowingExtraDetails
			detailsContainer.visible = isShowingExtraDetails

#endregion


#region State
@onready var messageLabel:	Label = %MessageLabel

@onready var detailsControl:	Control   = %ShowDetailsControl
@onready var detailsContainer:	Container = %DetailsContainer

@onready var frameTImeLabel: Label = %FrameTimeLabel
@onready var nameLabel:		Label = %NameLabel
@onready var instanceLabel:	Label = %InstanceLabel
@onready var typeLabel:		Label = %TypeLabel
@onready var nodeClassLabel: Label = %NodeClassLabel
@onready var baseScriptLabel: Label = %BaseScriptLabel
@onready var classNameLabel: Label = %ClassNameLabel
@onready var parentLabel:	Label = %ParentLabel
# @onready var objectLabel:	Label = %ObjectLabel # Redundant information; always "Object"

@onready var labels: Array[Label] = [messageLabel, frameTImeLabel, nameLabel, instanceLabel, typeLabel, nodeClassLabel, baseScriptLabel, classNameLabel, parentLabel]
#endregion


func _ready() -> void:
	updateUI()


func updateUI() -> void:
	Tools.setLabelsWithDictionary(self.labels, self.logEntry, false, false) # Don't show labels, don't hide labels, because some are already permanently hidden.


func onToggleDetailsControl_guiInput(event: InputEvent) -> void:
	if  event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		isShowingExtraDetails = not isShowingExtraDetails
		accept_event()
	pass
