## A [Payload] that modifies a set of [Stat]s when executed.
## NOTE: The `source` and `target` are ignored/irrelevant; Stats are modified regardless.
## TIP: Use [method Tools.checkResult] to verify this [Payload]'s success or failure depending on whether any [Stat]s were modified, including skipped [Stat]s because of [member shouldDenyIfStatMax] or 0 modifiers.

class_name StatModifierPayload
extends Payload


#region Parameters
## A [Dictionary] where the keys are [Stat]s and their values are the positive or negative modifiers to add or subtract from each Stat.
@export var statsAndModifiers:   Dictionary[Stat, int]
@export var shouldDenyIfStatMax: bool = true
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
			if statsAndModifiers[stat] >= 1 and shouldDenyIfStatMax and stat.value >= stat.max:
				# TODO: Emit bubbles for max Stats
				continue # Skip if a stat is already maxed
			else:
				stat.value += statsAndModifiers[stat]
				modifiedStats.append(stat)

	return modifiedStats # NOTE: AWESOME: Thanks to being smart in Tools.checkResult() any empty Arrays will be regarded as a failed Payload :)
