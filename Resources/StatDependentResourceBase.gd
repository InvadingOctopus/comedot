## Abstract base class for Resources that may have cost a certain amount of an [Stat] to "purchase" or use.
## For example, a product in a shop with a price represented as a Gold Stat, or a [TargetableAction] spell which requires a Mana Stat to cast.

class_name StatDependentResourceBase
extends NamedResourceBase # because we cannot have multiple inheritance in Godot, so include the most common combination :')


#region Common Parameters

## The [Stat] required to "pay" for this resource, such as spending Money at a shop or using innate Mana to cast a spell.
## If no Stat is specified, then this resource is always free.
## NOTE: If a Stat is specified but not present in an Entity's [StatsComponent], this resource CANNOT be purchased EVEN IF the cost is <= 0.
## This acts as a further layer of validation: The Entity must have the Stat type in its [StatsComponent], i.e. be able to HOLD a "currency" such as gold etc., but it may be 0.
## NOTE: This actual [Stat] is never used for comparison when searching in a [StatsComponent], ONLY THE NAME.
## Searching by the name allows any Entity, even monsters etc. to use this resource, by having different instances of the same Stat.
## DESIGN: This parameter accepts a [Stat] to eliminate bugs from typing incorrect names, and to be able to use the [member Stat.displayName].
@export var costStat: Stat

## The cost for "purchasing" or using this resource. This may be the price for a product in a shop, or the mana required to cast a spell etc.
@export_range(0, 1000, 1, "or_greater") var cost: int

#endregion


#region Derived Properties

## This is the property that is ACTUALLY used to search for the required Stat, so that ANY instance of a particular Stat resource may be usable.
var costStatName: StringName:
	get: return self.costStat.name if self.costStat else &""

#endregion


#region Validation

## Checks if the offered [Stat] has the same [member Stat.name] as the name of this resource's [member costStat],
## and the offered [member Stat.value] is equal to or higher than this resource's [member cost].
## If there is no [member costStat], returns `true`, because this resource may always be "purchased" or used without "paying" any cost.
## NOTE: Only the Stat NAMES are compared, because the Stats may be different INSTANCES of the same Stat Resource. e.g. a player may also have a "Money" Stat and an NPC or monster may also have "Money".
func validateOfferedStat(offeredStat: Stat) -> bool:
	return  self.costStat 	  != null \
		and offeredStat.name  == self.name \
		and offeredStat.value >= self.cost


## Checks if the specified [StatsComponent] has the [Stat] required to "pay" for or use this resource, such as "mana" or "money",
## and calls [method validateOfferedStat].
## If this resource has no [member costStat], returns `true`, because this resource may always be "purchased" or used without "paying" any cost.
func validateStatsComponent(statsComponent: StatsComponent) -> bool:
	if not self.costStat: 
		return true
	else:
		var offeredStat: Stat = statsComponent.getStat(self.costStat.name)
		return self.validateOfferedStat(offeredStat)

#endregion

