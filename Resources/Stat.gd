## Represents a statistic on a character or object, such as the player's health or an enemy's attack power.
## TIP: Use [StatUI], [StatBar], [StatPips] to display a game character's [Stats] in the UI.
## TIP: Use the `UI/Lists/[StatsList].gd` script to automatically display and update these values in a HUD during runtime.
## DESIGN: Stats are integers to simplify arithmetic and comparisons and potentially improve performance.
## TIP: If you need to use Stats for objects that require floats, such as [member Timer.wait_time] or [member CooldownComponent.cooldownMillisecondsModifier],
## then let the Stat be multiples of 1000, e.g. milliseconds instead of whole seconds. Then to convert from a Stat to a float, divide by 1000. Vice versa, multiply by 1000.

#@tool # To clamp values when editing stats in the editor. # WARNING: This is causing errors on editor launch because of the GameState signal access. It doesn't seem to provide much usage benefit, so it's disabled instead of using a potentially expensive `Engine.is_editor_hint()` check during each change.
@warning_ignore("missing_tool")
class_name Stat
extends GameplayResourceBase

# TODO: Support float?


#region Parameters

@warning_ignore("shadowed_global_identifier")
## Minimum value allowed. Clamps [member initial] and [member value] when set.
## TIP: Call [method setToMin] instead of setting [member value] to 0 directly.
@export var min: int = 0: # IGNORE: Godot Warning; variable names can be the same as built-in functions.
	set(newValue):
		min     = newValue
		if  min > max: max = min
		value   = clamp(value, min, max)

@warning_ignore("shadowed_global_identifier")
## Maximum value allowed. Clamps [member initial] and [member value] when set.
@export var max: int = 10: # IGNORE: Godot Warning; variable names can be the same as built-in functions.
	set(newValue):
		max     = newValue
		if  max < min: min = max
		value   = clamp(value, min, max)

## The current value of the stat. Clamped between [member min] and [member max].
## NOTE: The default initial value is set equal to [member min].
@export var value: int = min: # DESIGN: Default to `min` because it is almost always 0, but `max` is usually different for most Stats, which causes a redundant `value` change from the default `max` of 10 to the new `max`.
	set = setValue # Use a separate function for the property setter so that it may be overridden in subclasses. The getter should not be overridden as that causes problems in cases like `value = value - 1` etc.

## Logs changes.
## WARNING: May reduce performance if used for very frequently-changing stats.
@export var debugMode: bool = false

#endregion


#region Stat
## If `true` then the next SINGLE [signal Resource.changed] signal is skipped ONCE.
## EXAMPLE USAGE: [InteractionWithCostComponent] uses this to suppress [StatsVisualComponent] animations in case of a refund if a [Payload] fails.
var shouldSkipEmittingNextChange: bool = false
#endregion


#region Value Getter/Setter

## Returns the [member value]. This method may be overridden in a subclass such as [StatWithModifiers] to provide a dynamically modifiable value i.e via gameplay buffs/debuffs etc.
# func getValue() -> int:
#	# NOTE: UNUSED: Overriding the getter causes innumerable issues such as infinite recursion and conflicts with min/max clamps etc. specially in cases like `value = value - 1` so just modify the value once in the setter.
#	# CHECK: PERFORMANCE: Is this bad for frequently accessed Stats?
#	return value


## Sets the [member value] while clamping it between [member min] and [member max]. This method may be overridden in a subclass such as [StatWithModifiers] to provide custom validation or restrictions i.e. via gameplay buffs/debuffs etc.
func setValue(newValue: int) -> void:
	previousValue = value
	value = clampi(newValue, min, max)

	if value != previousValue:
		previousChange = value - previousValue # NOTE: A decrease should be a negative change.

		if debugMode:
			# NOTE: PERFORMANCE: We don't use `Debug.printChange()` or other calls because we already checked for changes.
			Debug.printDebug(str(previousValue, " → ", value, " (%+d" % previousChange, ")"), str(self.get_script().get_global_name(), " ", self, " ", name))

		# Signals
		# TBD: CHECK: PERFORMANCE: Are signals expensive for frequently updated stats?

		if not shouldSkipEmittingNextChange:  emit_changed()
		else:  shouldSkipEmittingNextChange = false

		# NOTE: Don't use `elif` because more than one signal may be emitted during a single change, if min/max/0 are equal.

		if previousChange > 0: # Were we rising?
			if value >= max: didMax.emit()
			if value >= 0:	 didZero.emit()

		if previousChange < 0: # Were we falling?
			if value <= min: didMin.emit()
			if value <= 0:	 didZero.emit()

		valueWithModifiers = value # TBD: Should this be here?
		GameState.statUpdated.emit(self) # TBD: Should this be optional?

	else: previousChange = 0 # IMPORTANT: If the value did not change due to clamping etc., reset previousChange so TextBubble etc. can properly show the actual difference!

#endregion


#region Derived Properties

var previousValue:  int
var previousChange: int ## [member value] - [member previousValue] so a decrease is a negative number.

## A property used by subclasses such as [StatWithModifiers] to denote dynamic buffs/debuffs during gameplay.
## @experimental
var valueWithModifiers: int

var percentage: float: ## The current [member value] as a percentage of the [member max] limit.
	get: return float(value) / float(max) * 100.0

var logName: String:
	get: return str(self.get_script().get_global_name(), " ", self, " ", self.name, ": ", value, " (", min, "-", max, ")")

#endregion



#region Signals

# NOTE: More than one signal may be emitted during a single change, if [member min] & [member max] are equal, or also equal to 0.

signal didMax  ## Only emitted when [member previousChange] is >= +1
signal didMin  ## Only emitted when [member previousChange] is <= -1
signal didZero ## Emitted whether the value is rising or falling. See [member previousChange] to check the direction of approach to 0.
#endregion


## Applies the [param difference] to [member value] and returns the value.
func change(difference: int) -> int:
	self.value += difference
	return self.value


## Returns a COPY of the Stat's [member value] + the [param difference] after clamping it between [member min] and [member max].
## NOTE: Does NOT modify the [member value].
## TIP: May be used to test for a clamped result before altering the value.
func testChange(difference: int) -> int:
	return clampi(self.value + difference, self.min, self.max)


func setToMax() -> void:
	self.value = self.max


## This method should be used instead of setting [member value] to 0 directly.
func setToMin() -> void:
	self.value = self.min
