## A subclass of [InteractionComponent] with a cooldown [Timer]].
## To edit the cooldown [Timer], enable "Editable Children"

class_name InteractionWithCooldownComponent
extends InteractionComponent

# TBD: Abstract functions for cooldown start/end?


#region Parameters

@export var shouldCooldownOnFailure: bool = true ## If `true` then there is a short delay in case of a failed [Payload] (but not on insufficient [member cost] payment), to prevent UI/network spamming etc.
@export_range(0.0, 60.0, 0.01) var cooldownOnFailure: float = 0.5

## If `true` then [method InteractionControlComponent.interact] is called again on [member previousInteractor] after the cooldown [Timer] finishes.
## TIP: May be useful for auto-advancing a [TextInteractionComponent] for simple NPC dialogue etc.
## TIP: Set [member shouldSkipInteractorCooldown] to ensure that the [InteractionControlComponent] is not in cooldown when this [InteractionWithCooldownComponent] comes out of cooldown.
@export var shouldRepeatInteractionAfterCooldown: bool = false
@export var shouldModifyIndicatorInCooldown:	  bool = true  ## If `true` then the [member interactionIndicator] is dimmed and modified during a cooldown.

#endregion


#region State

@onready var cooldownTimer: CooldownTimer = $CooldownTimer

## Updated on a successful [method performInteraction] and used for [member shouldRepeatInteractionAfterCooldown].
## IMPORTANT: MUST be updated by subclasses that override [method performInteraction].
@export_storage var previousInteractor: InteractionControlComponent

## Allows [method requestToInteract] & [method performInteraction] to ignore an ONGOING cooldown ONCE.
## NOTE: This flag is reset in [method startCooldown], so it must be set AFTER starting a cooldown.
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


# TBD: Tools.connectSignal(cooldownTimer.timeout, self.finishCooldown) # In case the scene file forgets to wire signals?


func updateIndicator() -> void:
	# TBD: Modify Label only on startCooldown() or hijack this method?
	# CONCERN: If only on startCooldown(), then a manual Timer.start() would skip the UI update, because Timer does not have a "started" signal :'(
	if not interactionIndicator: return
	interactionIndicator.visible = isEnabled and (shouldAlwaysShowIndicator or controllersInContactCount > 0)

	# Should the indicator indicate the cooldown?
	if shouldModifyIndicatorInCooldown:
		# Just modify `self_modulate` alpha to avoid disrupting any existing `modulate` tints
		# NOTE: DESIGN: Modifying `visible` is unreliable because making it visible onCooldownTimer_timeout() would cause it to reappear even if there is no [InteractionControlComponent] in contact.
		interactionIndicator.self_modulate = Color(interactionIndicator.self_modulate, 1.0) if is_zero_approx(cooldownTimer.time_left) else Color(interactionIndicator.self_modulate, 0.25)

	if interactionIndicator is Label:
		# Are we off cooldown?
		if shouldModifyIndicatorInCooldown and not is_zero_approx(cooldownTimer.time_left):
			interactionIndicator.text = "COOLDOWN"
		else:
			interactionIndicator.text = self.text # TBD: Allow empty strings?


#region Interaction Interface

## Extends [method InteractionComponent.requestToInteract] to include a cooldown [Timer] check.
## NOTE: Does NOT emit [signal didDenyInteraction] when on cooldown.
func requestToInteract(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	# TBD: Emit `didDenyInteraction` when on cooldown?
	if  not isEnabled \
	or (not canSkipCurrentCooldown and not is_zero_approx(cooldownTimer.time_left)):
		return false
	return super.requestToInteract(interactorEntity, interactionControlComponent)


## Extends [method performInteraction] to start a cooldown [Timer] after an interaction.
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> Variant:
	if  debugMode: printDebug(str("performInteraction() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent, ", isEnabled: ", isEnabled, ", cooldown: ", cooldownTimer.time_left, ", canSkipCurrentCooldown: ", canSkipCurrentCooldown))
	if  not isEnabled \
	or (not canSkipCurrentCooldown and not is_zero_approx(cooldownTimer.time_left)):
		return false # TBD: Check cooldown again in performInteraction() or only in requestToInteract()?

	var result: Variant = super.performInteraction(interactorEntity, interactionControlComponent)

	# NOTE: Call our own self.startCooldown() wrapper to ensure `canSkipCurrentCooldown` etc.
	if Tools.checkResult(result): # TODO: Add shouldSucceedIfNoPayload for "reactions" or whatever
		previousInteractor = interactionControlComponent # TBD: Update only on successful interaction or always?
		self.startCooldown()
		return result
	else:
		if shouldCooldownOnFailure:
			self.startCooldown(cooldownOnFailure)
		return false


## Calls [method InteractionControlComponent.interact] is called again on [member previousInteractor]
## May be overridden by subclasses such as [TextInteractionComponent] to add further checks on whether to repeat or not.
func repeatPreviousInteraction() -> Variant:
	if debugMode: printLog(str("repeatPreviousInteraction() with: ", previousInteractor))
	if is_instance_valid(previousInteractor): return previousInteractor.interact(self)
	else: return null

#endregion


#region Cooldown

## Resets [member canSkipCurrentCooldown] and calls [method CooldownTimer.startCooldown]
func startCooldown(overrideTime: float = cooldownTimer.cooldownSeconds, restartIfOnCooldown: bool = false) -> void:
	self.canSkipCurrentCooldown = false # TBD: Should this be in onCooldownTimer_didStartCooldown()?
	cooldownTimer.startCooldown(overrideTime, restartIfOnCooldown)


## Calls [method CooldownTimer.finishCooldown]
func finishCooldown() -> void:
	# TBD: Check `canSkipCurrentCooldown` on finish?
	cooldownTimer.finishCooldown()


## Calls [method updateIndicator] if [member shouldModifyIndicatorInCooldown]
func onCooldownTimer_didStartCooldown(time: float) -> void:
	if shouldModifyIndicatorInCooldown: updateIndicator()
	self.didStartCooldown.emit(time)


## Calls [method updateIndicator] then if [member shouldRepeatInteractionAfterCooldown], calls [method repeatPreviousInteraction]
func onCooldownTimer_didFinishCooldown() -> void:
	updateIndicator() # NOTE: Restoration should not depend on `shouldModifyIndicatorInCooldown`
	if shouldRepeatInteractionAfterCooldown: repeatPreviousInteraction() # Again again!?
	self.didFinishCooldown.emit()

#endregion
