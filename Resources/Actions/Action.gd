## Represents an "special" action, skill or ability that a player or another character may explicitly choose to perform. May have a cost and may require a target to be chosen.
## It may be a special skill/spell such as "Fireball", an innate ability such as "Fly", or a trivial command like "Examine".
## NOTE: In most games this does NOT include the very basic common actions such as movement, jumping, shooting etc.
## NOTE: This is NOT a player input device action such as a joystick movement, gamepad button or keyboard keypress.

class_name Action
extends StatDependentResourceBase

# TBD:  A less ambiguous name, like SpecialAction or Ability? Because "action" is a Godot term for all input events.
# TODO: Add support for position targeting, e.g. casting a Fireball at the ground.


#region Parameters

@export var requiresTarget:	bool

@export var hasFiniteUses:	bool ## If `true`, then this Action may be performed only for a number times equal to [member maximumUses]
@export var maximumUses:	int: ## The number of times this Action may be performed, if [member hasFiniteUses]. Setting this property resets [member usesRemaining].
	set(newValue):
		if newValue != maximumUses:
			if debugMode: Debug.printChange("maximumUses",   maximumUses,   newValue)
			if debugMode: Debug.printChange("usesRemaining", usesRemaining, newValue)
			maximumUses   = newValue
			usesRemaining = maximumUses # DUMBDOT: Set usesRemaining here because [Resource]s don't have a _ready() :(

@export_range(0, 6000, 0.1) var cooldown: float = 0 ## The time in seconds (or fraction of a second) to wait before this Action may be used again.

## The code to execute when this Action is performed. See [Payload] for explanation and available options.
@export var payload: Payload

@export var debugMode: bool

#endregion


#region State

## If [member hasFiniteUses]
@export_storage var usesRemaining: int = self.maximumUses: # BUG: DUMBDOT: Does not get initialized to `maximumUses`
	set(newValue):
		if newValue != usesRemaining:
			if debugMode: Debug.printChange("usesRemaining", usesRemaining, newValue, true) # logAsTrace
			usesRemaining = newValue

## The number of seconds remaining before this Action may be used again.
## NOTE: This must be reduced by an [ActionsComponent] on every frame, because [Resource]s cannot perform any per-frame updates on their own.
@export_storage var cooldownRemaining: float:
	set(newValue):
		cooldownRemaining = newValue
		if  cooldownRemaining < 0 or is_zero_approx(cooldownRemaining):
			cooldownRemaining = 0
			didFinishCooldown.emit()
#endregion


#region Derived Properties

var logName: String:
	get: return str(self.get_script().get_global_name(), " ", self, " ", self.name)

var isOnCooldown: bool:
	get:
		# Also return `false` if there is no cooldown at all 
		return  (cooldown > 0 or not is_zero_approx(cooldown)) \
			and (cooldownRemaining > 0 or not is_zero_approx(cooldownRemaining)) # Multiple checks in case of floating point funkery

## Returns `true` if all conditions pass, such as payload, cooldown and uses remaining.
## TIP: For [StatDependentResourceBase] validation, call [method StatDependentResourceBase.validateStatsComponent] etc.
var isReady: bool:
	get: return  not isOnCooldown \
			and (not hasFiniteUses or usesRemaining > 0) \
			and is_instance_valid(payload) # Simple checks first. Allow 0.1 uses :')

#endregion


#region Signals

## Emitted if [member requiresTarget] is `true` but a target has not been provided for [method perform]. 
## May be handled by game-specific UI to prompt the player to choose a target for this Action.
## NOTE: If this Action is to be performed via an [ActionsComponent]'s [method ActionsComponent.perform] then this signal will NOT be emitted; ONLY the Component's [signal ActionsComponent.didRequestTarget] is emitted.
signal didRequestTarget(source: Entity)

signal didDecreaseUses ## Emitted when [member usesRemaining] decreases.
signal didDepleteUses  ## Emitted if [member hasFiniteUses] and [member usesRemaining] goes below 1

signal didStartCooldown
signal didFinishCooldown

#endregion


#region Interface

## Returns whether this Action is currently usable (i.e. off cooldown, have available uses) with the provided [Stat] and source/target.
## NOTE: The default implementation of this method does NOT check for [param target] or [member requiresTarget];
## TIP: call [method checkTarget] separately, or override and extend this method in a subclass to add further validation.
@warning_ignore("unused_parameter")
func checkUsability(source: Entity, target: Entity = null, paymentStat: Stat = null) -> bool:
	# Perform the more simple and more frequently false checks first

	# Check cooldown
	if self.isOnCooldown: return false # TBD: Log?

	# Check number of uses remaining
	if self.hasFiniteUses and self.usesRemaining < 1:
		if debugMode: Debug.printDebug("hasFiniteUses, usesRemaining < 1", self)
		return false

	if not is_instance_valid(self.payload):
		Debug.printWarning("Missing payload", self)
		return false

	# If there is a cost, check if the offered Stat can pay for the cost.
	if self.hasCost and not validateOfferedStat(paymentStat):
		printLog(str("Payment invalid! costStat: ", self.costStat, ", cost: ", self.cost, ", paymentStat: ", paymentStat))
		return false

	return true


