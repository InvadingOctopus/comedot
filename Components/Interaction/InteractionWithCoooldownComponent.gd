## A subclass of [InteractionComponent] with a cooldown [Timer]].
## To edit the cooldown [Timer], enable "Editable Children"

class_name InteractionWithCooldownComponent
extends InteractionComponent

# TBD: Abstract functions for cooldown start/end?


#region Parameters

@export var shouldCooldownOnFailure: bool = true ## If `true` then there is a short delay in case of a failed [Payload] (but not on insufficient [member cost] payment), to prevent UI/network spamming etc.
@export_range(0.0, 60.0, 0.1) var cooldownOnFailure: float = 0.5

## If `true` then [method InteractionControlComponent.interact] is called again on [member previousInteractor] after the cooldown [Timer] finishes.
## TIP: May be useful for auto-advancing a [TextInteractionComponent] for simple NPC dialogue etc.
## TIP: Set [member shouldSkipInteractorCooldown] to ensure that the [InteractionControlComponent] is not in cooldown when this [InteractionWithCooldownComponent] comes out of cooldown.
@export var shouldRepeatInteractionAfterCooldown: bool = false
@export var shouldModifyIndicatorInCooldown:	  bool = true  ## If `true` then the [member interactionIndicator] is dimmed and modified during a cooldown.

#endregion


#region State
## Updated on a successful [method performInteraction] and used for [member shouldRepeatInteractionAfterCooldown].
## IMPORTANT: MUST be updated by subclasses that override [method performInteraction].
@export_storage var previousInteractor: InteractionControlComponent
#endregion


#region Signals
signal didStartCooldown(time: float) ## ALERT: NOT emitted if [method Timer.start] is called manually on [member cooldownTimer].
signal didFinishCooldown
#endregion


#region Dependencies
@onready var cooldownTimer: Timer = $CooldownTimer
#endregion


func updateLabel() -> void:
	# TBD: Modify Label only on startCooldown() or hijack this method?
	# CONCERN: If only on startCooldown(), then a manual Timer.start() would skip the UI update, because Timer does not have a "start" signal :'(
	if not shouldModifyIndicatorInCooldown:
		super.updateLabel()
		return

	if not interactionIndicator: return

	# Just modify `self_modulate` alpha to avoid disrupting any existing `modulate` tints
	# NOTE: DESIGN: Modifying `visible` is problematic because making it visible onCooldownTimer_timeout() would cause it to reappear even if there is no [InteractionControlComponent] in contact.
	interactionIndicator.self_modulate = Color(interactionIndicator.self_modulate, 1.0) if is_zero_approx(cooldownTimer.time_left) else Color(interactionIndicator.self_modulate, 0.25)

	if interactionIndicator is Label:
		if is_zero_approx(cooldownTimer.time_left):
			if not self.labelText.is_empty(): interactionIndicator.text = self.labelText
		else:
			interactionIndicator.text = "COOLDOWN"


#region Cooldown
# Yes, some code duplication from CooldownComponent because Godon't have interface/protocols :')

## Starts the cooldown delay and dims the [member interactionIndicator] if it's a [Label].
func startCooldown(overrideTime: float = cooldownTimer.wait_time) -> void:
	# TBD: PERFORMANCE: Do we really need all this crap just for a simple Timer.start()?
	# Or could the `didStartCooldown` signal be helpful in chaining with other components e.g. for animations etc.?

	if debugMode:
		printDebug(str("startCooldown(): ", overrideTime))
		emitDebugBubble(str("CD:", overrideTime))

	if overrideTime > 0 and not is_zero_approx(overrideTime): # Avoid the annoying Godot error: "Time should be greater than zero."
		var previousTime: float = cooldownTimer.wait_time # Save the "actual" cooldown because Timer.start(overrideTime) modifies Timer.wait_time
		cooldownTimer.start(overrideTime)
		cooldownTimer.wait_time = previousTime # Restore the default cooldown
		didStartCooldown.emit(overrideTime)
	else: # If the time is too low, run straight to the finish
		finishCooldown() # TBD: CHECK: BUGCHANCE: Could this cause problems with `shouldRepeatInteractionAfterCooldown`?

	if shouldModifyIndicatorInCooldown: updateLabel()


## Called when the cooldown [Timer] is over. Updates the [member interactionIndicator] if it's a [Label].
func finishCooldown() -> void:
	if debugMode: printDebug("finishCooldown()")
	cooldownTimer.stop()
	updateLabel() # NOTE: Restoration should not depend on `shouldModifyIndicatorInCooldown`
	didFinishCooldown.emit()

	# Again again!?
	if shouldRepeatInteractionAfterCooldown: repeatPreviousInteraction()

#endregion


#region Interaction Interface

## Extends [method InteractionComponent.requestToInteract] to include a cooldown [Timer] check.
## NOTE: Does NOT emit [signal didDenyInteraction] when on cooldown.
func requestToInteract(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	# TBD: Emit `didDenyInteraction` when on cooldown?
	if not isEnabled or not is_zero_approx(cooldownTimer.time_left): return false
	return super.requestToInteract(interactorEntity, interactionControlComponent)


## Extends [method performInteraction] to start a cooldown [Timer] after an interaction.
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> Variant:
	if debugMode: printDebug(str("performInteraction() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent, ", isEnabled: ", isEnabled, ", cooldown: ", cooldownTimer.time_left))
	if not isEnabled or not is_zero_approx(cooldownTimer.time_left): return false

	var result: Variant = super.performInteraction(interactorEntity, interactionControlComponent)

	if Tools.checkResult(result):
		previousInteractor = interactionControlComponent # TBD: Update only on successful interaction or always?
		startCooldown()
		return result
	else:
		if shouldCooldownOnFailure:
			startCooldown(cooldownOnFailure)
		return false


## Calls [method InteractionControlComponent.interact] is called again on [member previousInteractor]
## May be overridden by subclasses such as [TextInteractionComponent] to add further checks on whether to repeat or not.
func repeatPreviousInteraction() -> Variant:
	if debugMode: printLog(str("repeatPreviousInteraction() with: ", previousInteractor))
	if is_instance_valid(previousInteractor): return previousInteractor.interact(self)
	else: return null

#endregion
