## An [Upgrade] represents a special collectible that grants a permanent or once-only effect, ability or item to a character,
## such as a player purchasing a new gun, or a monster getting a speed boost on a higher difficulty level.
## Upgrades may be upgraded multiple times and have costs associated with each enhancement,
## such as a gun getting a faster rate-of-fire, or a monster getting a strength buff after a certain time has elapsed.
## Upgrades may be acquired from in-game-world shops or even via in-app purchases,
## and the shop may inspect an [Entity]'s [UpgradesComponent] to keep track of which upgrades have already been purchased and not be offered again.
## NOTE: Even though this class is named "upgrade" it may also be used for downgrades/debuffs.

class_name Upgrade
extends Resource

# TODO: Create a base superclass for general purchasable items.
# TBD:  Create an emtpy subclass called "Downgrade" for naming consistency? :P
# TBD:  Should `acquire` be renamed `install`?


#region Parameters

## NOTE: This name MUST BE UNIQUE across all Upgrades, because [UpgradesComponent] and other classes search Upgrades by their names.
@export var name: StringName:
	set(newValue):
		if newValue.is_empty():
			Debug.printWarning("Rejected attempt to set name to empty string")
			return
		name = newValue
		self.resource_name = name # CHECK: Does this work without @tool?

## An optional different name for displaying in the HUD and other UI. If empty, returns [member name] capitalized.
@export var displayName: String:
	get:
		if not displayName.is_empty(): return displayName
		else: return self.name.capitalize()

## The core functionality of this Upgrade. A [Script] to execute when this Upgrade is "installed" or "uninstalled" on an [Entity]'s [UpgradesComponent].
## IMPORTANT: The script MUST have functions matching these signatures; the same interface as [UpgradePayload]:
## `static func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool`
## `static func onUpgrade_willDiscard(upgrade: Upgrade, entity: Entity) -> bool`
## TIP: Use the `Templates/Scripts/Resource/UpgradePayloadTemplate.gd` template.
## If not specified, a `.gd` script file matching the same name as the Upgrade `.tres` is used, if found, e.g. `GunUpgrade.tres`: `GunUpgrade.gd`
@export var payload: GDScript: # TODO: Stronger typing when Godot allows it :')
	get:
		if not payload:
			payload = load(Tools.getPathWithDifferentExtension(self.resource_path, ".gd"))
		return payload

const payloadAcquireMethodName: StringName = &"onUpgrade_didAcquireOrLevelUp" ## The method/function which will be executed from the [member payload] when the Upgrade is "installed" or leveled up.
const payloadDiscardMethodName: StringName = &"onUpgrade_willDiscard" ## The method/function which will be executed from the [member payload] when the Upgrade is "uninstalled".

@export var description: String ## An optional explanation, for internal development notes or to show the player.
@export var shouldShowDebugInfo: bool = false


@export_group("Level")

## The upgrade level of this Upgrade. Some upgrades may be upgraded multiple times to make them more powerful.
## If this value is set higher than [member maxLevel] and [member shouldAllowInfiniteLevels] is false, then it is reset to [member maxLevel].
@export_range(0, 100, 1, "or_greater") var level: int:
	set(newValue):
		if newValue == level: return

		# Keep the level at or under maxLevel.
		if not shouldAllowInfiniteLevels and maxLevel >= 0 and newValue > maxLevel:
			newValue = maxLevel # TBD: Should we reject the attempt to set a higher value?

		var previousValue: int = level
		level = newValue # Set the value first before emitting signals in case the handlers need to check it.

		if level > previousValue:
			didLevelUp.emit()
			if not shouldAllowInfiniteLevels and level >= maxLevel: didMaxLevel.emit()
		elif level < previousValue:
			didLevelDown.emit()

## The maximum number of times this Upgrade may be upgraded. Ignored if [member shouldAllowInfiniteLevels] is true.
## A value of <= -1 is invalid.
@export_range(0, 100, 1, "or_greater") var maxLevel: int:
	set(newValue):
		maxLevel = newValue
		if not shouldAllowInfiniteLevels and maxLevel >= 0 and level > maxLevel:
			Debug.printDebug(str("Decreasing higher level ", level, " to new maxLevel ", maxLevel))
			level = maxLevel

## If `true` then [member maxLevel] is ignored and [member level] has no limit.
@export var shouldAllowInfiniteLevels: bool = false


@export_group("Costs")

