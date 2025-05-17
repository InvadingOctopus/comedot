## A subclass of [InteractionComponent] with a cooldown and a [Stat] cost.
## To edit the cooldown [Timer], enable "Editable Children"

class_name InteractionWithCostComponent
extends InteractionComponent

# DESIGN: Perform Stat-checking in requestToInteract() and deduction in performInteraction() and leave checkInteractionConditions() as a virtual method for game-specific subclassed.


#region Parameters
@export var cost: StatDependentResourceBase ## The [Stat] cost.
#endregion


#region Dependencies
@onready var cooldownTimer: Timer = $CooldownTimer
#endregion


func _ready() -> void:
	# NOTE: If our label property is empty, save any existing text as the default so we can restore it after the cooldown is over
	if interactionIndicator is Label and self.label.is_empty():
		self.label = interactionIndicator.text

	super._ready()


func updateLabel() -> void:
	# OVERRIDE: super.updateLabel()
	if not interactionIndicator: return

	# Just modify `self_modulate` alpha to avoid disrupting any existing `modulate` tints
	# NOTE: DESIGN: Modifying `visible` is problematic because making it visible onCooldownTimer_timeout() would cause it to reappear even if there is no [InteractionControlComponent] in contact.
	interactionIndicator.self_modulate = Color(interactionIndicator.self_modulate, 1.0) if is_zero_approx(cooldownTimer.time_left) else Color(interactionIndicator.self_modulate, 0.25)

	if interactionIndicator is Label:
		if is_zero_approx(cooldownTimer.time_left):
			if not self.label.is_empty(): interactionIndicator.text = self.label
		else:
			interactionIndicator.text = "COOLDOWN"


## Called by an [InteractionControlComponent].
## When the player presses the Interact button, the [InteractionControlComponent] checks its conditions then calls this method on the [InteractionComponent](s) in range.
## Then this [InteractionWithCostComponent] checks its own conditions (such as whether the player has key to open a door, or the energy to chop a tree).
func requestToInteract(interactorEntity: Entity, interactionControlComponent: InteractionControlComponent) -> bool:
	if not isEnabled or not is_zero_approx(cooldownTimer.time_left): return false

	var statsComponent:	 StatsComponent = interactorEntity.getComponent(StatsComponent) as StatsComponent
	var isStatsComponentValidated: bool

	if self.cost:
		isStatsComponentValidated = cost.validateStatsComponent(statsComponent) if statsComponent else false
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

	var statsComponent: StatsComponent = interactorEntity.getComponent(StatsComponent) as StatsComponent
	var didPayCost: bool

	if self.cost:
		didPayCost = cost.deductCostFromStat(cost.getPaymentStatFromStatsComponent(statsComponent)) if statsComponent else false
	else: # If there is no cost, any offer is valid!
		didPayCost = true

	if didPayCost:
		var result: Variant = super.performInteraction(interactorEntity, interactionControlComponent)
		if  result: cooldownTimer.start()
		updateLabel()
		return result
	else: return false


func onCooldownTimer_timeout() -> void:
	updateLabel()
