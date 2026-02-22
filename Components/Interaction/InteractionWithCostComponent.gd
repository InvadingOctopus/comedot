## A subclass of [InteractionWithCooldownComponent] with a [Stat] cost.
## To edit the cooldown [Timer], enable "Editable Children"
## TIP: To display text bubbles for [Stat] deduction, use [StatsVisualComponent].

class_name InteractionWithCostComponent
extends InteractionWithCooldownComponent

# DESIGN: Perform Stat-checking in requestToInteract() and deduction in performInteraction() and leave checkInteractionConditions() as a virtual method for game-specific subclassed.


#region Parameters
@export var cost: StatCost ## The [Stat] cost.
#endregion


#region Interaction Interface

## Overrides [InteractionControlComponent].
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

	if debugMode: printDebug(str("requestToInteract() cost: ", cost, ", statsComponent: ", statsComponent.logNameWithEntity if statsComponent else str(statsComponent), " ", isStatsComponentValidated))

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
		if not paymentStat:
			if debugMode: printDebug(str("performInteraction() cant find ", cost.costStatName, " in ", statsComponent))
			return false

		# NOTE: DESIGN: We have to deduct the [Stat] before executing the Payload, in case the Payload depends on the actual new value of the [Stat],
		# EXAMPLE: A card that costs mana to play but adds extra effects if the mana becomes 0.
		# so we CANNOT just "proxy" the cost and delay mutating the [Stat] until only when the Payload's result is a success :')
		# TODO: Find a way to suppress superfluous [StatsVisualComponent] animations etc. in case there is a refund later.
		# TRIED: WITHOUT "skipping signals" as a previous implementation tried; it was too confusing and inelegant.
		didPayCost = cost.deductCostFromStat(paymentStat) if statsComponent else false
	else: # If there is no cost, any offer is valid!
		didPayCost = true

	if didPayCost:
		var paidCost:	int = cost.cost
		var result: Variant = super.performInteraction(interactorEntity, interactionControlComponent)

		if  Tools.checkResult(result):
			previousInteractor = interactionControlComponent # TBD: Update only on successful interaction or always?
			startCooldown()

		elif paymentStat: # Refund the cost if the interaction failed
			if debugMode: printDebug(str("Payload: ", payload, ", result: ", result, " failed; refunding ", paidCost, " → ", paymentStat.logName))
			# TODO: Suppress superfluous [StatsVisualComponent] animations etc. in case of a refund
			paymentStat.value += paidCost
			if shouldCooldownOnFailure: startCooldown(cooldownOnFailure)

		updateIndicator()
		return result
	else:
		return false

#endregion