## The [Stat] required to "pay" for the Upgrade, such as spending Money at a shop or Energy at a machine.
## If no Stat is specified, then the Upgrade is always free.
## NOTE: If a Stat is specified but not present in an Entity's [StatsComponent], the Upgrade CANNOT be purchased EVEN IF the cost is <= 0.
## This acts as a further layer of validation: The Entity must have the Stat type in its StatsComponent, i.e. be able to HOLD a resource such as gold etc., but it may be 0.
## NOTE: This actual [Stat] is never used for comparison when searching in a [StatsComponent], ONLY THE NAME.
## Searching by the name allows any Entity, even monsters etc. to use Upgrades, by having different instances of the same Stat resource.
## DESIGN: This parameter accepts a [Stat] to eliminate bugs from typing incorrect names, and to be able to use the [member Stat.displayName].
@export var costStat: Stat

## This is the property that is ACTUALLY used to search for the required Stat, so that ANY instance of a particular Stat resource may be usable.
var costStatName: StringName:
	get: return self.costStat.name if self.costStat else &""

## A list of costs for each [member level] of this upgrade. The first cost at array index 0 is the requirement for initially acquiring this upgrade.
## `cost[n]` == Level n+1 so `cost[1]` == Upgrade Level 2.
## If a cost is <= 0, or missing and [member shouldUseLastCostForHigherLevels] is false, then the level is free.
## If the array is empty, then the Upgrade is always free.
## TIP: Use [member shouldUseLastCostForHigherLevels] to specify only 1 or a few costs and use the last cost for all subsequent levels.
@export_range(0, 1000, 1, "or_greater") var costs: Array[int]

## If `true`, then the highest index of the [member costs] array is used for all subsequent higher levels.
## This lets you write only 1 or a few costs even if the number of allowed upgrade levels is higher.
@export var shouldUseLastCostForHigherLevels: bool = false


@export_group("Requirements")

## An optional list of other upgrades which are needed before this upgrade may be used.
## This array is checked in order.
@export var requiredUpgrades: Array[Upgrade]

## An optional list of upgrades which prevent this upgrade from being acquired or used.
## For example, if the player has a fire-based weapon, they may not equip a water-based weapon.
## This array is checked in order.
## NOTE: This is an Array of [StringName] instead of [Upgrade], because 2 Upgrades referring to each other would cause a cyclic dependency, preventing Godot from loading them. :')
@export var mutuallyExclusiveUpgrades: Array[StringName]

## An optional list of [Component]s that this Upgrade requires or modifies, such as a [GunComponent].
## This array is checked in order.
# TODO: @export var requiredComponents: Array[Component] # GODOT LIMITATION: "Node export is only supported in Node-derived classes, but the current class inherits 'Resource'." :(

#endregion


#region State
var logName: String:
	get: return str(self, " ", self.name, " L", self.level)

## Returns `true` if [member shouldAllowInfiniteLevels] is false and [member level] == [member maxLevel]
var isMaxLevel: bool:
	get: return not shouldAllowInfiniteLevels and level >= maxLevel
#endregion


#region Signals
# DESIGN: Acquire/Discard signals should be emitted by the UpgradesCOMPONENT first, THEN by the Upgrade,
# because any handlers connected to the Upgrade will expect the Upgrade to be or not be in a component when they receive the Upgrade's signals.

@warning_ignore("unused_signal")
signal didAcquire(entity: Entity) ## NOTE: [signal Upgrade.didAcquire] is emitted AFTER [signal UpgradesComponent.didAcquire].
signal didDiscard(entity: Entity) ## NOTE: [signal Upgrade.didDiscard] is emitted AFTER [signal UpgradesComponent.didDiscard].

signal didLevelUp
signal didLevelDown
signal didMaxLevel
#endregion


#region Gameplay Functionality

## Allows or declines this Upgrade to be installed in an [Entity]'s [UpgradesComponent] after deducting the required [method getCost] from the required [Stat].
## NOTE: The Stat to pay with must be chosen by the Entity (i.e. the UpgradesComponent), in case the entity have multiple Stats of the same type to choose from.
## May be overridden in a subclass to check additional game-specific conditions.
func requestToAcquire(entity: Entity, paymentStat: Stat) -> bool:
	printLog(str("requestToAcquire() entity: ", entity, ", paymentStat: ", paymentStat))

	# Validate
	if not validateEntityEligibility: return false

	# Pay up!
	if not deductPayment(paymentStat, self.level): return false

	# Install.exe
	# DESIGN: The Upgrade's signal should be emitted AFTER the component's signal,
	# because any handlers connected to the Upgrade will except the Upgrade to be already installed in a component when they receive the acquire signal.
	# Even though a class not emitting its own signals is unreliable design :')
	# Handled by [UpgradesComponent]: self.didAcquire.emit(entity)
	# TBD: Should we use `await` on the component to be able to emit our signal by ourselves?
	return true


