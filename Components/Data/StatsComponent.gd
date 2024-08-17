## Stores an array of [Stat]s such as health and ammo for an [Entity].
## TIP: Use the `Scripts/UI/StatsUI.gd` script to automatically display and update these values in a HUD during runtime.
class_name StatsComponent
extends Component


#region Parameters
@export var statNames: Array[StringName] # TBD: What is this used for? lol
@export var stats: Array[Stat]

## May be used for automatically resetting stats in situations like restarting the game etc.
@export var shouldResetResourcesOnReady: bool = false
#endregion


func _ready() -> void:
	if shouldResetResourcesOnReady: resetStats()


func resetStats() -> void:
	for stat in stats:
		stat = stat.duplicate() # TBD: Is there a better way?


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
