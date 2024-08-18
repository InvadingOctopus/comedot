## Represents a statistic on a character or object, such as the player's health or an enemy's attack power.
## May be optionally tied to a UI HUD element to update the display whenever the value changes.

#@tool # To clamp values when editing stats in the editor. # WARNING: This is causing errors on editor launch because of the GameState signal access. It doesn't seem to provide much usage benefit, so it's disabled instead of using a potentially expensive `Engine.is_editor_hint()` check during each change.
class_name Stat
extends Resource

# TODO: Support float?


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
			previousChange = value - previousValue # NOTE: A decrease should be a negative change.

			if logChanges:
				# NOTE: PERFORMANCE: We don't use `Debug.printChange()` because we already checked for changes.
				Debug.printDebug(str(self) + " " + str(name) + ": " + str(previousValue) + " → " + str(value) + " (" + str(previousChange) + ")")

			# Signals
			# TBD: CHECK: PERFORMANCE: Are signals expensive for frequently updated stats?

			emit_changed()

			# NOTE: We don't use `elif` because more than one signal may be emitted during a single change, if min/max/0 are equal.
			
			if previousChange > 0: # Were we rising?
				if value >= max: didMax.emit()
				if value >= 0:	 didZero.emit()

			if previousChange < 0: # Were we falling?
				if value <= min: didMin.emit()
				if value <= 0:	 didZero.emit()
			
			GameState.HUDStatUpdated.emit(self) # TBD: Should this be optional?


@export var logChanges: bool = false

#endregion


#region Derived Properties

var previousValue:  int
var previousChange: int ## [member value] - [member previousValue] so a decrease is a negative number.

var percentage: float: ## The current [member value] as a percentage of the [member max] limit.
	get: return float(value) / float(max) * 100.0

#endregion



#region Signals

# NOTE: More than one signal may be emitted during a single change, if [member min] & [member max] are equal, or also equal to 0.

signal didMax  ## Only emitted when [member previousChange] is >= +1
signal didMin  ## Only emitted when [member previousChange] is <= -1
signal didZero ## Emitted whether the value is rising or falling. See [member previousChange] to check the direction of approach to 0.
#endregion
