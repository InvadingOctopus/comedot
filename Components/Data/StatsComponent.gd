## Stores an array of [Stat]s such as health and ammo for an [Entity].
class_name StatsComponent
extends Component


@export var statNames: Array[StringName]
@export var stats: Array[Stat]


## Returns the first matching [Stat] found in [member stats].
func findStat(nameToSearch: StringName) -> Stat:

	if stats.size() <= 0: return null

	for stat: Stat in stats:
		if stat.name == nameToSearch: return stat
	# else:
	printWarning("Cannot find Stat: " + nameToSearch)
	return null


## Returns the value of the matching [Stat] found in [member stats], otherwise a `0` if no match is found.
func getStatValue(statName: StringName) -> int:
	var stat: Stat = self.findStat(statName)
	if not stat: return 0
	else: return stat.value
