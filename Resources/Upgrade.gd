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


#region Parameters

## NOTE: This name MUST BE UNIQUE across all Upgrades, because [UpgradesComponent] and other classes search Upgrades by their names.
@export var name: StringName:
	set(newValue):
		if newValue.is_empty():
			Debug.printWarning("Rejected attempt to set name to empty string")
			return
		name = newValue
		self.resource_name = name # CHECK: Does this work without @tool?

## The [Stat] required to "pay" for the Upgrade, such as spending Money at a shop or Energy at a machine.
## If no stat is specified, then the Upgrade is always free.
@export var costStat: Stat

## A list of costs for each [member level] of this upgrade. The first cost at array index 0 is the requirement for initially acquiring this upgrade. 
## `cost[n]` == Level n+1 so `cost[1]` == Upgrade Level 2.
## If a cost is missing or <= -1, then the level is free. If the array is empty, then the Upgrade is always free.
@export_range(-1, 1000) var costs: Array[int]

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


## An optional list of other upgrades which are needed before this upgrade may be used.
## This array is checked in order.
@export var requiredUpgrades: Array[Upgrade]

## An optional list of upgrades which prevent this upgrade from being acquired or used.
## For example, if the player has a fire-based weapon, they may not equip a water-based weapon.
## This array is checked in order.
@export var mutuallyExclusiveUpgrades: Array[Upgrade]

@export var description: String ## An optional explanation, for internal development notes or to show the player.
@export var shouldShowDebugInfo: bool = false

#endregion


#region State
#endregion


#region Signals
signal didAcquire(entity: Entity)
signal didDiscard(entity: Entity)

signal didLevelUp
signal didLevelDown
signal didMaxLevel
#endregion


#region Dependencies
#endregion


#region Gameplay Functionality

func acquire(entity: Entity) -> bool:
	# TODO: Stub
	didAcquire.emit(entity)
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

## Checks whether the provided [UpgradesComponent] has all the [requiredUpgrades] for THIS Upgrade, and none of this Upgrade's [mutuallyExclusiveUpgrades].
func validateRequirements(upgradesComponent: UpgradesComponent) -> bool:
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

#endregion


