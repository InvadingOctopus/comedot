## Stores an array of [Stat]s such as health and ammo for an [Entity].
## TIP: Use the `Scripts/UI/[StatsUI].gd` script to automatically display and update these values in a HUD during runtime.

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
	# CHECK: Should the dictionary be cleared before re-caching?
	for stat in self.stats:
		statsDictionary[stat.name] = stat
	return statsDictionary.size()


func resetStats() -> void:
	for stat in stats:
		stat = stat.duplicate() # TBD: CHECK: Is there a better way?


#region Interface

## Searches the [member statsDictionary] for the [param name] key. If no matching [Stat] is found, calls [method findStat].
func getStat(statName: StringName) -> Stat:
	var stat: Stat = statsDictionary.get(statName)
	if not stat: stat = findStat(statName)
	return stat


## Returns the specified [Stat] if it has been added to this [StatsComponent] and its [member Stat.value] is >= the specified [param requiredValue].
func getStatIfHasValue(statName: StringName, requiredValue: int) -> Stat:
	var stat: Stat = self.getStat(statName)
	if stat and stat.value >= requiredValue: return stat
	else: return null


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


## Returns `true` if this [StatsComponent] has the specified [Stat] and the [member Stat.value] is >= the specified [param amount].
func canSpend(statName: StringName, amount: int) -> bool:
	var stat: Stat = self.getStat(statName)
	return stat and stat.value >= amount # TBD: Check for `stat.min`?


## Deducts the specified amount from the specified Stat, if available.
## Returns `true` if successful.
## NOTE: If [param amount] is negative, then the Stat's value is INCREASED.
func spend(statName: StringName, amount: int) -> bool:
	var stat: Stat = self.getStatIfHasValue(statName, amount)
	if stat:
		stat.value -= amount # Let a positive amount be a dedution, because the verb is "spend" not "change".
		return true
	else:
		return false

#endregion


#region Convenience Functions

## Returns the value of the matching [Stat] found in [member stats], otherwise a `0` if no match is found.
## Queries the [member statsDictionary] first or calls [method findStat].
func getStatValue(statName: StringName) -> int:
	var stat: Stat = self.getStat(statName)
	if stat: return stat.value
	else: return 0


## Applies the [param difference] to the specified Stat's [member value].
## TIP: May be used as a shortcut for changing Stats by signals from UI buttons etc. without writing a separate script.
func changeStatValue(statName: StringName, difference: int) -> void:
	var stat: Stat = self.getStat(statName)
	if stat: stat.value += difference


## TIP: May be used as a shortcut for changing Stats by signals from UI buttons etc. without writing a separate script.
func setStatToMax(statName: StringName) -> void:
	var stat: Stat = self.getStat(statName)
	if stat: stat.value = stat.max


## TIP: May be used as a shortcut for changing Stats by signals from UI buttons etc. without writing a separate script.
func setStatToMin(statName: StringName) -> void:
	var stat: Stat = self.getStat(statName)
	if stat: stat.value = stat.min

#endregion

