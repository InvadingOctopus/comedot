## A shared [Resource] for game-specific global data that may be accessed and modified by any [Entity], [Component], node and script.
## EXAMPLE: `globalData.difficultyScale = 42` or `GameState.globalData[&"questItems"]`

class_name GlobalData
extends Resource


#region Constants
## The prefix Godot uses when serializing [Object] metadata as properties.
const metadataPropertyPrefix: StringName = &"metadata/"
#endregion


#region Parameters
## The actual [Dictionary] containing the [StringName] keys and associated [Variant] values.
## ALERT: Advanced scripts may modify this [Dictionary] directly, but manual changes will NOT emit signals such as [signal GlobalData.didChangeValue] or [signal Resource.changed] etc.
## TIP: When accessing a key for the first time, use [method Dictionary.get_or_add] with a default value.
## EXAMPLE: `dictionary.get_or_add(&"questItems", [])`
## IMPORTANT: Avoid using keys beginning with `metadata/` as such properties may be reserved for Godot's internal usage.
@export var dictionary:	Dictionary[StringName, Variant]
#endregion


#region Signals

## Emitted after a value is added or changed via [method setValue]
## NOTE: [param previousValue] is `null` when a new key is added, which may be indistinguishable from replacing an existing `null` value.
## ALERT: Manually modifying [member dictionary] does NOT emit these signals.
signal didChangeValue(key:	StringName, previousValue: Variant, newValue: Variant)

## Emitted after a value is erased via [method eraseValue]
## ALERT: Manually modifying [member dictionary] does NOT emit these signals.
signal didEraseValue(key:	StringName, previousValue: Variant)

#endregion


#region Dynamic Property Interface

# Godot passes serialized Resource metadata through these dynamic property methods as `metadata/<name>`.
# Preserve it as Object metadata instead of treating it as game-specific global data.

## Supports convenient shortcut access to [member dictionary]'s values via this [Resource] object itself, without needing to write `dictionary`
## such as `globalData[&"enemySpeed"]` or `globalData.enemySpeed`
## IMPORTANT: [param propertyName] beginning with `metadata/` is reserved for Godot's internal usage.
func _get(propertyName: StringName) -> Variant:
	# Don't trap [Resource] metadata such as `metadata/_custom_type_script` etc.
	if propertyName.begins_with(metadataPropertyPrefix):
		return get_meta(propertyName.trim_prefix(metadataPropertyPrefix))
	else:
		return dictionary.get(propertyName)


## Supports convenient shortcut access for modifying [member dictionary]'s values via this [Resource] object itself, without needing to write `dictionary`
## while ensuring that [signal didChangeValue] is emitted.
## such as `globalData[&"enemySpeed"] = 69` or `globalData.enemySpeed = 69`
## IMPORTANT: [param propertyName] beginning with `metadata/` is reserved for Godot's internal usage.
func _set(propertyName: StringName, newValue: Variant) -> bool:
	# Don't trap [Resource] metadata such as `metadata/_custom_type_script` etc.
	if propertyName.begins_with(metadataPropertyPrefix):
		set_meta(propertyName.trim_prefix(metadataPropertyPrefix), newValue)
		return true
	else:
		setValue(propertyName, newValue)
		return true


# TBD: Expose each entry in [member dictionary] as an Inspector-only property?
# func _get_property_list() -> Array[Dictionary]:
# 	var propertyDictionaries:Array[Dictionary]
# 	var propertyDictionary:  Dictionary[String, Variant]
#
# 	for propertyName: StringName in self.dictionary:
# 		propertyDictionary["name"]  = propertyName
# 		propertyDictionary["type"]  = typeof(dictionary[propertyName])
# 		propertyDictionary["usage"] = PROPERTY_USAGE_EDITOR
# 		if dictionary[propertyName] == null:
# 			propertyDictionary["usage"] |= PROPERTY_USAGE_NIL_IS_VARIANT
# 		propertyDictionaries.append(propertyDictionary)
#
# 	return propertyDictionaries

#endregion


#region Value Interface
# Signal-emitting wrappers for basic operations on [member dictionary]
# Scripts may access [member dictionary] directly for other [Dictionary] features that skip signals.

## Returns the value associated with [param key] or [param defaultValue] if the key is missing.
## This method supports specifying a fallback value unlike [method Object.get]
func getValue(key: StringName, defaultValue: Variant = null) -> Variant:
	return dictionary.get(key, defaultValue)


## Adds or changes a value and emits [signal Resource.changed] then [signal didChangeValue]
## Returns `true` if the stored value was changed or already present.
func setValue(key: StringName, newValue: Variant) -> bool:
	var previousValue: Variant = dictionary.get(key)

	# See if we already have the same value of the same type for the same key
	# to avoid emitting signals
	if dictionary.has(key) \
	and typeof(newValue) == typeof(previousValue):

		if  newValue is float and previousValue is float \
		and is_equal_approx(newValue, previousValue):
			return true
		elif newValue == previousValue:
			return true

	# Update & Emit
	dictionary[key] = newValue

	# TBD: Emit `changed` first or `didChangeValue`?
	emit_changed()
	didChangeValue.emit(key, previousValue, newValue)
	return true


## Erases [param key] and emits [signal Resource.changed] then [signal didEraseValue]
## Returns `true` if the value was found & erased.
func eraseValue(key: StringName) -> bool:
	# TBD: Should we not return any value? Because a missing key is already removed :)
	if not dictionary.has(key): return false

	var previousValue: Variant = dictionary[key]
	dictionary.erase(key)

	# TBD: Emit `changed` first or `didEraseValue`?
	emit_changed()
	didEraseValue.emit(key, previousValue)
	return true

#endregion
