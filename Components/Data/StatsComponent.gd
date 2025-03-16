## Stores an array of [Stat]s such as health and ammo for an [Entity].
## Stats can be accessed via `statsComponent.statsDictionary.health.value` or a name-independent UID such as `statsComponent.statsUIDDictionary.bah69kvu0xeae.value`.
## To avoid runtime crashes in case of missing Stats, use the [method getStat], [method getStatByUID] or [method findStat] methods.
## TIP: Use the `UI/Lists/[StatsList].gd` script to automatically display and update these values in a HUD during runtime.

class_name StatsComponent
extends Component


#region Parameters
@export var stats: Array[Stat]:
	set(newValue):
		if newValue != stats:
			stats = newValue
			cacheStats()

## May be used for automatically resetting stats in situations like restarting the game etc.
@export var shouldResetResourcesOnReady: bool = false
#endregion


#region State
## Caches Stats by their [StringName] [member Stat.name] keys. Access via `statsDictionary.health.value` or [method getStat] to avoid crashes if the Stat is missing.
var statsDictionary:	Dictionary[StringName, Stat] = {}
## Caches Stats by their [ResourceUID] ID for name-independent access via their UIDs like "uid://bah69kvu0xeae". Access via `statsUIDDictionary.health.value` or [method getStatByUID] to avoid crashes if the Stat is missing.
## NOTE: The "uid://" prefix is stripped so that the Dictionary may be accessed via dot notation.
var statsUIDDictionary:	Dictionary[StringName, Stat] = {}
#endregion


func _ready() -> void:
	if shouldResetResourcesOnReady: resetStats()
	if not self.stats.is_empty():   cacheStats()


## Saves each [Stat] in the [member stats] array to the [member statsDictionary] with the [member Stat.name] as its key, for quicker access.
## TIP: Use [method getStat] to quickly access cached stats.
## WARNING: May override previously cached stats.
## Returns: The number of stats saved in the dictionary.
func cacheStats() -> int:
	if debugMode: printDebug(str("cacheStats() ", stats))
	
	# Clear the dictionaries before re-caching, to remove Stats that are no longer present.
	self.statsDictionary.clear()
	self.statsUIDDictionary.clear()

	for stat in self.stats:
		statsDictionary[stat.name] = stat
		# Also store the UID for name-independent access.
		# NOTE: Trim "uid://" prefix for brevity and to access the Dictionary via dot notation.
		if stat.uid != -1 or stat.uid != 0: statsUIDDictionary[stat.uidString.trim_prefix("uid://")] = stat # Because 0 and -1 are invalid UIDs.
		if debugMode: printDebug(str(stat.name, " ", stat.uidString.trim_prefix("uid://")))
	return statsDictionary.size()


## Resets all Stats to their default values.
func resetStats() -> void:
	for stat in stats:
		stat = stat.duplicate() # TBD: CHECK: Is there a better way?


#region Interface

## Searches the [member statsDictionary] for the [param name] key. If no matching [Stat] is found, calls [method findStat].
func getStat(statName: StringName) -> Stat:
	var stat: Stat = statsDictionary.get(statName)
	if not stat: stat = findStat(statName)
	return stat


## Accesses Stats from [member statsUIDDictionary] by a name-independent [ResourceUID] string such as "uid://bah69kvu0xeae".
## Helpful for referencing Stats via an ID which does not change even after the [member Stat.name] or filename changes.
## NOTE: The "uid://" prefix is stripped.
## NOTE: Does NOT scan the whole [member stats] array for matching UIDs.
func getStatByUID(uidPath: StringName) -> Stat:
	uidPath = uidPath.to_lower().trim_prefix("uid://")
	var stat: Stat = statsUIDDictionary.get(uidPath)
	if not stat: printWarning("getStatByUID() Cannot find Stat with UID " + uidPath)
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