## Returns `true` if the provided [param target] is valid or if this Action does not need a target.
## NOTE: Does NOT emit [signal didRequestTarget]
func checkTarget(target: Entity) -> bool:
	return not requiresTarget or is_instance_valid(target)


## Performs the Action then if applicable, deducts the [member cost] from the [param paymentStat], decrements the [member usesRemaining] and starts the [member cooldownRemaining].
## Returns: The result of the [member payload], or `false` if the Payload or [member cost] payment or a required [param target] is missing.
## TIP: PERFORMANCE: [param validateState] may be disabled by components or UI that perform their own validation, such as [ActionsComponent];
## but targets are always checked if [param requiresTarget].
## TIP: Various "bookkeeping" such as cost, cooldown can be situationally disabled by buffs etc. via [param deductCost], [param startCooldown] etc.
## ALERT: [param deductCost] does not skip validation for [param paymentStat] if [param validateState] is set.
func perform(source: Entity, target: Entity = null, paymentStat: Stat = null, 
validateState:	bool = true,
deductCost:		bool = true,
refundCost:		bool = true,
decrementUses:	bool = true,
startCooldown:	bool = true) -> Variant:

	printLog(str("perform() source: ", source, ", target: ", target, ", paymentStat: ", paymentStat))

	# Check if we can be used at this time
	if validateState and not self.checkUsability(source, target, paymentStat):
		# ALERT: Invalid `paymentStat` will cause this function to fail even if `deductCost` is false!
		# DESIGN: This is intentional; `deductCost` is simply a one-off "favor" for temporary buffs etc.; it is not related to validation.
		return false

	# See if we need a target
	if not checkTarget(target):
		# TBD: Log? if debugMode: Debug.printDebug("requiresTarget but no target", self)
		self.didRequestTarget.emit(source)
		return false

	# Deduct cost first, then refund later if the Payload fails. TODO: Test & verify
	var statChange: int # NOTE: Store the CHANGE not the absolute cost; e.g. if cost==10 and the stat was 5 and somehow allowed, then 5 would be deducted, so we should refund 5 and not 10
	if self.hasCost and deductCost:
		# TBD: How to make sure the deduction was successful?
		# deductCostFromStat() only returns the change, but a 0 may also be the result of clamping!
		# So we doublecheck the payment stat to make sure
		if not validateOfferedStat(paymentStat):
			printLog(str("Payment failed! costStat: ", self.costStat, ", cost: ", self.cost, ", paymentStat: ", paymentStat))
			return false
		statChange = self.deductCostFromStat(paymentStat, false) # not validateOffer because we already checked

	# Execute the payload!
	var payloadResult: Variant = payload.execute(source, target)

	# IMPORTANT: Deduct the cost from the Stat only if the payload was successfully executed!
	if Tools.checkResult(payloadResult): # Must not be `null` and not `false` and not an empty collection

		# Let the target know, if any
		if target:
			var actionTargetableComponent: ActionTargetableComponent = target.findFirstComponentSubclass(ActionTargetableComponent) # TBD: Allow sublasses such as ActionReactionComponent
			if  actionTargetableComponent:
				actionTargetableComponent.didTarget(self, source, payloadResult)

		# Deduct the number of uses
		if decrementUses and self.hasFiniteUses:
			self.usesRemaining -= 1
			didDecreaseUses.emit()
			if debugMode: Debug.printDebug(str("hasFiniteUses, usesRemaining: ", usesRemaining), self)
			if usesRemaining < 1: didDepleteUses.emit() # TBD: == 0 or < 1?

		# Start cooling down
		if startCooldown and self.cooldown > 0 and not is_zero_approx(self.cooldown): # Multiple checks in case of floating point funkery
			self.cooldownRemaining = self.cooldown
			didStartCooldown.emit()

	elif refundCost and statChange != 0 and paymentStat: # Refund the cost if things didn't work out
		paymentStat.value += -statChange # The refund is the inverse of the change!

	return payloadResult

#endregion


func printLog(message: String) -> void:
	if debugMode: Debug.printLog(message, str(self.logName), "", Global.Colors.logResource)
