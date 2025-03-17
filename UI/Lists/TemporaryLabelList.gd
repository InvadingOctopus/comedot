## A [Container] which creates copies of [FadingLabel.tscn] and groups them in a list. May be used for logs, alerts, or chat messages etc.
## NOTE: This script must be attached to a container like [VBoxContainer] or [GridContainer].

class_name TemporaryLabelList
extends Container


#region Parameters
## If a new label is created when the total count of child [Label]s in this Control is >= this number, the first child [Label] is removed.
@export var maximumLabels: int = 5
#endregion


func createTemporaryLabel(text: String) -> Label:
	if haveMaximumLabelCount(): deleteOldestLabel()

	var newLabel: Label = load("res://UI/Labels/FadingLabel.tscn").instantiate()
	
	if newLabel:
		newLabel.text = text
		self.add_child(newLabel)
		newLabel.owner = self # INFO: Necessary for persistence to a [PackedScene] for save/load.
		return newLabel
	else:
		Debug.printWarning("Cannot create an instance of FadingLabel")
		return null


func getLabelCount() -> int:
	var labelCount: int = 0
	for child: Variant in self.get_children():
		if child is Label:
			labelCount += 1
	return labelCount


## Returns `true` if the number of [Label] children is equal to higher than [member maximumLabels].
func haveMaximumLabelCount() -> bool:
	return self.getLabelCount() >= maximumLabels


## Removes and returns the first [Label] found. May be `null` if no [Label] found.
func deleteOldestLabel() -> Label:
	# TODO: Handle deleting more than 1
	var labelToRemove: Label = Tools.findFirstChildOfType(self, Label)

	if labelToRemove:
		self.remove_child(labelToRemove)
		labelToRemove.queue_free()

	return labelToRemove
