## Abstract base class for [Resource]s that may cost a certain amount of an [Stat] to "purchase" or use.
## For example, an item in a shop with a price represented as a Gold Stat, or a [TargetableAction] spell which requires a Mana Stat to cast.

@warning_ignore("missing_tool")
@abstract class_name StatDependentResourceBase
extends GameplayResourceBase # because we cannot have multiple inheritance in Godot, so include the most common combination :')

# TBD: Allow negative costs? :')
# TRIED: FAILED: "Refund" functionality: Fails if there are multiple users of the same resource; too much work to keep track of which caller "spent" how much etc.


#region Common Parameters

## The "currency" [Stat] required to "pay" for this gameplay resource or action, such as spending Money at a shop or using innate Mana to cast a spell.
## If no Stat is specified, then this resource is considered to be always "free", e.g. moves such as "dash" etc. that are only limited by a cooldown and so on.
## NOTE: This exact [Stat] instance should not be used for comparison when searching in a [StatsComponent] etc., ONLY THE STAT'S [member Stat.name]
## Searching by the name allows multiple entities to have different instances of the same Stat, e.g. the player and a monster may both have a "mana" Stat with different values.
## DESIGN: This parameter accepts a [Stat] instead of a [StringName] to eliminate the risk of typo bugs, and to use the [member Stat.displayName].
## ALERT: Methods such as [method validateStatsComponent] & [method deductCostFromStat] may fail if this property is missing or invalid; callers should check [member hasCost] first.
## TIP: To enforce a requirement that an Entity must have the [member costStat] type in its [StatsComponent], i.e. a character must be able to HOLD a "currency" such as gold etc., even if the price is 0,
## call [method validateStatsComponent] regardless of [member hasCost]
@export var costStat: Stat:
	set(newValue):
		if newValue != costStat:
			# Disconnect from any previous Stat
			if costStat: Tools.disconnectSignal(costStat.changed, self.onCostStat_changed)
			# Connect to the new Stat and update our state
			costStat = newValue
			if costStat: self.connectToStatSignals()
			self.updateFlags()

## The cost for using or "purchasing" this resource. This should be a POSITIVE value that will be SUBTRACTED from an [Stat] that matches [member costStat].
## This may be the price for a product in a shop, or the amount of mana required to cast a spell etc.
@export_range(0, 1000, 1, "or_greater") var cost: int:
	set(newValue):
		if newValue != cost:
			cost = newValue
			self.updateFlags()

#endregion


#region State
## Returns `true` if the [member Stat.value] of the specific Stat instance provided for the [member costStat] property is >= [member cost].
## Updated whenever the [member costStat] or [member cost] properties are reassigned, or on [signal Stat.changed] if [method connectToStatSignals] is used 
## NOTE: Unlike the other validation functions, this flag is `false` if [member costStat] is `null`, even though a missing `costStat` means this resource is ALWAYS FREE.
## NOTE: A negative cost also sets this flag to `true`
var isUsableWithCostStat: bool
#endregion


#region Derived Properties
## The property used to search for the required Stat in a [StatsComponent] etc., so that ANY instance of a particular Stat resource may be usable.
var costStatName: StringName:
	get: return costStat.name if costStat else &""

## `true` if the [member cost] is not 0 and a valid [member costStat] is present.
## If either conditions are false, then this resource or action is considered to be free, and "payment" may be skipped.
## IMPORTANT: Check this flag before calling [method validateOfferedStat], [method deductCostFromStat] etc.
## because an invalid or missing [member costStat] will cause an error.
## costStat == null and cost == 0: Free
## costStat != null and cost == 0: Free but requires Stat
## costStat == null and cost > 0:  Invalid state; error
## costStat != null and cost > 0:  Normal cost & payment
var hasCost: bool:
	get: return true if (self.cost != 0 and costStat) else false # Using `if` because `if costStat` includes is_instance_valid() TBD: Also check for nonempty `costStat.name`?
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
	updateFlags()

#endregion


#region Validation

# DESIGN: Raise error/crash if there is no `costStat` because the purpose of these methods is validation, and we can't compare against a non-existent `offeredStat`
# Callers should check `hasCost` first.
# TRIED: Treating a missing `costStat` as a "free" purchase and returning `true` caused confusion, ambiguity and too many exceptions down the line in other scripts.


## Checks if the specified [StatsComponent] has the [Stat] required to use or "pay" for this resource, such as "mana" or "gold",
## and then calls and returns the result of [method validateOfferedStat].
## IMPORTANT: PERFORMANCE: Check [member hasCost] BEFORE calling this method; a missing [member costStat] is an error!
## TIP: To enforce a requirement that an Entity must have the [member costStat] type in its [StatsComponent], i.e. be able to HOLD a "currency" such as gold etc., even if the price is 0,
## call [method validateStatsComponent] regardless of the [member cost] value.
func validateStatsComponent(statsComponent: StatsComponent) -> bool:
	if   not statsComponent: Debug.printWarning("validateStatsComponent(): null", self)
	elif not self.costStat:
		Debug.printError("validateStatsComponent(): No costStat • Check hasCost first!", self)
		return false
	else:
		var offeredStat: Stat = statsComponent.getStat(self.costStat.name)
		return self.validateOfferedStat(offeredStat) if offeredStat else false
	# else
	return false


