## An example script called by the [ScriptPayload] of an [AbilityReactionComponent]
## when it's chosen as the target of a "Look" [Ability].

extends GDScript


## NOTE: [AbilityReactionComponent] calls [method Payload.execute] with these arguments:
## ([sourceEntity, ability, abilityResult], AbilityReactionComponent's entity)
static func onPayload_didExecute(_payload: Payload, source: Variant, target: Entity) -> Variant:
	# Function entry logging done in ScriptPayload.executeImplementation()
	GlobalUI.createTemporaryLabel(str("I was looked at by ", source)) \
		.label_settings.font_color = Color.CYAN
	TextBubble.create("HI!", target)
	return true
