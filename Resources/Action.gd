## Represents an "special" action, skill or ability that a player or another character may explicitly choose to perform. May have a cost and may require a target to be chosen.
## It may be a special skill/spell such as "Fireball", an innate ability such as "Fly", or a trivial command like "Examine".
## NOTE: In most games this does NOT include the very basic common actions such as movement, jumping, shooting etc.
## NOTE: This is NOT a player input device action such as a joystick movement, gamepad button or keyboard keypress.

class_name Action
extends StatDependentResourceBase

# TBD:  A less ambiguous name, like ExplicitAction or Ability? Because "action" is a Godot term for all input events.
# TODO: Add support for position targeting.


#region Parameters

@export var requiresTarget:	bool

@export var hasFiniteUses:	bool ## If `true`, then this Action may be performed only for a number times equal to [member maximumUses]
@export var maximumUses:	int: ## The number of times this Action may be performed, if [member hasFiniteUses]. Setting this property resets [member usesRemaining].
	set(newValue):
		if newValue != maximumUses:
			if debugMode: Debug.printChange("maximumUses", maximumUses, newValue)
			if debugMode: Debug.printChange("usesRemaining", usesRemaining, newValue)
			maximumUses = newValue
			usesRemaining = maximumUses

@export_range(0, 6000, 0.1) var cooldown: float = 0 ## The time in seconds (or fraction of a second) to wait before this Action may be used again.

## The code to execute when this Action is performed. See [Payload] for explanation and available options.
@export var payload:		Payload

@export var debugMode: bool

#endregion


#region State

## If [member hasFiniteUses]
@export_storage var usesRemaining: int = self.maximumUses # BUG: Does not get initialized to `maximumUses`

## The number of seconds remaining before this Action may be used again.
## NOTE: This must be reduced by an [ActionsComponent] on every frame, because [Resource]s cannot perform any per-frame updates on their own.
@export_storage var cooldownRemaining: float:
	set(newValue):
		cooldownRemaining = newValue
		if cooldownRemaining < 0 or is_zero_approx(cooldownRemaining):
			cooldownRemaining = 0
			didFinishCooldown.emit()
#endregion


#region Derived Properties
var logName: String:
	get: return str(self.get_script().get_global_name(), " ", self, " ", self.name)

var isUsable: bool: ## Returns `true` if this Action is off cooldown and has uses remaining. For [StatDependentResourceBase] validation, call [method StatDependentResourceBase.validateStatsComponent] etc.
	get: return (not hasFiniteUses or usesRemaining > 0) and not isInCooldown

var isInCooldown: bool:
	get:
		# Also return `false` if there is no cooldown at all 
		return  (cooldown > 0 or not is_zero_approx(cooldown)) \
			and (cooldownRemaining > 0 or not is_zero_approx(cooldownRemaining)) # Multiple checks in case of floating point funkery
#endregion


#region Signals

## Emitted if [member requiresTarget] is `true` but a target has not been provided for [method perform]. 
## May be handled by game-specific UI to prompt the player to choose a target for this Action.
## NOTE: If this Action is to be performed via an [ActionsComponent]'s [method ActionsComponent.perform] then this signal will NOT be emitted; ONLY the Component's [signal ActionsComponent.didRequestTarget] is emitted.
signal didRequestTarget(source: Entity)

signal didDecreaseUses ## Emitted when [member usesRemaining] decreases.
signal didDepleteUses ## Emitted if [member hasFiniteUses] and [member usesRemaining] goes below 1

signal didStartCooldown
signal didFinishCooldown

#endregion


#region Interface

## Returns the result of the [member payload], or `false` if the Payload or [member cost] payment or a required [param target] is missing.
func perform(paymentStat: Stat, source: Entity, target: Entity = null) -> Variant:
	printLog(str("perform() source: ", source, ", target: ", target))

	if not self.payload:
		Debug.printWarning("Missing payload", self)
		return false

	# Check number of uses remaining
	if self.hasFiniteUses and usesRemaining < 1:
		if debugMode: Debug.printDebug("hasFiniteUses, usesRemaining < 1", self)
		return false

	# Check cooldown
	if isInCooldown: return false # TBD: Log?

	# Check for target
	if self.requiresTarget and target == null:
		self.didRequestTarget.emit(source)
		return false

	# Check if the offered Stat can pay for the cost, if there is a cost.
	if self.costStat and self.cost >= 0 and not validateOfferedStat(paymentStat):
		printLog(str("Payment failed! self.costStat: ", self.costStat, ", self.cost: ", self.cost, ", paymentStat: ", paymentStat))
		return false
	
	# Execute the payload!
	var payloadResult: Variant = payload.execute(source, target)

	# IMPORTANT: Deduct the cost from the Stat only if the payload was successfully executed!
	if payloadResult: # Must not be `null` and not `false`
		self.deductCostFromStat(paymentStat) # TBD: Validate even if the `cost` is negative?
		
		# Deduct the number of uses
		if self.hasFiniteUses:
			self.usesRemaining -= 1
			didDecreaseUses.emit()
			if debugMode: Debug.printDebug(str("hasFiniteUses, usesRemaining: ", usesRemaining), self)
			if usesRemaining < 1: didDepleteUses.emit() # TBD: == 0 or < 1?

		# Start cooling down
		if self.cooldown > 0 and not is_zero_approx(self.cooldown): # Multiple checks in case of floating point funkery
			self.cooldownRemaining = self.cooldown
			didStartCooldown.emit()

	return payloadResult

#endregion


func printLog(message: String) -> void:
	if debugMode: Debug.printLog(message, str(self.logName), "", "pink")
