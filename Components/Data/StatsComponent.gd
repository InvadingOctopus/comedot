## Stores an array of [Stat]s such as health and ammo for an [Entity].
## TIP: Use the `Scripts/UI/StatsUI.gd` script to automatically display and update these values in a HUD during runtime.
class_name StatsComponent
extends Component


#region Parameters
@export var stats: Array[Stat]

## May be used for automatically resetting stats in situations like restarting the game etc.
@export var shouldResetResourcesOnReady: bool = false
#endregion


#region State
var statsDictionary: Dictionary = {} ## Caches stats accessed by [StringName] keys.
#endregion


func _ready() -> void:
	if shouldResetResourcesOnReady: resetStats()
	cacheStats()


## Saves each [Stat] in the [member stats] array to the [member statsDictionary] with the [member Stat.name] as its key, for quicker access.
## TIP: Use [method getStat] to quickly access cached stats.
## WARNING: May override previously cached stats.
## Returns: The number of stats saved in the dictionary.
func cacheStats() -> int:
	for stat in self.stats:
		statsDictionary[stat.name] = stat
	return statsDictionary.size()


func resetStats() -> void:
	for stat in stats:
		stat = stat.duplicate() # TBD: Is there a better way?


## Searches the [member statsDictionary] for the [param name] key. If no matching [Stat] is found, calls [method findStat].
func getStat(statName: StringName) -> Stat:
	var stat: Stat = statsDictionary.get(statName)
	if not stat: stat = findStat(statName)
	return stat


## Returns the first matching [Stat] found in [member stats].
## NOTE: This has a slower performance than [method getStat] if [param nameToSearch] has already been cached in the [member statsDictionary].
func findStat(nameToSearch: StringName) -> Stat:
	if stats.is_empty(): return null

	for stat: Stat in stats:
		if stat.name == nameToSearch: 
			statsDictionary[stat.name] = stat # Cache for quicker future access
			return stat
	# else:
	printWarning("Cannot find Stat: " + nameToSearch)
	return null


## Returns the value of the matching [Stat] found in [member stats], otherwise a `0` if no match is found.
## Queries the [member statsDictionary] first or calls [method findStat].
func getStatValue(statName: StringName) -> int:
	var stat: Stat = self.getStat(statName)
	if not stat: return 0
	else: return stat.value
