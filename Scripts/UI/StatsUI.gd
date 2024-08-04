## A script for nodes which manage a HUD UI that displays the values of [Stat] Resources.
## To use this, add [Label] child nodes and name them with this convention: "[Stat's name]Label"
## NOTE: The case should be exactly the same as the name of the [Stat] which should be displayed via that label!

class_name StatsUI
extends Control


#region Parameters

@export var shouldPrefixValueWithStatName := false

## An optional dictionary of additional prefixes to write in the [Label] before the value of each [Stat].
## The dictionary types should be {[StringName]:[String]}, where the keys are the names of the stats (`playerHealth`, `levelTime`) in the exact case.
## If [member shouldPrefixValueWithStatName] is `true`, the name will be added after the custom prefix.
@export var prefixes := {&"health": "HP:"}

## An optional dictionary of suffixes to write in the [Label] after the value of each [Stat].
## The dictionary type should be {[StringName]:[String]}, where the keys are the names of the stats (`playerHealth`, `levelTime`) in the exact case.
@export var suffixes := {&"health": "♡"}

## A list of stats to display as soon as the Stats UI is ready,
## without waiting for a signal about a change.
@export var statsToUpdateOnReady: Array[Stat]

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

	if shouldPrefixValueWithStatName: prefix += " " + statName + " "

	label.text = buildLabelText(prefix, stat, suffix)
	if animate: animateLabel(label, stat.value, stat.previousValue)


## Combines the prefix, value of the stat and the suffix.
## May be customized by a subclass for game specific styles,
## e.g.: drawing multiple hearts instead of a number to represent lives.
func buildLabelText(prefix: String, stat: Stat, suffix: String) -> String:
	var labelText: String = str(prefix, stat.value, suffix)
	return labelText


## Plays different animations on a label depending on how the [Stat]'s value changes.
## May be overridden in a subclass.
func animateLabel(label: Label, value, previousValue) -> void: # NOTE: IGNORE Godot Warning; Values not typed so we can use [float].
	var color: Color
	const duration: float = 0.25 # TBD: Should this be an argument?

	if    value > previousValue: color = Color.GREEN
	elif  value < previousValue: color = Color.RED
	else: return

	var defaultColor: Color = Color.WHITE # TODO: CHECK: A better way to reset a property.

	var tween: Tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate", color, duration)
	tween.tween_property(label, "modulate", defaultColor, duration)


# TODO: Use a more compact and strictly-typed resource,
# but Godot as of 4.3 Dev 3 does not support creating instances of an "inner class"
# inside the editor yet :(

#class StatLabelPrefixAndSuffix:
	#extends Resource

	#@export var statName: StringName
	#@export var prefix: String
	#@export var suffix: String

#@export var prefixesResources: Array[StatLabelPrefixAndSuffix]