## Allows or declines this Upgrade's [member level] to be incremented after deducting the required [method getCost] from the required [Stat].
## May be overridden in a subclass to check additional game-specific conditions.
func requestLevelUp(entity: Entity, paymentStat: Stat) -> bool:
	# DESIGN: The Stat to pay with should be chosen from the Entity's side (i.e. the UpgradesComponent),
	# in case they have multiple Stats of the same type to choose from.

	printLog(str("requestLevelUp() entity: ", entity, ", paymentStat: ", paymentStat))

	# First, verify that we HAVE a next level to level up to.
	if not self.shouldAllowInfiniteLevels and self.level >= self.maxLevel:
		printLog(str("Already at maxLevel ", maxLevel))
		return false

	# Next, pay up before level up!
	if not deductPayment(paymentStat, self.level + 1): return false

	# Finally, level up!
	self.level += 1
	return true


## Deducts a level's cost from the [member Stat.value] of the [Stat] used to pay for this Upgrade.
func deductPayment(offeredStat: Stat, levelToPurchase: int) -> bool:
	printLog(str("deductPayment() offeredStat: ", offeredStat))

	# NOTE: DESIGN: Check the NAME instead of the Stat itself, so that any Entity, even monsters etc. may be able to use Upgrades by using different instances of a Stat resource.
	# NOTE: DESIGN: Check for the presence of the Stat EVEN IF the cost is FREE; this acts as a further layer of validation: The Entity must have the Stat type in its StatsComponent, i.e. be able to HOLD a resource such as gold etc., but it may be 0.

	# If the Upgrade does not need any Stat, the Upgrade is always free.
	if self.costStat == null: return true

	# If the Upgrade requires a Stat, make sure the offered Stat is an instance of the type we want.
	if not offeredStat.name == self.costStat.name:
		printLog(str("offeredStat.name: ", offeredStat, " != self.costStat.name: ", self.costStat.name))
		return false

	# Check our cost. If it's <= 0, the purchase is free!
	var cost: int = self.getCost(levelToPurchase)
	if cost <= 0: return true

	# Does the Stat have enough?
	var offeredValue: int = offeredStat.value # Cache

	if not offeredValue >= cost:
		printLog(str("offeredStat.value: ", offeredValue, " < self.getCost(): ", cost))
		return false

	# Kaching!
	offeredStat.value -= cost
	printLog(str("Paid offeredStat.value: ", offeredValue, " - ", cost))
	return true


## Performs the actual actions or purpose of the Upgrade. Calls the static method [member payloadAcquireMethodName] from the [member payload] Script: `onUpgrade_didAcquireOrLevelUp()`
## Override in subclass to perform any modifications to the entity or other components when gaining (or losing) a [member level].
## Level 0 is when the Upgrade is first acquired by an entity.
func processPayload(entity: Entity) -> bool:
	printLog(str("processPayload() entity: ", entity, ", payload: ", self.payload))
	if self.payload:
		return self.payload.call(self.payloadAcquireMethodName, self, entity)
	else:
		return false


## Override in subclass to perform any per-frame modifications to the entity or other components.
func _process(_delta: float) -> void:
	pass


## Calls the static method [member payloadDiscardMethodName] from the [member payload] Script: `onUpgrade_willDiscard()`
func discard(entity: Entity) -> bool:
	var payloadResult: bool

	if self.payload:
		payloadResult = self.payload.call(self.payloadDiscardMethodName, self, entity)

	self.didDiscard.emit(entity)
	return payloadResult

#endregion


#region Management

## Returns the next level after clamping it to the [member maxLevel] if not [member shouldAllowInfiniteLevels].
## If there is no next level possible, then the current [member level] is returned.
func getNextLevel() -> int:
	# TBD: Should we return an invalid number if there is no next level?
	if self.shouldAllowInfiniteLevels or self.level < maxLevel:
		return self.level + 1
	else:
		return level


## Returns the cost for the specified level or the current level.
## Returns 0 if no cost has been specified for the respective level and [member shouldUseLastCostForHigherLevels] is `false`.
func getCost(levelOverride: int = self.level) -> int:
	# If the level number a valid index within the costs array, get the cost associated with the level.
	if levelOverride < costs.size(): # Array size will be 1 less than the last valid index.
		return costs[levelOverride]

	# If the level is higher than the array size and shouldUseLastCostForHigherLevels, return the highest index if the array is not empty.
	elif shouldUseLastCostForHigherLevels and not costs.is_empty() and levelOverride >= costs.size(): # Checks are in order of speed
		return costs.back()

	else:
		return 0 # TBD: Return 0 on a missing cost or <= -1?


