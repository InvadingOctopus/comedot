## A subclass of [ActionTargetableComponent] that performs its own [Payload] effect in response to being chosen for an [Action].
## May be used to implement "passive" [Action]s that do not have any effect of their own,
## or generic commands where the effect is different depending on the target object, such as a hypothetical "Activate" or "Switch on" Action.
## To implement a targeting UI on the Entity that initiates an [Action], use [ActionTargetingComponentBase].

class_name ActionReactionComponent
extends ActionTargetableComponent


#region Parameters
## A [Dictionary] of code to execute when this component is targeted by an [Action]. See [Payload] for explanation and available options.
## IMPORTANT: The keys must match each [member Action.name].
@export var payloads: Dictionary[StringName, Payload] # TBD: Should the keys be StringName or Action?

## The [Payload] to execute for ANY [Action] IF there is no matching [member Action.name] key in [member payloads].
@export var fallbackPayload: Payload
#endregion


#region Signals
signal willExecutePayload(payload: Payload, action: Action, sourceEntity: Entity)
signal didExecutePayload(payload: Payload,  action: Action, sourceEntity: Entity, result: Variant)
#endregion


## May be called by an [ActionTargetingComponent].
func requestToChoose(action: Action = null, sourceEntity: Entity = null) -> bool:
	# TBD: Use Action StringName or the direct instance?
	# DESIGN: Using actual Action instances may cause problems if different entities use different instances of the same Action with the same name, e.g. to keep track of different cooldowns etc.

	var payload: Payload = self.payloads.get(action.name)

	if not payload:
		if fallbackPayload:
			payload = fallbackPayload
			if debugMode: printLog(str("requestToChoose(): No payload for Action name: " + action.name, ", using fallback: ", fallbackPayload.logName))
		else:
			printWarning("requestToChoose(): No payload or fallback for Action name: " + action.name)
			return false

	if debugMode: printLog(str("requestToChoose() action: ", action.logName, ", sourceEntity: ", sourceEntity.logFullName, ", payload: ", payload.logName))

	if checkConditions(action, sourceEntity):
		self.wasChosen.emit(action, sourceEntity)
		self.willExecutePayload.emit(payload, action, sourceEntity)
		var result: Variant = payload.execute(sourceEntity, self.parentEntity) # TBD: Should `source` be the Action or the source Entity?
		self.didExecutePayload.emit(payload, action, sourceEntity, result)
		return result
	else:
		if debugMode: printLog("checkConditions() failed.")
		return false
