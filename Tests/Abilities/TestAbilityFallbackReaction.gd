## An example script called by the [ScriptPayload] of an [AbilityReactionComponent]'s [member AbilityReactionComponent.fallbackPayload].

extends GDScript


## NOTE: [AbilityReactionComponent] calls [method Payload.execute] with these arguments:
## ([sourceEntity, ability, abilityResult], AbilityReactionComponent's entity)
static func onPayload_didExecute(payload: Payload, source: Variant, target: Entity) -> Variant:
	# Function entry logging done in ScriptPayload.executeImplementation()
	GlobalUI.createTemporaryLabel(str("Fallback Payload: ", payload.logName, "\nsource: ", source, "\ntarget: ", target)) \
		.label_settings.font_color = Color.YELLOW
	return true
