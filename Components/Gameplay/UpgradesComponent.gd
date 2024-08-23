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
signal didAcquire(upgrade: Upgrade) ## NOTE: [signal Upgrade.didAcquire] is emitted before [signal UpgradesComponent.didAcquire].
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


func addUpgrade(newUpgrade: Upgrade, overwrite: bool = false) -> bool:
	# TODO: Review the order of the tasks executed here, and which class should execute the installation etc? The [Upgrade] or the [UpgradesComponent]?

	printDebug(str("addUpgrade() ", newUpgrade.logName))

	# Do we already have the upgrade?
	
	var conflictingUpgrade: Upgrade = self.getUpgrade(newUpgrade.name)
	
	if conflictingUpgrade:
		printDebug("Upgrade name already in dictionary")
		
		# Is it the same upgrade?
		if conflictingUpgrade == newUpgrade:
			printDebug("Upgrade already in component")
			return true
		elif not overwrite:
			printDebug("Not overwriting Upgrade already in component with same name: " + str(conflictingUpgrade))
			return false
	
	# If the Upgrade is not already installed in this component or `overwrite` is `true`, add it!

	if newUpgrade.acquire(self.parentEntity):
		self.upgrades.append(newUpgrade)
		self.upgradesDictionary[newUpgrade.name] = newUpgrade
		self.didAcquire.emit(newUpgrade)
		printDebug("Upgrade added")

	return true


## If the specified [Upgrade] is not already "installed" in this [UpgradesComponent], it will be added.
## If the Upgrade is already in this component, its level will be incremented by 1.
## Returns: The new level of the Upgrade. If 0 then this Upgrade was not in this component before.
func addOrLevelUpUpgrade(newUpgrade: Upgrade) -> int:
	if self.getUpgrade(newUpgrade.name):
		printDebug(str("addOrLevelUpUpgrade() ", newUpgrade, " already installed."))
		if newUpgrade.level < newUpgrade.maxLevel: newUpgrade.level += 1
	else:
		printDebug(str("addOrLevelUpUpgrade() Installing ", newUpgrade))
		self.addUpgrade(newUpgrade)

	return newUpgrade.level
