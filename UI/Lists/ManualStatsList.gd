## A script for [Container] controls which manage a HUD UI to display the values of [Stat] Resources when they emit the [signal GameState.statUpdated] signal.
## To use, add [Label] child nodes and name them with the convention: "[Stat's name]Label" e.g. "healthLabel"
## NOTE: The case should be exactly the same as the [member Stat.name] of the [Stat] which should be displayed via that label! Do NOT use the [member Stat.displayName].
## TIP: If you have [Stat]s saved as ".tres" Resource files, use the newer [StatsList] and [StatUI] instead for automatic UI creation and updates.
## ALERT: Order of Resource initialization may cause unexpected updates. For example, the Health Stat saved in HealthComponent.tscn will have its values applied first, and then the modified Stat values saved in an Entity scene which uses that component will be applied. See documentation notes in GameplayResourceBase.gd

class_name ManualStatsList
extends Container


#region Parameters

## If `true`, the Stat's value will be prefixed with its [member Stat.displayName].
@export var shouldPrefixValueWithStatName: bool = false

## An optional dictionary of additional prefixes to write in the [Label] before the value of each [Stat].
## The dictionary types should be {[StringName]:[String]}, where the keys are the names of the stats (`playerHealth`, `levelTime`) in the exact case.
## If [member shouldPrefixValueWithStatName] is `true`, the name will be added after the custom prefix.
@export var prefixes: Dictionary[StringName, String] = {}

## An optional dictionary of suffixes to write in the [Label] after the value of each [Stat].
## The dictionary type should be {[StringName]:[String]}, where the keys are the names of the stats (`playerHealth`, `levelTime`) in the exact case.
@export var suffixes: Dictionary[StringName, String] = {}

## A list of stats to display as soon as the Stats UI is ready,
## without waiting for a signal for a change in a stat's value.
@export var statsToUpdateOnReady: Array[Stat]

## If greater than 1, then smaller values will be padded with leading 0s.
@export var minimumDigits: int = 2 # TODO: Different for each stat

#endregion


func _ready() -> void:
	updateInitialStats()
	Tools.connectSignal(GameState.statUpdated, self.onGameState_statUpdated) # Use Tools method to avoid error on multiple connections


func updateInitialStats() -> void:
	if statsToUpdateOnReady.is_empty(): return
	for stat in statsToUpdateOnReady:
		updateStatUI(stat, false)


func onGameState_statUpdated(stat: Stat) -> void:
	updateStatUI(stat)


func updateStatUI(stat: Stat, animate: bool = true) -> void:
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

