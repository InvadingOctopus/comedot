# meta-default: true

## A script called by a [ScriptPayload] when it is executed by an [Action].

extends GDScript


@warning_ignore("unused_parameter")
static func onPayload_didExecute(payload: Payload, source: Entity, target: Entity) -> Variant:
	# Function entry logging done in ScriptPayload.executeImplementation()
	return false
