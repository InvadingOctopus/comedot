## A subclass of [InteractionComponent] with a [CooldownTimer]
## When on cooldown, rejects interaction requests and emits [signal didDenyInteraction]
## To change the [CooldownTimer], enable "Editable Children"

class_name InteractionWithCooldownComponent
extends InteractionComponent


#region Parameters

## If `true` then there's a short delay after a failed [Payload] or [method performInteraction], to prevent spamming the UI/network etc.
## DESIGN: EXCEPTION: Cooldowns are NOT started for "request rejections" such as [member isEnabled] being `false`, invalid [member payload] state, or insufficient [member cost] "payment" in [InteractionWithCostComponent]
## because the interaction isn't even allowed in those cases.
@export var shouldCooldownOnFailure: bool = true
@export_range(0.0, 60.0, 0.01) var cooldownOnFailure: float = 0.5

## If `true` then [method InteractionControlComponent.interact] is called again on [member previousInteractor] after the cooldown [Timer] finishes.
## TIP: Use [member isAutomatic] to automatically initiate the FIRST interaction on contact.
## TIP: May be useful for auto-advancing a [TextInteractionComponent] for simple NPC dialogue etc.
## TIP: Set [member shouldSkipInteractorCooldown] to ensure that the [InteractionControlComponent] is not in cooldown when this [InteractionWithCooldownComponent] comes out of cooldown.
## ALERT: Even a failed interaction may be repeated if [member shouldCooldownOnFailure]
@export var shouldRepeatInteractionAfterCooldown:	bool

@export var shouldModifyIndicatorInCooldown:		bool   = true ## If `true` then the [CanvasItem.self_modulate] of the [member interactionIndicator] is dimmed during a cooldown. WARNING: Does not preserve opacity!
@export var textInCooldown:							String = "COOLDOWN" ## If not empty, temporarily applied during a cooldown to the [member interactionIndicator] if it's a [Label] and [member shouldModifyIndicatorInCooldown] is `true`

#endregion


#region State

@onready var cooldownTimer: CooldownTimer = $CooldownTimer

## Used for [member shouldRepeatInteractionAfterCooldown] and updated by [method performInteraction] before starting a cooldown.
## IMPORTANT: MUST be updated BEFORE calling [method startCooldown]
@export_storage var previousInteractor:	InteractionControlComponent

## Allows [method checkInteractionConditions] to ignore an ONGOING cooldown.
## NOTE: This flag is reset in [method performInteraction] & cooldown methods so it must be set AFTER starting a cooldown.
## NOTE: This is DIFFERENT from [member CooldownTimer.shouldSkipNextCooldown] which prevents STARTING a cooldown once.
@export_storage var canSkipCurrentCooldown: bool

## Returns `true` if the `cooldownTimer` still has remaining [Timer.time_left].
## ALERT: Does NOT check [Timer.paused]
var isOnCooldown: bool:
	get: return cooldownTimer.isOnCooldown

#endregion


#region Signals
signal didStartCooldown(time: float) ## ALERT: NOT emitted if [method Timer.start] is called manually on [member cooldownTimer].
signal didFinishCooldown
#endregion


## Customizes the [member interactionIndicator] if [member shouldModifyIndicatorInCooldown]
## ALERT: Calling Timer.start() bypasses `didStartCooldown` and skips the immediate UI update, because [Timer] does not have a "started" signal :'(
func updateIndicator() -> void:
	if not interactionIndicator: return
	interactionIndicator.visible = isEnabled and (shouldAlwaysShowIndicator or controllersInContactCount > 0)

	if shouldModifyIndicatorInCooldown:
		# Just modify `self_modulate` alpha to avoid disrupting any existing `modulate` tints
		# NOTE: DESIGN: Don't use `visible` to represent cooldown state because visibility is determined by physics contacts with [InteractionControlComponent]
		# TODO: Preserve original opacity
		interactionIndicator.self_modulate = Color(interactionIndicator.self_modulate, 1.0) if is_zero_approx(cooldownTimer.time_left) else Color(interactionIndicator.self_modulate, 0.25)

	if interactionIndicator is Label:
		# Are we on cooldown?
		if shouldModifyIndicatorInCooldown and not textInCooldown.is_empty() and not is_zero_approx(cooldownTimer.time_left):
			interactionIndicator.text = textInCooldown
		else:
			interactionIndicator.text = self.text # TBD: Allow empty strings?


#region Interaction Interface

