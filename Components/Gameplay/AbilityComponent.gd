## Stores a list of special gameplay abilities which an Entity such as the player character or an NPC may explicitly choose to perform.
## Abilities may be special skills/spells like "Fireball", or trivial commands like "Examine".
## An Ability may cost a [Stat] Resource when used and may require a target to be chosen.
## To perform an Ability in response to player control, use [AbilityControlComponent].
## To display UI buttons for Abilities, use [AbilityButton] & [AbilityButtonsList].
## TIP: To execute Abilities via keyboard shortcuts or gamepad buttons, edit the Project Settings' Input Map,
## and add Godot input actions with names matching [member GlobalInput.Actions.abilityPrefix] + [member Ability.name] e.g. `ability_dash`.
## Requirements: [StatsComponent] to perform Abilities which have a Stat cost.

class_name AbilityComponent
extends Component

# TBD: Reset cooldowns for each Ability when its added to this component?


#region Parameters
@export var abilities: Array[Ability] ## The list of available [Ability]s that the Entity may choose to perform.
@export var isEnabled: bool = true
#endregion


#region State
@export_storage var abilitiesOnCooldown: Array[Ability]
#endregion


#region Signals

## Emitted if the [Ability] [member Ability.requiresTarget] but a target has not been provided for [method performAbility].
## Handled by [AbilityControlComponent] to provide game-specific UI for prompting the player to choose a target for the Ability.
## NOTE: If an Ability is to be performed via this component's [method performAbility] then this signal is emitted by the [AbilityComponent] ONLY; [signal Ability.didRequestTarget] will NOT be emitted.
signal didRequestTarget(ability: Ability, source: Entity)

signal willPerformAbility(ability: Ability)
signal didPerformAbility(ability: Ability, result: Variant)

#endregion


#region Dependencies
@onready var statsComponent: StatsComponent = coComponents.get(&"StatsComponent")
#endregion


func _ready() -> void:
	createCooldownsList() # Check if any Abilities were already in cooldown when they were added to this component
	connectSignals() # Then connect signals for future cooldown updates


#region Interface

## Returns the first [Ability] with the matching name from the [member abilities] array.
func findAbility(nameToSearch: StringName) -> Ability:
	# TBD: Use `Array.any()`?
	# TBD: PERFORMANCE: Use a Dictionary to cache Name:Ability?
	# TBD: PERFORMANCE: Should we to_lower() to avoid any typo bugs? Or is that a bad idea for StringName?

	for ability in self.abilities:
		if ability.name == nameToSearch: return ability

	printDebug("Cannot find Ability named: " + nameToSearch)
	return null


## Returns an [Ability] that matches an [InputEvent] shortcut.
## i.e. the first [Ability] from this component's [member abilities] array where
## [member GlobalInput.Actions.abilityPrefix] + [member Ability.name] returns `true` for [method InputEvent.is_action]
## For example `ability_dash`.
## This method is called by [AbilityControlComponent] to handle keyboard/gamepad/etc. shortcuts for special Abilities.
func findAbilityForInputEvent(inputEvent: InputEvent) -> Ability:
	# NOTE: GRR: Dummy Godot does not seem to have a way to get all the matching Godot Input Action from an InputEvent,
	# so we have to try all the [special/explicit] Abilities we have and ask Godot whether an InputEvent matches any of them.

	if debugMode: printDebug(str("findAbilityForInputEvent(): ", inputEvent))
	var inputActionName: StringName
	for ability in self.abilities:
		inputActionName = GlobalInput.Actions.abilityPrefix + ability.name
		if InputMap.has_action(inputActionName) and inputEvent.is_action(inputActionName): # Check InputMap.has_action() to avoid a dumb Godot error
			if debugMode: printDebug(str("First match: ", ability.logName))
			return ability
	return null


