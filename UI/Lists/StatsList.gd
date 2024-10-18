## Builds a list of [StatLabel]s for all the stats in a [StatsComponent].
## Attach this script to any [Container] [Control] such as a [GridContainer] or [HBoxContainer].

class_name StatsList
extends Container


#region Parameters

## The [StatsComponent] to build [StatLabel]s from.
## If `null`, then the [member GameState.players] Player Entity will be searched.
## NOTE: Does NOT monitor the addition or removal of Stats at runtime.
@export var statsComponent: StatsComponent

## If greater than 1, then smaller values will be padded with leading 0s.
## Will apply to all [StatLabels].
@export var minimumDigits: int = 2

@export var horizontalAlignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT ## The aligment for all newly created [Label]s.
@export var verticalAlignment:	 VerticalAlignment   = VERTICAL_ALIGNMENT_CENTER ## The aligment for all newly created [Label]s


@export var shouldUppercase: bool = false ## Make all [StatLabel]s [member Label.uppercase].
@export var shouldShowText:  bool = true  ## Only affects newly created [StatLabel]s.
@export var shouldShowIcon:  bool = true  ## Only affects newly created [StatLabel]s.

#endregion


#region Dependencies
const statLabelScene: PackedScene = preload("res://UI/Labels/StatLabel.tscn")
#endregion


func _ready() -> void:
	if not statsComponent:
		var player: PlayerEntity = GameState.players.front()
		if player: self.statsComponent = player.statsComponent

	if statsComponent: buildLabels()
	else: Debug.printWarning("Missing statsComponent", self)


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
	newLabel.shouldShowText				= self.shouldShowText
	newLabel.shouldShowIcon				= self.shouldShowIcon
	newLabel.shouldUppercase			= self.shouldUppercase

	Tools.addChildAndSetOwner(newLabel, self)
	newLabel.label.horizontal_alignment = self.horizontalAlignment
	newLabel.label.vertical_alignment   = self.verticalAlignment

	# newLabel.updateStatText() # Is this necessary? Won't it be called on the label's _ready()?
	return newLabel
