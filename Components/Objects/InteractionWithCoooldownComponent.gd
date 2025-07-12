## A subclass of [InteractionComponent] with a cooldown [Timer]].
## To edit the cooldown [Timer], enable "Editable Children"

class_name InteractionWithCooldownComponent
extends InteractionComponent

# TODO: Signals & abstract functions for cooldown start/end


#region Parameters
@export var shouldCooldownOnFailure: bool = true ## If `true` then there is a short delay in case of a failed [Payload] (but not on insufficient [member cost] payment), to prevent UI/network spamming etc.
@export_range(0.0, 60.0, 0.1) var cooldownOnFailure: float = 0.5
#endregion


#region Dependencies
@onready var cooldownTimer: Timer = $CooldownTimer
#endregion


func updateLabel() -> void:
	# OVERRIDE: super.updateLabel()
	if not interactionIndicator: return

	# Just modify `self_modulate` alpha to avoid disrupting any existing `modulate` tints
	# NOTE: DESIGN: Modifying `visible` is problematic because making it visible onCooldownTimer_timeout() would cause it to reappear even if there is no [InteractionControlComponent] in contact.
	interactionIndicator.self_modulate = Color(interactionIndicator.self_modulate, 1.0) if is_zero_approx(cooldownTimer.time_left) else Color(interactionIndicator.self_modulate, 0.25)

	if interactionIndicator is Label:
		if is_zero_approx(cooldownTimer.time_left):
			if not self.labelText.is_empty(): interactionIndicator.text = self.labelText
		else:
			interactionIndicator.text = "COOLDOWN"


func onCooldownTimer_timeout() -> void:
	if debugMode: emitDebugBubble("Cooldown Over")
	updateLabel()
	# TODO: Signal


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
		cooldownTimer.start()
		updateLabel()
		return result
	else:
		if shouldCooldownOnFailure:
			cooldownTimer.start(cooldownOnFailure)
			updateLabel()
		return false

#endregion
