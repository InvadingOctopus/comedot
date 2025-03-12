## A [Payload] that modifies a set of [Stat]s when executed.
## NOTE: The `source` and `target` are ignored/irrelevant; Stats are modified regardless.

class_name StatModifierPayload
extends Payload


#region Parameters
## A [Dictionary] where the keys are [Stat]s and their values are the positive or negative modifiers to add or subtract from each Stat.
@export var statsAndModifiers: Dictionary[Stat, int]
#endregion


## Returns an array of all the [Stat]s that were modified by a non-zero difference.
func executeImplementation(source: Variant, target: Variant) -> Array[Stat]:
	printLog(str("executeImplementation() statsAndModifiers: ", statsAndModifiers, ", source: ", source, ", target: ", target))
	
	if self.statsAndModifiers.is_empty():
		Debug.printWarning("No statsAndModifiers", self.logName)
		return []

	self.willExecute.emit(source, target)
	
	var modifiedStats: Array[Stat]
	for stat in statsAndModifiers:
		if not statsAndModifiers[stat] == 0:
			stat.value += statsAndModifiers[stat]
			modifiedStats.append(stat)

	return modifiedStats
