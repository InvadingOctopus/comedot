## An example script called by the [ScriptPayload] of a [ActionReactionComponent]'s [member ActionReactionComponent.fallbackPayload].

extends GDScript


## NOTE: [ActionReactionComponent] calls [method Payload.execute] with these arguments:
## ([sourceEntity, action, actionResult], ActionReactionComponent's parentEntity)
static func onPayload_didExecute(payload: Payload, source: Variant, target: Entity) -> Variant:
	# Function entry logging done in ScriptPayload.executeImplementation()
	GlobalUI.createTemporaryLabel(str("Fallback Payload: ", payload.logName, "\nsource: ", source, "\ntarget: ", target)) \
		.label_settings.font_color = Color.YELLOW
	return true