## Extends [method InteractionComponent.checkInteractionConditions] to include a cooldown [Timer] check.
## Rejects interaction when on cooldown, unless [member canSkipCurrentCooldown] is set.
## IMPORTANT: Subclasses MUST call `super` to enforce cooldown checks.
func checkInteractionConditions(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	return (canSkipCurrentCooldown or is_zero_approx(cooldownTimer.time_left)) \
	and super.checkInteractionConditions(interactorEntity, interactionControlComponent) # `isEnabled` is checked by superclass


## Extends [method performInteraction] to start a cooldown [Timer] after an interaction.
## DESIGN: Allows "forced" execution: Does NOT verify cooldown or [method checkInteractionConditions]; callers should check [method requestToInteract] for validation.
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> Variant:
	if debugMode: printDebug(str("performInteraction() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent, ", isEnabled: ", isEnabled, ", cooldown: ", cooldownTimer.time_left, ", canSkipCurrentCooldown: ", canSkipCurrentCooldown))
	if not isEnabled: return false
	if not payload and not allowNoPayload: return null

	# NOTE: Clear the skip flag here too and not just on startCooldown()
	# FIXED: because if the interaction fails but there is no `shouldCooldownOnFailure` then the NEXT interaction will also be skippable!
	if  canSkipCurrentCooldown and not is_zero_approx(cooldownTimer.time_left):
		canSkipCurrentCooldown = false

	# Let the superclass perform the full interaction THEN start the cooldown after `didPerformInteraction` etc.
	var result: Variant = super.performInteraction(interactorEntity, interactionControlComponent)

	# NOTE: Call our own self.startCooldown() wrapper to reset `canSkipCurrentCooldown` etc.
	# NOTE: Update `previousInteractor` regardless of success or failure:
	# FIXED: Otherwise if Interactor1 succeeds then Interactor2 later causes a failure cooldown, completion might repeat Interactor1 and so on.
	if Tools.checkResult(result):
		previousInteractor = interactionControlComponent
		self.startCooldown()
	elif shouldCooldownOnFailure:
		previousInteractor = interactionControlComponent
		self.startCooldown(cooldownOnFailure)

	return result # Always return the raw result from the superclass; don't "flatten" failures to `false`


## Calls [method InteractionControlComponent.interact] again on [member previousInteractor]
## Called from [method onCooldownTimer_didFinishCooldown] if [member shouldRepeatInteractionAfterCooldown]
## May be overridden by subclasses such as [TextInteractionComponent] to add further checks on whether to repeat or not.
func repeatPreviousInteraction() -> Variant:
	if debugMode: printLog(str("repeatPreviousInteraction() with: ", previousInteractor))
	if is_instance_valid(previousInteractor): return previousInteractor.interact(self)
	else: return null

#endregion


#region Cooldown

## Clears [member canSkipCurrentCooldown] then calls [method CooldownTimer.startCooldown]
func startCooldown(overrideTime: float = cooldownTimer.cooldownSeconds, restartIfOnCooldown: bool = false) -> float:
	self.canSkipCurrentCooldown = false # Clear BEFORE calling CooldownTimer.startCooldown() because it may not emit `didStartCooldown`
	return cooldownTimer.startCooldown(overrideTime, restartIfOnCooldown)


## Clears state and calls [method CooldownTimer.cancelCooldown] & [method updateIndicator]
func cancelCooldown() -> void:
	self.previousInteractor		= null
	self.canSkipCurrentCooldown	= false
	cooldownTimer.cancelCooldown()
	self.updateIndicator()


## Calls [method updateIndicator] if [member shouldModifyIndicatorInCooldown] and emits [signal InteractionWithCooldownComponent.didStartCooldown]
func onCooldownTimer_didStartCooldown(time: float) -> void:
	if shouldModifyIndicatorInCooldown: updateIndicator()
	didStartCooldown.emit(time)


## Calls [method updateIndicator], emits [signal didFinishCooldown] then if [member shouldRepeatInteractionAfterCooldown], calls [method repeatPreviousInteraction]
func onCooldownTimer_didFinishCooldown() -> void:
	canSkipCurrentCooldown = false # Just in case
	updateIndicator() # NOTE: Always restore normal visibility/text, whether `shouldModifyIndicatorInCooldown` is set or not
	didFinishCooldown.emit() # IMPORTANT: Emit BEFORE repeating so observers can see "StartCooldown1 → FinishCooldown1 → StartCooldown2"
	# NOTE: Signal handlers may modify state such as `previousInteractor` etc. for complex game-specific "hacks" etc; that's OK.
	if shouldRepeatInteractionAfterCooldown: repeatPreviousInteraction() # Again again!? # NOTE: Failed interactions may also be repeated.

#endregion
