## A view for an entry in the custom log, with interactive details about the object that emitted the message.

class_name CustomLogEntryUI
extends Control


#region Parameters

## NOTE: Call [method CustomLogEntryUI.updateUI] after changing this dictionary.
var logEntry: Dictionary # Doesn't need to be @exported (to disk)

var isShowingExtraDetails: bool = false: # Doesn't need to be @exported (to disk)
	set(newValue):
			isShowingExtraDetails = newValue
			detailsButton.visible = not isShowingExtraDetails
			detailsGrid.visible   = isShowingExtraDetails

#endregion


#region State
@onready var messageLabel:	Label = %MessageLabel

@onready var detailsButton:	Button = %DetailsButton
@onready var detailsGrid:	Container = %DetailsGrid

@onready var nameLabel:		Label = %NameLabel
@onready var instanceLabel:	Label = %InstanceLabel
@onready var typeLabel:		Label = %TypeLabel
@onready var nodeClassLabel: Label = %NodeClassLabel
@onready var baseScriptLabel: Label = %BaseScriptLabel
@onready var classNameLabel: Label = %ClassNameLabel
@onready var parentLabel:	Label = %ParentLabel
# @onready var objectLabel:	Label = %ObjectLabel # Redundant information; always "Object"

@onready var labels: Array[Label] = [messageLabel, nameLabel, instanceLabel, typeLabel, nodeClassLabel, baseScriptLabel, classNameLabel, parentLabel]
#endregion


func _ready() -> void:
	updateUI()


func updateUI() -> void:
	Tools.setLabelsWithDictionary(self.labels, self.logEntry, true, false)


func onDetailsGrid_guiInput(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT:
		isShowingExtraDetails = not isShowingExtraDetails
		accept_event()
	pass


func onDetailsButton_pressed() -> void:
	isShowingExtraDetails = not isShowingExtraDetails
