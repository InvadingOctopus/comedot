## A variant of [Stat] for stats that may have a stack of positive or negative modifiers added or removed during gameplay i.e. via buffs/debuffs or upgrades, while preserving the "natural" [member value]
## @experimental

@warning_ignore("missing_tool")
class_name StatWithModifiers
extends Stat

# TODO: Support float?
# TODO: A specialized type for Modifiers, to include the source of the buff/debuff + a description.


#region Parameters

## A list of modifiers representing dynamic buffs/debuffs.
## IMPORTANT: ALWAYS use the [method addModifier] and [method removeModifier] methods to ensure that [member valueWithModifiers] is properly recalculated and cached; do NOT modify this array directly!
## @experimental
@export var modifiers: Array[int]:
	set(newValue):
		if newValue != modifiers:
			modifiers = newValue
			shouldRecalculate = true

## Clamps [member valueWithModifiers] between [member min] and [member max] inclusive.
@export var shouldClampModifiedValue: bool = false

#endregion


#region State

## The combined value of all [member modifiers] added/subtracted, i.e. the difference between the [member value] and [member valueWithModifiers].
## Calculated by [method calculateModifiers]
var modifierTotal: int

## Flag used to recalculate modifiers only when needed. If `true` then accessing [member value] calls [method calculateModifiers]
var shouldRecalculate: bool = true

#endregion


func _init() -> void:
	calculateModifiers()


#region Property Getter/Setter


## Sets the [member value] while clamping it between [member min] and [member max]. This method may be overridden in a subclass such as [StatWithModifiers] to provide custom validation or restrictions i.e. via gameplay buffs/debuffs etc.
## @experimental
func setValue(newValue: int) -> void:
	super.setValue(newValue)
	if shouldRecalculate:
		calculateModifiers()
		shouldRecalculate = false
	else:
		updateValueWithModifiers()


#endregion


#region Modifier Management

## Adds a modifier and recalculates the [member valueWithModifiers]
## IMPORTANT: ALWAYS use this method to add modifiers; do NOT modify the [member modifiers] array directly!
## @experimental
func addModifier(modifierToAdd: int) -> int:
	modifiers.append(modifierToAdd)
	calculateModifiers()
	updateValueWithModifiers()
	return valueWithModifiers


## Removes a modifier and recalculates the [member valueWithModifiers]
## IMPORTANT: ALWAYS use this method to remove modifiers; do NOT modify the [member modifiers] array directly!
## @experimental
func removeModifier(modifierToRemove: int) -> int:
	modifiers.erase(modifierToRemove)
	calculateModifiers()
	updateValueWithModifiers()
	return valueWithModifiers


## Recalculates [member valueWithModifiers] and [member modifierTotal], returning the former.
## @experimental
func calculateModifiers() -> int:
	if modifiers.is_empty():
		if debugMode: Debug.printTrace(["No modifiers, valueWithModifiers = value", value, "shouldRecalculate", shouldRecalculate], self)
		valueWithModifiers = value
		modifierTotal = 0
	else:
		if debugMode: Debug.printTrace(["shouldRecalculate", shouldRecalculate, "modifiers", modifiers], self)

		modifierTotal = 0
		for modifier in modifiers:
			modifierTotal += modifier

		updateValueWithModifiers()
		if debugMode: Debug.printDebug(str("value: ", value, ", modifierTotal: ", modifierTotal, ", valueWithModifiers: ", valueWithModifiers), self)

	shouldRecalculate = false
	return valueWithModifiers


## Applies [member modifierTotal] to [member valueWithModifiers] with respect to [member shouldClampModifiedValue]
func updateValueWithModifiers() -> int:
	valueWithModifiers = clampi(value + modifierTotal, min, max) if shouldClampModifiedValue else (value + modifierTotal)
	return valueWithModifiers

#endregion
