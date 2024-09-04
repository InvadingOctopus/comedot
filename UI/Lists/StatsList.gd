## A [Container] [Control] which builds a list of [StatLabel]s for all the stats in a [StatsComponent].

class_name StatsList
extends Container


#region Parameters

## The [StatsComponent] to build [StatLabel]s from.
## If `null`, then the [member GameState.players] Player Entity will be searched.
## NOTE: Does NOT monitor the addition or removal of stats at runtime.
@export var statsComponent: StatsComponent

## If greater than 1, then smaller values will be padded with leading 0s.
## Will apply to all [StatLabels].
@export var minimumDigits: int = 2

@export var horizontalAlignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT ## The aligment for all newly created [Label]s.
@export var verticalAlignment:	 VerticalAlignment   = VERTICAL_ALIGNMENT_CENTER ## The aligment for all newly created [Label]s

## Make all [StatLabel]s [member Label.uppercase].
@export var shouldWriteAllUppercase: bool = false

#endregion


#region Dependencies
const statLabelScene: PackedScene = preload("res://UI/Labels/StatLabel.tscn")
#endregion


func _ready() -> void:
	if not statsComponent:
		var player: PlayerEntity = GameState.players.front()
		if player: self.statsComponent = player.statsComponent

	if statsComponent: buildLabels()
	else: Debug.printWarning("Missing statsComponent", str(self))


## Creates a [StatLabel] for each of the [Stat] in the [member statsComponent].
## Removes all existing child nodes.
func buildLabels() -> void:
	Tools.removeAllChildren(self)
	for stat in statsComponent.stats:
		createStatLabel(stat)


func createStatLabel(stat: Stat) -> StatLabel:
	var newLabel: StatLabel = statLabelScene.instantiate()
	newLabel.stat = stat
	newLabel.minimumDigits = self.minimumDigits
	newLabel.horizontal_alignment = self.horizontalAlignment
	newLabel.vertical_alignment = self.verticalAlignment
	newLabel.shouldWriteAllUppercase = self.shouldWriteAllUppercase
	
	Tools.addChildAndSetOwner(newLabel, self)
	# newLabel.updateStatText() # Is this necessary? Won't it be called on the label's _ready()?
	return newLabel
