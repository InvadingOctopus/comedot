## A script for [Container] controls which manage a HUD UI to display the values of [Stat] Resources.
## To use, add [Label] child nodes and name them with the convention: "[Stat's name]Label" e.g. "healthLabel"
## NOTE: The case should be exactly the same as the [member Stat.name] of the [Stat] which should be displayed via that label! Do NOT use the [member Stat.displatName].

class_name StatsUI
extends Container


#region Parameters

## If `true`, the Stat's value will be prefixed with its [member Stat.displayName].
@export var shouldPrefixValueWithStatName: bool = false

## An optional dictionary of additional prefixes to write in the [Label] before the value of each [Stat].
## The dictionary types should be {[StringName]:[String]}, where the keys are the names of the stats (`playerHealth`, `levelTime`) in the exact case.
## If [member shouldPrefixValueWithStatName] is `true`, the name will be added after the custom prefix.
@export var prefixes: Dictionary = {&"health": "HP:"}

## An optional dictionary of suffixes to write in the [Label] after the value of each [Stat].
## The dictionary type should be {[StringName]:[String]}, where the keys are the names of the stats (`playerHealth`, `levelTime`) in the exact case.
@export var suffixes: Dictionary = {}

## A list of stats to display as soon as the Stats UI is ready,
## without waiting for a signal for a change in a stat's value.
@export var statsToUpdateOnReady: Array[Stat]

## If greater than 1, then smaller values will be padded with leading 0s.
@export var minimumDigits: int = 2 # TODO: Different for each stat

#endregion


func _ready() -> void:
	updateInitialStats()
	GameState.HUDStatUpdated.connect(self.onGameState_HUDStatUpdated)


func updateInitialStats() -> void:
	if statsToUpdateOnReady.is_empty(): return
	for stat in statsToUpdateOnReady:
		updateStatLabel(stat, false)


func onGameState_HUDStatUpdated(stat: Stat) -> void:
	updateStatLabel(stat)


func updateStatLabel(stat: Stat, animate: bool = true) -> void:
	var label: Label = self.find_child(stat.name + "Label") as Label
	if not label: return

	var statName: StringName = stat.name # Cache

	var prefix: String = self.prefixes.get(statName, "")
	var suffix: String = self.suffixes.get(statName, "")

	if shouldPrefixValueWithStatName: prefix += " " + stat.displayName + " " # NOTE: Use stat.displayName

	label.text = buildLabelText(prefix, stat, suffix)
	if animate:  Animations.animateNumberLabel(label, stat.value, stat.previousValue)


## Combines the prefix, value of the stat and the suffix.
## May be customized by a subclass for game specific styles,
## e.g.: drawing multiple hearts instead of a number to represent lives.
func buildLabelText(prefix: String, stat: Stat, suffix: String) -> String:
	if minimumDigits >= 1:
		var format: String = "%0" + str(minimumDigits) + "d"
		return str(prefix, format % stat.value, suffix)
	else:
		return str(prefix, stat.value, suffix)

