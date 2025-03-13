## Keeps track of which [Upgrade]s an [Entity] has.
## TIP: To offer the player a UI to choose Upgrades from, see [UpgradeChoiceUI] and [UpgradeChoiceList].

class_name UpgradesComponent
extends Component

# NOTE: Too much code duplication from StatsComponent :(


#region Parameters
@export var upgrades: Array[Upgrade]

## May be used for automatically resetting upgrades in situations like restarting the game etc.
@export var shouldResetResourcesOnReady: bool = false
#endregion


#region State
var upgradesDictionary: Dictionary[StringName, Upgrade] = {} ## Caches upgrades accessed by [StringName] keys.
#endregion


#region Signals
# DESIGN: Acquire/Discard signals should be emitted by the UpgradesCOMPONENT first, THEN by the Upgrade,
# because any handlers connected to the Upgrade will expect the Upgrade to be or not be in a component when they receive the Upgrade's signals.

signal didAcquire(upgrade: Upgrade) ## NOTE: [signal UpgradesComponent.didAcquire] is emitted BEFORE [signal Upgrade.didAcquire].
signal didDiscard(upgrade: Upgrade) ## NOTE: [signal UpgradesComponent.didDiscard] is emitted BEFORE [signal Upgrade.didDiscard].
#endregion


#region Dependencies
@onready var statsComponent: StatsComponent = coComponents.StatsComponent # TBD: Static or dynamic?

func getRequiredComponents() -> Array[Script]:
	return [StatsComponent]
#endregion


func _ready() -> void:
	if shouldResetResourcesOnReady: resetUpgrades()
	cacheUpgrades()


#region Management

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
## NOTE: This has slower performance than [method getUpgrade] if [param nameToSearch] has already been cached in the [member upgradesDictionary].
func findUpgrade(nameToSearch: StringName) -> Upgrade:
	if upgrades.is_empty(): return null

	for upgrade: Upgrade in upgrades:
		if upgrade.name == nameToSearch: 
			upgradesDictionary[upgrade.name] = upgrade # Cache for quicker future access
			return upgrade
	# else:
	printDebug("Cannot find Upgrade: " + nameToSearch)
	# TODO: Reduce multiple calls to this function from other Upgrade-handling classes when adding a new Upgrade
	return null


## Searches the entity's [StatsComponent] for the [Stat] required to purchase or level-up the specified [Upgrade]
func findPaymentStat(upgradeToBuy: Upgrade) -> Stat:
	if not upgradeToBuy.costStatName.is_empty():
		var statToOffer: Stat = statsComponent.getStat(upgradeToBuy.costStatName)
		return statToOffer
	else:
		return null

#endregion


#region Upgrade Installation

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
	
	# But we gotta pay first!
	var statToOffer: Stat = self.findPaymentStat(newUpgrade)

	if newUpgrade.requestToAcquire(self.parentEntity, statToOffer):
		self.upgrades.append(newUpgrade)
		self.upgradesDictionary[newUpgrade.name] = newUpgrade

		# DESIGN: The Upgrade's signal should be emitted AFTER the component's signal,
		# because any handlers connected to the Upgrade will except the Upgrade to be already installed in a component when they receive the `didAcquire` signal.
		self.didAcquire.emit(newUpgrade)
		newUpgrade.setAcquisition(self.parentEntity) ## Let the Upgrade emit its signal and set its flags etc.
		
		printLog(str("Upgrade added: ", newUpgrade.logName))

		# After the upgrade is installed, perform its ACTUAL JOB!
		newUpgrade.processPayload(self.parentEntity)

	return true


## Attempts to increase the level of the Upgrade after paying the required Stat cost.
func incrementUpgradeLevel(upgrade: Upgrade) -> bool:
	var statToOffer: Stat = self.findPaymentStat(upgrade)
	if upgrade.requestLevelUp(self.parentEntity, statToOffer):
		# After the upgrade is leveled up, perform its ACTUAL JOB at the new level!
		upgrade.processPayload(self.parentEntity)
		return true
	else:
		return false


## If the specified [Upgrade] is not already "installed" in this [UpgradesComponent], it will be added.
## If the Upgrade is already in this component, its level will be incremented by 1.
## Returns: The new level of the Upgrade. If 0 then this Upgrade was not in this component before.
func addOrLevelUpUpgrade(newUpgrade: Upgrade) -> int:
	# Do we already have the upgrade?
	if self.getUpgrade(newUpgrade.name):
		printDebug(str("addOrLevelUpUpgrade() ", newUpgrade, " already installed."))
		self.incrementUpgradeLevel(newUpgrade) # Level up!
	
	# If not, then install it.
	else:
		printDebug(str("addOrLevelUpUpgrade() Installing ", newUpgrade))
		self.addUpgrade(newUpgrade)

	return newUpgrade.level


## Returns `true` if the specified Upgrade was found and discarded.
## NOTE: Requires the [member Upgrade.name] instead of a specific Upgrade instance, so that any matching Upgrade may be found, even if it has a different level etc. in the UpgradesComponent.
func discardUpgrade(nameToDiscard: StringName) -> bool:
	
	var upgradeToDiscard: Upgrade = self.getUpgrade(nameToDiscard)
	if not upgradeToDiscard: return false

	self.upgrades.erase(upgradeToDiscard)
	
	if self.upgradesDictionary.erase(nameToDiscard):
		# DESIGN: The Upgrade's signal should be emitted AFTER the component's signal,
		# because any handlers connected to the Upgrade will except the Upgrade to not be in any component when they receive the discard signal.
		self.didDiscard.emit(upgradeToDiscard)
		upgradeToDiscard.discard(parentEntity) # Let the Upgrade perform its cleanup.
		return true
	else:
		return false

#endregion
