## Keeps track of which [Upgrade]s an [Entity] has.

class_name UpgradesComponent
extends Component

# NOTE: Too much code duplication from StatsComponent :(

	
#region Parameters
@export var upgrades: Array[Upgrade]

## May be used for automatically resetting upgrades in situations like restarting the game etc.
@export var shouldResetResourcesOnReady: bool = false
#endregion


#region State
var upgradesDictionary: Dictionary = {} ## Caches upgrades accessed by [StringName] keys.
#endregion


#region Signals
#endregion


#region Dependencies
#endregion


func _ready() -> void:
	if shouldResetResourcesOnReady: resetUpgrades()
	cacheUpgrades()


## Saves each [Upgrade] in the [member upgrades] array to the [member upgradesDictionary] with the [member Upgrade.name] as its key, for quicker access.
## TIP: Use [method getUpgrade] to quickly access cached upgrades.
## WARNING: May override previously cached upgrades.
## Returns: The number of upgrades saved in the dictionary.
func cacheUpgrades() -> int:
	# CHECK: Should the dictionary be cleared before re-caching?
	for upgrade in self.upgrades:
		upgradesDictionary[upgrade.name] = upgrade
	return upgradesDictionary.size()


func resetUpgrades() -> void:
	for upgrade in upgrades:
		upgrade = upgrade.duplicate() # TBD: CHECK: Is there a better way?


## Searches the [member upgradesDictionary] for the [param name] key. If no matching [Upgrade] is found, calls [method findUpgrade].
func getUpgrade(upgradeName: StringName) -> Upgrade:
	var upgrade: Upgrade = upgradesDictionary.get(upgradeName)
	if not upgrade: upgrade = findUpgrade(upgradeName)
	return upgrade


## Returns the first matching [Upgrade] found in [member upgrades].
## NOTE: This has a slower performance than [method getUpgrade] if [param nameToSearch] has already been cached in the [member upgradesDictionary].
func findUpgrade(nameToSearch: StringName) -> Upgrade:
	if upgrades.is_empty(): return null

	for upgrade: Upgrade in upgrades:
		if upgrade.name == nameToSearch: 
			upgradesDictionary[upgrade.name] = upgrade # Cache for quicker future access
			return upgrade
	# else:
	printWarning("Cannot find Upgrade: " + nameToSearch)
	return null