## Performs an [Ability] and returns the result of it's [member Ability.payload], or `false` if the Ability does not exist or cannot be performed: i.e. a required [param target] is missing or if [method Ability.checkUsability] fails.
## To perform Abilities in response to player control and handle targeting, use [AbilityControlComponent].
func performAbility(abilityName: StringName, target: Entity = null) -> Variant:
	# TBD: PERFORMANCE: Use a Dictionary to cache Name:Ability?
	# TBD: PERFORMANCE: Should we to_lower() to avoid any typo bugs? Or is that a bad idea for StringName?
	if not isEnabled: return false

	# First off, see if the requested Ability is available
	var abilityToPerform: Ability = self.findAbility(abilityName)
	if debugMode: printLog(str("performAbility(): ", abilityName, " (", abilityToPerform.logName if abilityToPerform else "NOT FOUND", ") target: ", target))
	if not abilityToPerform: return false

	# Next, if the Ability has any associated cost, get the Stat to pay that cost
	var statToPayWith: Stat
	if abilityToPerform.hasCost:
		statToPayWith = abilityToPerform.getPaymentStatFromStatsComponent(statsComponent)
		if not statToPayWith: # `null` Stat while `hasCost` means a payment failure
			if debugMode: printLog(str("abilityToPerform.getPaymentStatFromStatsComponent() can't find Stat ", abilityToPerform.costStatName, " in ", statsComponent))
			return false

	# NOTE: Make sure the Ability can be performed with the current state and parameters,
	# BEFORE choosing a target, in case the targeting UI has side-effects etc.
	if not abilityToPerform.checkUsability(self.entity, target, statToPayWith):
		return false

	# If the Ability requires a target and we haven't been provided one,
	# let the UI prompt the player for a target.
	if abilityToPerform.requiresTarget and target == null:
		if debugMode: printDebug("Missing target")
		self.didRequestTarget.emit(abilityToPerform, self.entity) # To be handled by AbilityControlComponent
		GlobalUI.abilityDidRequestTarget.emit(abilityToPerform, self.entity) # This should be emitted here next to `didRequestTarget` as this is the first point where a target is requested, not AbilityControlComponent.
		# TBD: ALSO emit the Ability's signal?
		# What would be the behavior expected by objects connecting to these signals? If an AbilityControlComponent is used, then it is the AbilityControlComponent requesting a target, right? The Ability should not also request a target, to avoid UI duplication, right?
		return false

	# Alakazam!
	self.willPerformAbility.emit(abilityToPerform)
	var result: Variant = abilityToPerform.perform(self.entity, target, statToPayWith)

	# Check the result
	# NOTE: If the Ability's Payload fails the Stat cost is refunded by Ability.perform()
	if Tools.checkResult(result): # Must not be `null` and not `false` and not an empty collection
		self.didPerformAbility.emit(abilityToPerform, result)

	return result

#endregion


#region Cooldowns

## Resets the [member abilitiesOnCooldown] array and checks each [Ability] in the [member abilities] array,
## adding it to [member abilitiesOnCooldown] if [member Ability.isOnCooldown].
## The cooldowns list is used by [method _process] to countdown the cooldown time of each Ability on every frame.
func createCooldownsList() -> void:
	# TBD: Reset cooldowns for each Ability when its added?
	self.abilitiesOnCooldown.clear()
	for ability in self.abilities:
		if ability.isOnCooldown: self.abilitiesOnCooldown.append(ability)
	self.set_process(not self.abilitiesOnCooldown.is_empty()) # PERFORMANCE: Update per-frame only if needed


func connectSignals() -> void:
	for ability in self.abilities:
		Tools.connectSignal(ability.didStartCooldown,  self.onAbility_didStartCooldown.bind(ability))
		Tools.connectSignal(ability.didFinishCooldown, self.onAbility_didFinishCooldown.bind(ability))


func onAbility_didStartCooldown(ability: Ability) -> void:
	self.abilitiesOnCooldown.append(ability)
	self.set_process(true) # Start per-frame updates


func onAbility_didFinishCooldown(ability: Ability) -> void:
	self.abilitiesOnCooldown.erase(ability)
	if self.abilitiesOnCooldown.is_empty(): self.set_process(false) # PERFORMANCE: Do not update per-frame anymore


func _process(delta: float) -> void:
	# NOTE: PERFORMANCE: Update per-frame only when needed: Call `self.set_process()` whenever `abilitiesOnCooldown` is modified.
	if not isEnabled or self.abilitiesOnCooldown.is_empty(): return
	for ability in abilitiesOnCooldown:
		ability.cooldownRemaining -= delta

#endregion
