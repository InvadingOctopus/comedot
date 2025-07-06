## A subclass of [InteractionComponent] with a cooldown and a [Stat] cost.
## To edit the cooldown [Timer], enable "Editable Children"
## TIP: To display text bubbles for [Stat] deduction, use [StatsVisualComponent].

class_name InteractionWithCostComponent
extends InteractionComponent

# DESIGN: Perform Stat-checking in requestToInteract() and deduction in performInteraction() and leave checkInteractionConditions() as a virtual method for game-specific subclassed.


#region Parameters
const cooldownOnFailure: float = 0.5
@export var cost: StatCost ## The [Stat] cost.
@export var shouldCooldownOnFailure: bool = true ## If `true` then there is a short delay in case of a failed [Payload] (but not on insufficient [member cost] payment), to prevent UI/network spamming etc.
#endregion


#region Dependencies
@onready var cooldownTimer: Timer = $CooldownTimer
#endregion


func _ready() -> void:
	# NOTE: If our label property is empty, save any existing text as the default so we can restore it after the cooldown is over
	if interactionIndicator is Label and self.labelText.is_empty():
		self.labelText = interactionIndicator.text

	super._ready()


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
	updateLabel()


#region Interaction Interface

## Called by an [InteractionControlComponent].
## When the player presses the Interact button, the [InteractionControlComponent] checks its conditions then calls this method on the [InteractionComponent](s) in range.
## Then this [InteractionWithCostComponent] checks its own conditions (such as whether the player has key to open a door, or the energy to chop a tree).
func requestToInteract(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	if not isEnabled or not is_zero_approx(cooldownTimer.time_left): return false

	var statsComponent:	 StatsComponent = interactorEntity.getComponent(StatsComponent) as StatsComponent
	var isStatsComponentValidated: bool

	if self.cost:
		isStatsComponentValidated = cost.validateStatsComponent(statsComponent) if statsComponent else false
		if not isStatsComponentValidated:
			var bubble: GameplayResourceBubble = GameplayResourceBubble.create(self.cost.costStat, " LOW", interactorEntity)
			bubble.modulate = Color.RED
			# TBD: bubble.ui.label.label_settings.outline_size = 3
			Animations.blink(bubble)
	else: # If there is no cost, any offer is valid!
		isStatsComponentValidated = true

	if debugMode: printDebug(str("requestToInteract() cost: ", cost, ", statsComponent: ", statsComponent.logNameWithEntity, " ", isStatsComponentValidated))

	var isInteractionApproved: bool = checkInteractionConditions(interactorEntity, interactionControlComponent)

	if isStatsComponentValidated and isInteractionApproved:
		return true
	else:
		didDenyInteraction.emit(interactorEntity)
		return false


## Deducts the [member cost] then executes the [member payload], passing this [InteractionWithCostComponent] as the `source` of the [Payload], and the [param interactorEntity] as the `target`.
## May be overridden by a subclass to perform custom actions.
## Returns: The result of [method Payload.execute] or `false` if the [member payload] is missing.
func performInteraction(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> Variant:
	if debugMode: printDebug(str("performInteraction() interactorEntity: ", interactorEntity, "interactionControlComponent: ", interactionControlComponent, ", isEnabled: ", isEnabled, ", cost: ", cost, ", cooldown: ", cooldownTimer.time_left))
	if not isEnabled or not is_zero_approx(cooldownTimer.time_left): return false

	# NOTE: DESIGN: AWESOME: Sometimes there may be interactions that fail, such as a [StatModifierPayload] skipping a [Stat] that is already maxed out.
	# But we cannot know the `result` of a Payload before it executes.
	# In that case, the Stat cost must be refunded.

	var statsComponent: StatsComponent = interactorEntity.getComponent(StatsComponent) as StatsComponent
	var didPayCost:  bool
	var paymentStat: Stat

	if self.cost:
		paymentStat = cost.getPaymentStatFromStatsComponent(statsComponent)
		# NOTE: DESIGN: We have to deduct the [Stat] before executing the Payload, in case the Payload depends on the actual value of the [Stat],
		# so we CANNOT just proxy the cost and only modify the [Stat] if the Payload's result is a success. :')
		paymentStat.shouldSkipEmittingNextChange = true # Suppress superfluous [StatsVisualComponent] animations etc. in case there is a refund later.
		didPayCost = cost.deductCostFromStat(paymentStat) if statsComponent else false
	else: # If there is no cost, any offer is valid!
		didPayCost = true

	if didPayCost:
		var paidCost:	int = cost.cost
		var result: Variant = super.performInteraction(interactorEntity, interactionControlComponent)

		if  Tools.checkResult(result):
			paymentStat.emit_changed() # In case we skipped the previous deduction :)
			cooldownTimer.start()

		elif paymentStat: # Refund the cost if the interaction failed
			if debugMode: printDebug(str("Payload: ", payload, ", result: ", result, " failed; refunding ", paidCost, " → ", paymentStat.logName))
			paymentStat.shouldSkipEmittingNextChange = true # Suppress superfluous [StatsVisualComponent] animations etc.
			paymentStat.value += paidCost
			if shouldCooldownOnFailure: cooldownTimer.start(cooldownOnFailure)

		updateLabel()
		return result
	else:
		return false

#endregion
