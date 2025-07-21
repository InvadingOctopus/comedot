## An example script called by the [ScriptPayload] of a [ActionReactionComponent]
## when it's chosen as the target of a "Look" [Action].

extends GDScript


static func onPayload_didExecute(_payload: Payload, source: Entity, _target: Entity) -> Variant:
	# Function entry logging done in ScriptPayload.executeImplementation()
	GlobalUI.createTemporaryLabel(str("I was looked at by ", source)) \
		.label_settings.font_color = Color.CYAN
	return true
