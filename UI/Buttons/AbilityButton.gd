## Displays a button for one of the [Ability]s that a playable character may perform.
## @experimental

class_name AbilityButton
extends Button

# TBD: Use `ability.name` to search within an `AbilityComponent`?


#region Parameters

## An [Entity] with an [AbilityComponent] and [StatsComponent].
## If `null`, the first [member GameState.players] Entity will be used.
@export var entity: Entity

@export var ability: Ability:
	set(newValue):
		if newValue != ability:
			# TBD: Disconnect signals from previous Ability?
			ability = newValue
			if self.is_node_ready():
				# CHECK: Are we calling these functions multiple times during initialization?
				getPaymentStat() # Get the new [member StatDependentResourceBase.costStat] match from the [statsComponent]
				connectSignals() # Reconnect in case it's a new/different Ability
				updateUI()

@export var shouldShowTargetPrompt: bool = true
@export var debugMode: bool

#endregion


#region Dependencies

var player: Entity: # PlayerEntity or TurnBasedPlayerEntity
	get: return GameState.players.front()

var abilityComponent: AbilityComponent:
	get:
		if   not entity: abilityComponent = null
		elif not abilityComponent: abilityComponent = entity.getComponent(AbilityComponent)
		return abilityComponent

var statsComponent: StatsComponent:
	get:
		if   not entity: statsComponent = null
		elif not statsComponent: statsComponent = entity.getComponent(StatsComponent)
		return statsComponent

var paymentStat: Stat: # Monitor the mana/gold/etc. value for changes and update the Button accordingly
	set(newValue):
		if newValue != paymentStat:
			# Stop watching the previous Stat if any
			if paymentStat: Tools.disconnectSignal(paymentStat.changed, self.onPaymentStat_changed)
			paymentStat = newValue
			# Monitor the new Stat to disable/enable the Button when the value changes
			if paymentStat: Tools.connectSignal(paymentStat.changed, self.onPaymentStat_changed)
			
@onready var cooldownBar: ProgressBar = $CooldownBar

#endregion


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not entity:
		entity = player
		if not entity: Debug.printWarning("Missing entity", self)

	if ability:
		getPaymentStat()
		connectSignals()
		updateUI()

	self.set_process(false) # PERFORMANCE: Update per-frame only when needed


## Queries the [member statsComponent] to get the [Stat] that matches the [Ability]'s [member StatDependentResourceBase.costStat]
## The [member Stat.value] is monitored to disable/enable this [Button] as the amount of mana/gold/enegery/etc. changes.
func getPaymentStat() -> Stat:
	if ability and ability.hasCost and statsComponent: paymentStat = ability.getPaymentStatFromStatsComponent(statsComponent)
	else: paymentStat = null
	return paymentStat


func updateUI() -> void:
	self.text = ability.displayName \
		+ (str("\n[", ability.usesRemaining, "]") if ability.hasFiniteUses else "")
	self.icon = ability.icon
	self.tooltip_text = ability.description
	self.disabled = not checkUsability()
	updateCooldown()


func updateCooldown() -> void:
	# TBD: PERFORMANCE: Just check ability.isOnCooldown or avoid property access/temporary variable creation for some reason? :')
	var isOnCooldown: bool = ability.cooldownRemaining > 0 or not is_zero_approx(ability.cooldownRemaining) # Multiple checks in case of float funkery
	
	cooldownBar.max_value = ability.cooldown
	cooldownBar.value	= ability.cooldownRemaining if isOnCooldown else 0.0 # Snap to 0 to avoid float funkery
	cooldownBar.visible	= isOnCooldown
	self.disabled		= not checkUsability()
	self.set_process(isOnCooldown) # PERFORMANCE: Update per-frame only when needed


## Checks if the [member entity]'s [StatsComponent] has the [Stat] required to perform the [member ability].
## WARNING: May not be updated accurately if the "payment" Stat changes outside the monitored signals/events.
func checkUsability() -> bool:
	return entity and ability and ability.isReady \
		and (not ability.hasCost or ability.validateStatsComponent(statsComponent))


#region Events

func connectSignals() -> void:
	Tools.connectSignal(ability.didDecreaseUses,   self.onAbility_didDecreaseUses)
	Tools.connectSignal(ability.didStartCooldown,  self.onAbility_didStartCooldown)
	Tools.connectSignal(ability.didFinishCooldown, self.onAbility_didFinishCooldown)

	Tools.connectSignal(GlobalUI.abilityIsChoosingTarget, self.onGlobalUI_abilityIsChoosingTarget)
	Tools.connectSignal(GlobalUI.abilityDidChooseTarget,  self.onGlobalUI_abilityDidChooseTarget)
	Tools.connectSignal(GlobalUI.abilityDidCancelTarget,  self.onGlobalUI_abilityDidCancelTarget)


func onPaymentStat_changed() -> void:
	self.disabled = not self.checkUsability()


func onPressed() -> void:
	if debugMode: Debug.printDebug("onPressed()", self)
	generateInputEvent()


## Generates a "fake" [InputEventAction] with the [member Ability.name] of the [member ability] prefixed with [member GlobalInput.Actions.abilityPrefix].
## This [InputEventAction] may then be processed by any Component or other class as any other [method _input] event.
func generateInputEvent() -> void:
	GlobalInput.generateInputEvent(GlobalInput.Actions.abilityPrefix + self.ability.name)


func onAbility_didDecreaseUses() -> void:
	updateUI()


func onAbility_didStartCooldown() -> void:
	updateCooldown()


func onAbility_didFinishCooldown() -> void:
	updateCooldown()


func onGlobalUI_abilityIsChoosingTarget(eventAbility: Ability, _source: Entity) -> void:
	if eventAbility == self.ability:
		self.disabled = true
		if shouldShowTargetPrompt: TextBubble.create("Choose target", self, Vector2(self.size.x / 2, 0)) # Position the Bubble at the center of this Button


func onGlobalUI_abilityDidChooseTarget(eventAbility: Ability, _source: Entity, _target: Variant) -> void:
	if eventAbility == self.ability: self.disabled = not checkUsability()


func onGlobalUI_abilityDidCancelTarget(eventAbility: Ability, _source: Entity) -> void:
	if eventAbility == self.ability: self.disabled = not checkUsability()


func _process(_delta: float) -> void:
	# PERFORMANCE: Update per-frame only when needed: Call `self.set_process()` whenever the Ability starts or ends its cooldown.
	if ability.cooldownRemaining > 0:
		cooldownBar.value = ability.cooldownRemaining

#endregion