## Returns the cost for the next level. If there is no next level, 0 is returned.
func getNextCost() -> int:
	return self.getCost(self.level + 1)


## Returns the cost for acquiring or upgrading this Upgrade for a particular [UpgradesComponent].
## If the component does NOT have this Upgrade, then the CURRENT level's cost is returned.
## If the component already has this Upgrade, then the NEXT level's cost is returned.
## If there is no cost for the respective level, 0 is returned.
func getCostForUpgradesComponent(upgradesComponent: UpgradesComponent) -> int:
	# Is this upgrade already installed in that component?
	if upgradesComponent.getUpgrade(self.name): # TBD: Match just the name or check for the exact same resource instance?
		return getNextCost()
	else:
		return getCost()

#endregion



#region Validation

## Checks if the specific entity meets all the requirements and costs to acquire this Upgrade.
func validateEntityEligibility(entity: Entity) -> bool:
	printLog(str("validateEntityEligibility() ", entity.logFullName))
	var statsComponent:	   StatsComponent    = entity.getComponent(StatsComponent)
	var upgradesComponent: UpgradesComponent = entity.getComponent(UpgradesComponent)
	return validateStatsComponent(statsComponent) and validateUpgradesComponent(upgradesComponent)


## Checks whether the specified [StatsComponent] can meet the cost for this Upgrade's specified level.
func validateStatsComponent(statsComponent: StatsComponent, levelOverride: int = self.level) -> bool:
	# If there is no cost for the specified level, then the component can afford it, of course.
	var cost: int = self.getCost(levelOverride)
	if cost <= 0: return true

	# Does the component have our required Stat type?
	var paymentStatInComponent: Stat = self.findCostStatInStatsComponent(statsComponent)
	if not paymentStatInComponent: return false

	# Is the stat's value >= our cost?
	return paymentStatInComponent.value >= cost


func findCostStatInStatsComponent(statsComponent: StatsComponent) -> Stat:
	# TBD: Match the name only or check for the exact same resource instance?
	return statsComponent.getStat(self.costStat.name) if self.costStat else null


## Checks whether the provided [UpgradesComponent] has all the [requiredUpgrades] for THIS Upgrade, and none of this Upgrade's [mutuallyExclusiveUpgrades].
func validateUpgradesComponent(upgradesComponent: UpgradesComponent) -> bool:
	# If we have no requirements or antirequirements, this Upgrade is good to go.
	if self.findMissingRequirement(upgradesComponent) == null \
	and self.findMutuallyExclusiveConflict(upgradesComponent) == null:
		return true
	else:
		return false


## Checks whether the provided [UpgradesComponent] has all the [requiredUpgrades] for THIS Upgrade.
## Returns: The first MISSING required Upgrade. If `null` is returned, then there are no missing requirements.
func findMissingRequirement(upgradesComponent: UpgradesComponent) -> Upgrade:
	if self.requiredUpgrades.is_empty(): return null

	for requirement in self.requiredUpgrades:
		# Is there any missing requirement?
		if not upgradesComponent.getUpgrade(requirement.name):
			printLog(str("Missing requirement ", requirement, " in ", upgradesComponent))
			return requirement

	return null


## Checks whether the provided [UpgradesComponent] has any of the [mutuallyExclusiveUpgrades] which conflict with THIS Upgrade.
## Returns: The first MATCHING mutually-exclusive Upgrade. If `null` is returned, then there are no conflicting Upgrades.
func findMutuallyExclusiveConflict(upgradesComponent: UpgradesComponent) -> Upgrade:
	if self.mutuallyExclusiveUpgrades.is_empty(): return null

	for conflicName in self.mutuallyExclusiveUpgrades:
		# Is there any conflicting Upgrade?
		var conflict: Upgrade = upgradesComponent.getUpgrade(conflicName)
		if conflict:
			printLog(str("Mutually-exclusive upgrade ", conflict.logName, " in ", upgradesComponent))
			return conflict

	return null


## Checks if the [member payload] script contains a function matching the required signature as [member payloadMethodName].
func validatePayloadSignature() -> bool:
	return Tools.findMethodInScript(self.payload, self.payloadAcquireMethodName) and Tools.findMethodInScript(self.payload, self.payloadAcquireMethodName)

#endregion


func printLog(message: String) -> void:
	if shouldShowDebugInfo: Debug.printLog(message, str(self.logName))
