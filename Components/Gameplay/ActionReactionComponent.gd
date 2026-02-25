## A subclass of [ActionTargetableComponent] that performs its own [Payload] effect in response to being chosen and targeted for an [Action].
## May be used to implement "passive" [Action]s that do not have any effect of their own,
## or generic commands where the effect is different depending on the target object, such as a hypothetical "Activate" or "Switch on" Action.
## TIP: To implement a targeting UI on the Entity that initiates an [Action], use [ActionTargetingComponentBase].

class_name ActionReactionComponent
extends ActionTargetableComponent

# TBD: Another Payload list for the initial choice of target, BEFORE an Action is executed?


#region Parameters
## A [Dictionary] of "reactions" to execute after an [Action] has been successfully executed with this component's entity as the Action's target. 
## IMPORTANT: The Payload's [method Payload.execute] method will be called with an array of [the source Entity, the Action, the action's result]
## IMPORTANT: The keys must match each [member Action.name].
## TIP: See [Payload] for explanation and available options.
@export var reactionPayloads: Dictionary[StringName, Payload] # TBD: Should the keys be StringName or Action?

## The [Payload] to execute for ANY [Action] IF there is no matching [member Action.name] key in [member reactionPayloads].
@export var fallbackPayload: Payload
#endregion


#region Signals
signal willExecutePayload(payload: Payload, action: Action, sourceEntity: Entity)
signal didExecutePayload (payload: Payload, action: Action, sourceEntity: Entity, reactionResult: Variant)
#endregion


## Fetches a [Payload] from the [members reactionPayloads] [Dictionary] that is associated with the supplied [Action] [member Action.name].
## If no matching Payload is found, the [member fallbackPayload] is returned, if any.
func getReactionPayloadForAction(action: Action) -> Payload:
	if not action:
		printWarning("getReactionPayloadForAction(): No action")
		return null

	# DESIGN: Use Action StringName, as comparing actual Action instances may cause problems if different entities use different instances of the same Action with the same name, e.g. to keep track of different cooldowns etc.
	var payload: Payload = self.reactionPayloads.get(action.name)

	if not payload:
		if fallbackPayload:
			payload = fallbackPayload
			if debugMode: printLog(str("requestToChoose(): No payload for Action name: " + action.name, ", using fallback: ", fallbackPayload.logName))
		else:
			printWarning("requestToChoose(): No payload or fallback for Action name: " + action.name)

	return payload


## May be called by an [ActionTargetingComponent] BEFORE an [Action]'s [Payload] is executed.
## Refuses to be chosen as the target of an Action if there is no matching "reaction" Payload assigned for that Action's name in the [member reactionPayloads] Dictionary.
func requestToChoose(action: Action = null, sourceEntity: Entity = null) -> bool:
	# DESIGN: `null` arguments may be allowed if they're not relevant
	if not isEnabled: return false

	# Check for a matching Payload first BEFORE checking for other conditions (which may be customized by subclasses)
	var payload: Payload = self.getReactionPayloadForAction(action)
	if debugMode: printLog(str("requestToChoose() action: ", (action.logName if action else "null"), ", sourceEntity: ", (sourceEntity.logFullName if sourceEntity else "none"), ", payload: ", payload.logName if payload else "NOT FOUND"))
	if not payload: return false

	if checkConditions(action, sourceEntity): # Arguments should be validated by checkConditions()
		self.wasChosen.emit(action, sourceEntity)
		return true
	else:
		if debugMode: printLog("checkConditions() failed.")
		return false


## May be called by an targeted [Action] AFTER the [Action]'s [Payload] is successfully executed.
## May optionally return the result of a "reaction" or just nothing etc.
## @experimental
func didTarget(action: Action, sourceEntity: Entity = null, actionResult: Variant = null) -> Variant:
	# DESIGN: `null` arguments may be allowed if they're not relevant
	if not isEnabled: return false

	var payload: Payload = self.getReactionPayloadForAction(action)
	if debugMode: printLog(str("didTarget() action: ", (action.logName if action else "null"), ", sourceEntity: ", (sourceEntity.logFullName if sourceEntity else "none"), ", payload: ", payload.logName if payload else "NOT FOUND"))
	if not payload: return false

	self.wasTargeted.emit(action, sourceEntity, actionResult) # Emit the "targeted" signal first,
	self.willExecutePayload.emit(payload, action, sourceEntity) # then the "reaction" signal

	var reactionResult: Variant = payload.execute([sourceEntity, action, actionResult], self.parentEntity) # TBD: Should `source` be the Action or the source Entity?

	if debugMode: printLog(str("didTarget() reactionResult: ", reactionResult))
	self.didExecutePayload.emit(payload, action, sourceEntity, reactionResult)
	return reactionResult
