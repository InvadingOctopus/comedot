## An [Upgrade] represents a special collectible that grants a permanent or once-only effect, ability or item to a character,
## such as a player purchasing a new gun, or a monster getting a speed boost on a higher difficulty level.
## Upgrades may be upgraded multiple times and have costs associated with each enhancement,
## such as a gun getting a faster rate-of-fire, or a monster getting a strength buff after a certain time has elapsed.
## Upgrades may be acquired from in-game-world shops or even via in-app purchases,
## and the shop may inspect an [Entity]'s [UpgradesComponent] to keep track of which upgrades have already been purchased and not be offered again.
## NOTE: Even though this class is named "upgrade" it may also be used for downgrades/debuffs.

class_name Upgrade
extends Resource

# TBD: Create an emtpy subclass called "Downgrade" for naming consistency? :P
# TBD: Should `acquire` be renamed `install`?


#region Parameters

## NOTE: This name MUST BE UNIQUE across all Upgrades, because [UpgradesComponent] and other classes search Upgrades by their names.
@export var name: StringName:
	set(newValue):
		if newValue.is_empty():
			Debug.printWarning("Rejected attempt to set name to empty string")
			return
		name = newValue
		self.resource_name = name # CHECK: Does this work without @tool?

## An optional different name for displaying in the HUD and other UI. If empty, returns [member name].
@export var displayName: String:
	get:
		if not displayName.is_empty(): return displayName
		else: return self.name

## A [Script] containing the code to execute when this Upgrade is acquired/"installed" by an [Entity] or leveled up.
## IMPORTANT: The script MUST have a function matching this signature:
## `func onUpgrade_didAcquireOrLevelUp(upgrade: Upgrade, entity: Entity) -> bool`
@export var payload: Script

const payloadMethodName: StringName = &"onUpgrade_didAcquireOrLevelUp" ## The method/function which will be executed from the [member payload].

@export var description: String ## An optional explanation, for internal development notes or to show the player.
@export var shouldShowDebugInfo: bool = false


@export_group("Level")

## The upgrade level of this Upgrade. Some upgrades may be upgraded multiple times to make them more powerful.
## If this value is set higher than [member maxLevel] then it is reset to [member maxLevel].
@export var level: int:
	set(newValue):
		if newValue == level: return

		# Keep the level at or under maxLevel.
		# NOTE: Remember that maxLevel <= -1 means infinite levels.
		if maxLevel >= 0 and newValue > maxLevel: newValue = maxLevel # TBD: Should we reject the attempt to set a higher value?

		var previousValue: int = level
		level = newValue # Set the value first before emitting signals in case the handlers need to check it.

		if level > previousValue:
			didLevelUp.emit()
			if level >= maxLevel: didMaxLevel.emit()
		elif level < previousValue:
			didLevelDown.emit()

## The maximum number of times this Upgrade may be upgraded.
## If maxLevel is -1 or less, then [member level] has no limit.
@export var maxLevel: int:
	set(newValue):
		maxLevel = newValue
		if maxLevel >= 0 and level > maxLevel:
			Debug.printDebug(str("Decreasing higher level ", level, " to new maxLevel ", maxLevel))
			level = maxLevel


@export_group("Costs")

## The [Stat] required to "pay" for the Upgrade, such as spending Money at a shop or Energy at a machine.
## If no stat is specified, then the Upgrade is always free.
## NOTE: The actual [Stat] is never used when searching in a [StatsComponent], ONLY THE NAME.
@export var costStat: Stat # TBD: Should this just be a StringName?

## A list of costs for each [member level] of this upgrade. The first cost at array index 0 is the requirement for initially acquiring this upgrade.
## `cost[n]` == Level n+1 so `cost[1]` == Upgrade Level 2.
## If a cost is <= -1, or missing and not [member shouldUseLastCostForHigherLevels], then the level is free.
## If the array is empty, then the Upgrade is always free.
## TIP: Use [member shouldUseLastCostForHigherLevels] to specify only 1 or a few costs and use the last cost for all subsequent levels.
@export_range(-1, 1000) var costs: Array[int]

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
@export var mutuallyExclusiveUpgrades: Array[Upgrade]

## An optional list of [Component]s that this Upgrade requires or modifies, such as a [GunComponent].
## This array is checked in order.
# TODO: @export var requiredComponents: Array[Component] # GODOT LIMITATION: "Node export is only supported in Node-derived classes, but the current class inherits 'Resource'." :(

#endregion


#region State
var logName: String:
	get: return str(self, " ", self.name, " ", self.level)
#endregion


