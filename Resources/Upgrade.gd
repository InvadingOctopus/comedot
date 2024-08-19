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

@export var name: StringName:
	set(newValue):
		if newValue.is_empty():
			Debug.printWarning("Rejected attempt to set name to empty string")
			return
		name = newValue
		self.resource_name = name # CHECK: Does this work without @tool?

## A list of costs for each [member level] of this upgrade. The first cost at array index 0 is the requirement for initially acquiring this upgrade. 
## `cost[n]` == Level n+1 so `cost[1]` == Upgrade Level 2.
## If a cost is missing, then the level is free. If the array is empty, then the Upgrade is always free.
@export var cost: Array[Stat]

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
@export var requiredUpgrades: Array[Upgrade]

## An optional list of upgrades which prevent this upgrade from being acquired or used.
## For example, if the player has a fire-based weapon, they may not equip a water-based weapon.
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
