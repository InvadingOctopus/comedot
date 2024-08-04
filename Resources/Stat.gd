## Represents a statistic on a character or object, such as the player's health or an enemy's attack power.
## May be optionally tied to a UI HUD element to update the display whenever the value changes.
@tool # To clamp values when editing stats in the editor. # WARNING: This is causing errors on editor launch because of the GameState signal access.
class_name Stat
extends Resource

#region Parameters

@export var name:   StringName:
	set(newValue):
		if newValue.is_empty():
			Debug.printWarning("Rejected attempt to set name to empty string")
			return
		name = newValue
		self.resource_name = name

## Minimum value allowed. Clamps [member initial] and [member value] when set.
@export var min:    int = 0: # IGNORE Godot Warning; variable names can be the same as built-in functions.
	set(newValue):
		min     = newValue
		if  min > max: max = min
		value   = clamp(value,   min, max)

## Maximum value allowed. Clamps [member initial] and [member value] when set.
@export var max:    int = 10: # IGNORE Godot Warning; variable names can be the same as built-in functions.
	set(newValue):
		max     = newValue
		if  max < min: min = max
		value   = clamp(value,   min, max)


## The current value of the stat. Clamped between [member min] and [member max].
@export var value:  int = max:
	set(newValue):
		previousValue = value
		value = clamp(newValue, min, max)

		if value != previousValue:
			previousChange = previousValue - value

			if logChanges:
				Debug.printDebug(str(self) + " " + str(name) + ": " + str(previousValue) + " → " + str(value) + " (" + str(previousChange) + ")")

			emit_changed()

			if not Engine.is_editor_hint(): # TBD: Is this check too expensive for frequently updated stats?
				GameState.HUDStatUpdated.emit(self) # TBD: Should this be optional? CHECK: Are signals expensive for frequently updated stats?


@export var logChanges := false

#endregion


#region Derived Properties

var previousValue:  int
var previousChange: int ## previousValue - value

var percentage: float: ## The current [member value] as a percentage of the [member max] limit.
	get: return float(value) / float(max) * 100.0

#endregion
