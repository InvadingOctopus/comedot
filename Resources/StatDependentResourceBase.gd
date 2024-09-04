## Abstract base class for Resources that may have cost a certain amount of an [Stat] to "purchase" or use.
## For example, a product in a shop with a price represented as a Gold Stat, or a [TargetableAction] spell which requires a Mana Stat to cast.

class_name StatDependentResourceBase
extends NamedResourceBase # because we cannot have multiple inheritance in Godot, so include the most common combination :')


#region Common Parameters

## The [Stat] required to "pay" for the Upgrade, such as spending Money at a shop or Energy at a machine.
## If no Stat is specified, then the Upgrade is always free.
## NOTE: If a Stat is specified but not present in an Entity's [StatsComponent], the Upgrade CANNOT be purchased EVEN IF the cost is <= 0.
## This acts as a further layer of validation: The Entity must have the Stat type in its StatsComponent, i.e. be able to HOLD a resource such as gold etc., but it may be 0.
## NOTE: This actual [Stat] is never used for comparison when searching in a [StatsComponent], ONLY THE NAME.
## Searching by the name allows any Entity, even monsters etc. to use Upgrades, by having different instances of the same Stat resource.
## DESIGN: This parameter accepts a [Stat] to eliminate bugs from typing incorrect names, and to be able to use the [member Stat.displayName].
@export var costStat: Stat

## The cost for "purchasing" or using this Resource. This may be the price for a product in a shop, or the mana required to cast a spell etc.
@export_range(0, 1000, 1, "or_greater") var cost: int

#endregion


#region Derived Properties

## This is the property that is ACTUALLY used to search for the required Stat, so that ANY instance of a particular Stat resource may be usable.
var costStatName: StringName:
	get: return self.costStat.name if self.costStat else &""

#endregion

