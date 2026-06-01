## A subclass of [AbilityTargetableComponent] that performs its own [Payload] effect in response to being chosen and targeted for an [Ability].
## May be used to implement "passive" [Ability]s that do not have any effect of their own,
## or generic commands where the effect is different depending on the target object, such as a hypothetical "Activate" or "Switch on" Ability.
## TIP: To implement a targeting UI on the Entity that initiates an [Ability], use [AbilityTargetingComponentBase].

class_name AbilityReactionComponent
extends AbilityTargetableComponent

# TBD: Another Payload list for the initial choice of target, BEFORE an Ability is executed?


#region Parameters
## A [Dictionary] of "reactions" to execute after an [Ability] has been successfully executed with this component's entity as the Ability's target.
## IMPORTANT: The Payload's [method Payload.execute] method will be called with an array of [the source Entity, the Ability, the ability's result]
## IMPORTANT: The keys must match each [member Ability.name].
## TIP: See [Payload] for explanation and available options.
@export var reactionPayloads: Dictionary[StringName, Payload] # TBD: Should the keys be StringName or Ability?

## The [Payload] to execute for ANY [Ability] IF there is no matching [member Ability.name] key in [member reactionPayloads].
@export var fallbackPayload: Payload
#endregion


#region Signals
signal willExecutePayload(payload: Payload, ability: Ability, sourceEntity: Entity)
signal didExecutePayload (payload: Payload, ability: Ability, sourceEntity: Entity, reactionResult: Variant)
#endregion


## Fetches a [Payload] from the [members reactionPayloads] [Dictionary] that is associated with the supplied [Ability] [member Ability.name].
## If no matching Payload is found, the [member fallbackPayload] is returned, if any.
func getReactionPayloadForAbility(ability: Ability) -> Payload:
	if not ability:
		printWarning("getReactionPayloadForAbility(): No ability")
		return null

	# DESIGN: Use Ability StringName, as comparing actual Ability instances may cause problems if different entities use different instances of the same Ability with the same name, e.g. to keep track of different cooldowns etc.
	var payload: Payload = self.reactionPayloads.get(ability.name)

	if not payload:
		if fallbackPayload:
			payload = fallbackPayload
			if debugMode: printLog(str("requestToChoose(): No payload for Ability name: " + ability.name, ", using fallback: ", fallbackPayload.logName))
		else:
			printWarning("requestToChoose(): No payload or fallback for Ability name: " + ability.name)

	return payload


## May be called by an [AbilityTargetingComponentBase] subclass BEFORE an [Ability]'s [Payload] is executed.
## Refuses to be chosen as the target of an Ability if there is no matching "reaction" Payload assigned for that Ability's name in the [member reactionPayloads] Dictionary.
func requestToChoose(ability: Ability = null, sourceEntity: Entity = null) -> bool:
	# DESIGN: `null` arguments may be allowed if they're not relevant
	if not isEnabled: return false

	# Check for a matching Payload first BEFORE checking for other conditions (which may be customized by subclasses)
	var payload: Payload = self.getReactionPayloadForAbility(ability)
	if debugMode: printLog(str("requestToChoose() ability: ", (ability.logName if ability else "null"), ", sourceEntity: ", (sourceEntity.logFullName if sourceEntity else "none"), ", payload: ", payload.logName if payload else "NOT FOUND"))
	if not payload: return false

	if checkConditions(ability, sourceEntity): # Arguments should be validated by checkConditions()
		self.wasChosen.emit(ability, sourceEntity)
		return true
	else:
		if debugMode: printLog("checkConditions() failed.")
		return false


## May be called by an targeted [Ability] AFTER the [Ability]'s [Payload] is successfully executed.
## May optionally return the result of a "reaction" or just nothing etc.
## @experimental
func didTarget(ability: Ability, sourceEntity: Entity = null, abilityResult: Variant = null) -> Variant:
	# DESIGN: `null` arguments may be allowed if they're not relevant
	if not isEnabled: return false

	var payload: Payload = self.getReactionPayloadForAbility(ability)
	if debugMode: printLog(str("didTarget() ability: ", (ability.logName if ability else "null"), ", sourceEntity: ", (sourceEntity.logFullName if sourceEntity else "none"), ", payload: ", payload.logName if payload else "NOT FOUND"))
	if not payload: return false

	self.wasTargeted.emit(ability, sourceEntity, abilityResult) # Emit the "targeted" signal first,
	self.willExecutePayload.emit(payload, ability, sourceEntity) # then the "reaction" signal

	var reactionResult: Variant = payload.execute([sourceEntity, ability, abilityResult], self.entity) # TBD: Should `source` be the Ability or the source Entity?

	if debugMode: printLog(str("didTarget() reactionResult: ", reactionResult))
	self.didExecutePayload.emit(payload, ability, sourceEntity, reactionResult)
	return reactionResult
