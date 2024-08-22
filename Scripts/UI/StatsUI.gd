## A [Container] [Control] which builds a list of [StatLabel]s for all the stats in a [StatsComponent].

class_name StatsUI
extends Container


#region Parameters
## The [StatsComponent] to build [StatLabel]s from.
## NOTE: Does NOT monitor the addition or removal of stats at runtime.
@export var statsComponent: StatsComponent
#endregion


#region Dependencies
const statLabelScene: PackedScene = preload("res://Scenes/UI/StatLabel.tscn")
#endregion


func _ready() -> void:
	if statsComponent: 
		buildLabels()
	else:
		Debug.printWarning("Missing statsComponent", str(self))


## Creates a [StatLabel] for each of the [Stat] in the [member statsComponent].
## Removes all existing child nodes.
func buildLabels() -> void:
	Tools.removeAllChildren(self)
	for stat in statsComponent.stats:
		createStatLabel(stat)


func createStatLabel(stat: Stat) -> StatLabel:
	var newLabel: StatLabel = statLabelScene.instantiate()
	newLabel.stat = stat
	Tools.addChildAndSetOwner(newLabel, self)
	# newLabel.updateStatText() # Is this necessary? Won't it be called on the label's _ready()?
	return newLabel