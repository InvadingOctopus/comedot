## Abstract base class for Resources that may have cost a certain amount of an [Stat] to "purchase" or use.
## For example, a product in a shop with a price represented as a Gold Stat, or a [TargetableAction] spell which requires a Mana Stat to cast.

@warning_ignore("missing_tool")
@abstract class_name StatDependentResourceBase
extends GameplayResourceBase # because we cannot have multiple inheritance in Godot, so include the most common combination :')

# TBD: Allow negative costs? :')


#region Common Parameters

## The [Stat] required to "pay" for this resource, such as spending Money at a shop or using innate Mana to cast a spell.
## If no Stat is specified, then this resource is always free.
## NOTE: If a Stat is specified but not present in an Entity's [StatsComponent], this resource CANNOT be purchased EVEN IF the cost is <= 0.
## This acts as a further layer of validation: The Entity must have the Stat type in its [StatsComponent], i.e. be able to HOLD a "currency" such as gold etc., but it may be 0.
## NOTE: This exact [Stat] instance should not be used for comparison when searching in a [StatsComponent] etc., ONLY THE STAT'S NAME: [member Stat.name]
## Searching by the name allows any Entity, even monsters etc. to use this resource, by having different instances of the same Stat.
## DESIGN: This parameter accepts a [Stat] to eliminate bugs from typing incorrect names, and to be able to use the [member Stat.displayName].
@export var costStat: Stat:
	set(newValue):
		if newValue != costStat:
			# Disconnect from the previous Stat first
			if costStat: Tools.disconnectSignal(costStat.changed, self.onCostStat_changed)
			# Connect to the new Stat and update our state
			costStat = newValue
			if costStat: self.connectToStatSignals()
			self.updateFlags()

## The cost for "purchasing" or using this resource. This amount will be SUBTRACTED from an [Stat].
## This may be the price for a product in a shop, or the mana required to cast a spell etc.
@export_range(0, 1000, 1, "or_greater") var cost: int:
	set(newValue):
		if newValue != cost:
			cost = newValue
			self.updateFlags()

#endregion


#region State
## Returns `true` if the [member Stat.value] of the specific Stat instance provided for the [member costStat] property is equal to or greater than [member cost].
## Updated whenever the [member costStat] or [member cost] properties are reassigned, or on [signal Stat.changed] if [method connectToStatSignals] is used 
## NOTE: Unlike the other validation functions, this flag is `false` if [member costStat] is `null`, even though a missing `costStat` means this resource is ALWAYS FREE.
## NOTE: A negative cost also sets this flag to `true`
var isUsableWithCostStat: bool
#endregion


#region Derived Properties

## The property used to search for the required Stat in a [StatsComponent] etc., so that ANY instance of a particular Stat resource may be usable.
var costStatName: StringName:
	get: return self.costStat.name if self.costStat else &""

#endregion


#region Signals

signal didBecomeUsable
signal didBecomeUnusable


## Connects to the [signal Stat.changed] of the [member costStat] to monitor the [member Stat.value] and then emit this resource's own [signal didBecomeUsable] and [signal didBecomeUnusable] accordingly.
## WARNING: May decrease performance if used with rapidly-changing Stats.
func connectToStatSignals() -> void:
	if not is_instance_valid(costStat):
		Debug.printWarning("connectToStatSignals() costStat is null", self)
		return

	Tools.connectSignal(costStat.changed, self.onCostStat_changed)


func onCostStat_changed() -> void:
	if not costStat: return

	# Emit our signals only when the usability CHANGES.
	if  costStat.value >= self.cost \
	and costStat.previousValue < self.cost:
		self.isUsableWithCostStat = true
		self.didBecomeUsable.emit()
	
	elif costStat.value < self.cost \
	and  costStat.previousValue >= self.cost:
		self.isUsableWithCostStat = false
		self.didBecomeUnusable.emit()

#endregion


#region Validation

## Checks if the offered [Stat] has the same [member Stat.name] as the name of this resource's [member costStat],
## and if the offered [member Stat.value] is equal to or higher than this resource's [member cost].
## NOTE: If there is no [member costStat], the result is always `true`, because then this resource may always be used or "purchased" without "paying" any cost.
## NOTE: Only the Stat NAMES are compared, because the Stats may be different INSTANCES of the same Stat Resource. e.g. a player may also have a "Money" Stat and an NPC or monster may also have "Money".
func validateOfferedStat(offeredStat: Stat) -> bool:
	# GODOT:  Apparently `if not` is better than `== null` because it implies is_instance_valid() (not sure)
	# DESIGN: If there is no `costStat`, always return `true`, because that means there is no cost, and we can't compare against a non-existent `offeredStat` anyway.
	if not costStat: return true
	# If there is no Stat offered, return `false`, because there's nothing to validate
	elif not offeredStat: return false 
	# If there is a cost and an offer, check if the offer can pay for the cost
	else: return offeredStat.name == costStat.name and offeredStat.value >= self.cost


## Checks if the specified [StatsComponent] has the [Stat] required to "pay" for or use this resource, such as "mana" or "money",
## and calls [method validateOfferedStat].
## If this resource has no [member costStat], returns `true`, because this resource may always be "purchased" or used without "paying" any cost.
func validateStatsComponent(statsComponent: StatsComponent) -> bool:
	if not self.costStat: 
		return true
	elif not statsComponent:
		Debug.printWarning("validateStatsComponent(): null", self)
		return false
	else:
		var offeredStat: Stat = statsComponent.getStat(self.costStat.name)
		return self.validateOfferedStat(offeredStat)


## Queries the specified [StatsComponent] and returns the [Stat] matching the [member Stat.name] of this Resource's [member costStat].
## If this Resource has not [member costStat], `null` is returned.
func getPaymentStatFromStatsComponent(statsComponent: StatsComponent) -> Stat:
	# TBD: Review & replace with a better interface if needed
	if not self.costStat: return null # Avoid printing a warning if there's no cost, so check the cost first.
	elif not statsComponent:
		Debug.printWarning("getPaymentStatFromStatsComponent(): null", self)
		return null
	else: return statsComponent.getStat(self.costStat.name)


func updateFlags() -> void:
	## DESIGN: If there is no `costStat` then `isUsableWithCostStat` should be `false` even though this resource is always free.
	self.isUsableWithCostStat = costStat != null \
		and (self.cost <= 0 or costStat.value >= self.cost) # NOTE: Allows a negative cost to succeed! TBD: Should this be `== 0` only?

#endregion


#region Interface 

## Deducts this Resource's [member cost] from the offered "payment" [Stat] and returns `true` if the "payment" was successful.
## Calls [method validateOfferedStat] if [param validateStat], which may be skipped if the caller has already performed the validation.
## NOTE: DESIGN: If there is NO cost, then this method returns `true`, EVEN IF there the [param offeredStat] is invalid,
## because the purpose of this function is to deduct the cost, so if there is no cost, then the intended task has already succeeded.
func deductCostFromStat(offeredStat: Stat, validateStat: bool = true) -> bool:
	# TBD: Review & replace with a better interface if needed
	if self.cost == 0 or not self.costStat:
		return true
	elif offeredStat and (not validateStat or validateOfferedStat(offeredStat)): # Make sure the Stat exists even if we skip validation
		offeredStat.value -= self.cost
		return true
	else:
		return false

#endregion