## Queries the specified [StatsComponent] to get the [Stat] matching the [member Stat.name] of this Resource's [member costStat].
## If this Resource has no [member costStat], `null` is returned.
func getPaymentStatFromStatsComponent(statsComponent: StatsComponent) -> Stat:
	# TBD: Review & replace with a better interface if needed
	if not self.costStat: return null # DESIGN: Avoid logging a warning/error if there's no cost; the purpose of this method is to simply get a Stat, not validation.
	elif not statsComponent:
		Debug.printWarning("getPaymentStatFromStatsComponent(): invalid StatsComponent", self)
		return null
	else: return statsComponent.getStat(self.costStat.name)


## Checks if the offered [Stat] has the same [member Stat.name] as this Resource's [member costStat],
## and if the offered [member Stat.value] is equal to or higher than this Resource's [member cost].
## NOTE: Only the Stat NAMES are compared, because the Stats may be different INSTANCES of the same Stat [Resource].
## e.g. a player may also have a "gold" Stat and an NPC or monster may also have "gold".
## IMPORTANT: PERFORMANCE: Check [member hasCost] BEFORE calling this method; a missing [member costStat] is an error!
## ALERT: BUGRISK: If the [member Stat.min] is non-0 then this checking [member Stat.value] >= [member cost] may not work as expected,
## or it could be intentional, e.g. temporary buffs that prevent a Stat from falling too low etc.
func validateOfferedStat(offeredStat: Stat) -> bool:
	# TBD: Handle `offeredStat.min != 0`?
	if not costStat:
		Debug.printError("validateOfferedStat(): No costStat • Check hasCost first!", self)
		return false
	# If there is no Stat offered, return `false`, because there's nothing to validate
	elif not offeredStat: return false		
	# If there is a cost and an offer, check if the offer can pay for the cost
	else: return offeredStat.name == costStat.name and offeredStat.value >= self.cost # ALERT: BUGRISK: May not work correctly if `offeredStat.min` != 0


func updateFlags() -> void:
	var wasUsable: bool = self.isUsableWithCostStat # Monitor for change

	## DESIGN: If there is no `costStat` then `isUsableWithCostStat` should be `false` because there is no `costStat`
	## even though this resource is always free.
	self.isUsableWithCostStat = is_instance_valid(self.costStat) \
		and (self.cost <= 0 or costStat.value >= self.cost) # NOTE: Allows a negative cost to succeed! TBD: Should this be `== 0` only? ALERT: BUGRISK: May cause unexpected behavior if `costStat.min` != 0

	# Emit our signals only when the usability CHANGES
	if self.isUsableWithCostStat != wasUsable:
		if  isUsableWithCostStat: didBecomeUsable.emit()
		else: didBecomeUnusable.emit()

#endregion


#region Interface 

## Deducts this Resource's [member cost] from the offered "payment" [Stat] and returns the resulting change in the Stat's [member Stat.value].
## Returns 0 if [member cost] is 0 or if a Stat is missing/invalid.
## Calls [method validateOfferedStat] if [param validateOffer], which may be skipped if the caller has already performed validation.
## IMPORTANT: PERFORMANCE: The caller must check [member hasCost] BEFORE offering any "payment" or doing any other validation; a missing [member costStat] is an error!
## ALERT: If [param offeredStat]'s [member Stat.min] is not 0, then the cost may not be fully deducted.
## TIP: When tracking a [Stat]'s value for "refunds" (in the case of cancelled actions etc.), compare [Stat.previousChange] with the return value of this method,
## to make sure the [param offeredStat]'s previous change was not caused by a different source!
func deductCostFromStat(offeredStat: Stat, validateOffer: bool = true) -> int:
	# TBD: Review & replace with a better interface if needed
	if not self.costStat:
		Debug.printError("deductCostFromStat(): No costStat • Check hasCost first!", self)
		return 0

	elif offeredStat and (not validateOffer or validateOfferedStat(offeredStat)): # Make sure the Stat exists even if we're free or skip validation
		if self.cost == 0: return 0 # Cut the crap early

		# IMPORTANT: Do our own change tracking, because `offeredStat.previousChange` might be from a different source if our cost is 0 or the change is clamped to 0
		var previousValue: int = offeredStat.value
		offeredStat.value -= self.cost
		var change: int = offeredStat.value - previousValue

		if offeredStat.debugMode and change != -self.cost: # If the actual change in the stat's value was not the inverse of our cost, which may happen if the `min` was not 0 etc., then log a headsup in case it leads to bugs
			Debug.printDebug(str("deductCostFromStat(): ", offeredStat.logName, " change: ", change, " != -cost: ", -cost), self)

		return change
	# else
	return 0

#endregion