#region Signals
signal didAcquire(entity: Entity) ## NOTE: [signal Upgrade.didAcquire] is emitted before [signal UpgradesComponent.didAcquire].
signal didDiscard(entity: Entity)

signal didLevelUp
signal didLevelDown
signal didMaxLevel
#endregion


#region Dependencies
#endregion


#region Gameplay Functionality

## Applies this Upgrade to an [Entity] by calling the method [member payloadMethodName] from the [member payload] Script: `onUpgrade_didAcquireOrLevelUp()`
## May be overridden in a subclass to check game-specific conditions etc.
func acquire(entity: Entity) -> bool:
	self.payload.call(self.payloadMethodName, self, entity)
	self.didAcquire.emit(entity)
	return true


## Override in subclass to perform any modifications to the entity or other components when gaining (or losing) a [member level].
## Level 0 is when the Upgrade is first acquired by an entity.
func processLevel() -> bool:
	# TODO: Stub
	return true


## Override in subclass to perform any per-frame modifications to the entity or other components.
func _process(_delta: float) -> void:
	pass


func discard(entity: Entity) -> bool:
	# TODO: Stub
	didDiscard.emit(entity)
	return true

#endregion

#region Management

## Returns the cost for the specified level or the current level.
## If no cost has been specified for the respective level and [member shouldUseLastCostForHigherLevels] is not `true`, -1 is returned.
func getCost(levelOverride: int = self.level) -> int:
	if levelOverride < costs.size(): # Array size will be 1 less than the last valid index.
		return costs[levelOverride]

	# If the level is higher than the array size and shouldUseLastCostForHigherLevels, return the highest index if the array is not empty.
	elif shouldUseLastCostForHigherLevels and not costs.is_empty() and levelOverride >= costs.size(): # Checks are in order of speed
		return costs.back()

	else:
		return -1


## Returns the cost for the next level. If there is no next level, -1 is returned.
func getNextCost() -> int:
	return self.getCost(self.level + 1)


## Returns the cost for acquiring or upgrading this Upgrade for a particular [UpgradesComponent].
## If the component does NOT have this Upgrade, then the CURRENT level's cost is returned.
## If the component already has this Upgrade, then the NEXT level's cost is returned.
## If there is no cost for the respective level, -1 is returned.
func getCostForUpgradesComponent(upgradesComponent: UpgradesComponent) -> int:
	if upgradesComponent.getUpgrade(self.name): # Is this upgrade already installed in that component?
		return getNextCost()
	else:
		return getCost()

#endregion



#region Validation

## Checks if the specific entity meets all the requirements and costs to acquire this Upgrade.
func validateEntityEligibility(entity: Entity) -> bool:
	var statsComponent: StatsComponent = entity.getComponent(StatsComponent)
	var upgradesComponent: UpgradesComponent = entity.getComponent(UpgradesComponent)
	return validateStatsComponent(statsComponent) and validateUpgradesComponent(upgradesComponent)


## Checks whether the specified [StatsComponent] can meet the cost for this Upgrade's specified level.
func validateStatsComponent(statsComponent: StatsComponent, levelOverride: int = self.level) -> bool:
	# If there is no cost for the specified level, then the component can afford it, of course.
	var cost: int = self.getCost(levelOverride)
	if cost <= 0: return true

	# Does the component have our required Stat type?
	var costStatInComponent: Stat = statsComponent.getStat(self.costStat.name)
	if not costStatInComponent: return false

	# Is the stat's value >= our cost?
	return costStatInComponent.value >= cost


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
			if shouldShowDebugInfo: Debug.printDebug(str("Missing requirement ", requirement, " in ", upgradesComponent), str(self))
			return requirement

	return null


## Checks whether the provided [UpgradesComponent] has any of the [mutuallyExclusiveUpgrades] which conflict with THIS Upgrade.
## Returns: The first MATCHING mutually-exclusive Upgrade. If `null` is returned, then there are no conflicting Upgrades.
func findMutuallyExclusiveConflict(upgradesComponent: UpgradesComponent) -> Upgrade:
	if self.mutuallyExclusiveUpgrades.is_empty(): return null

	for conflict in self.mutuallyExclusiveUpgrades:
		# Is there any conflicting Upgrade?
		if not upgradesComponent.getUpgrade(conflict.name):
			if shouldShowDebugInfo: Debug.printDebug(str("Mutually-exclusive upgrade ", conflict, " in ", upgradesComponent), str(self))
			return conflict

	return null


## Checks if the [member payload] script contains a function matching the required signature as [member payloadMethodName].
func validatePayloadSignature() -> bool:
	return Tools.findMethodInScript(self.payload, self.payloadMethodName)

#endregion
