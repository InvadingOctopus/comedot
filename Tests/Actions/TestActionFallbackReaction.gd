## An example script called by the [ScriptPayload] of a [ActionReactionComponent]'s [member ActionReactionComponent.fallbackPayload].

extends GDScript


static func onPayload_didExecute(payload: Payload, source: Entity, target: Entity) -> Variant:
	# Function entry logging done in ScriptPayload.executeImplementation()
	GlobalUI.createTemporaryLabel(str("Fallback Payload: ", payload.logName, "\nsource: ", source, "\ntarget: ", target)) \
		.label_settings.font_color = Color.YELLOW
	return true
