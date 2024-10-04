# meta-default: true

## A script called by a [ScriptPayload] when a [CollectibleComponent] is collected by a [CollectorComponent].

extends GDScript


@warning_ignore("unused_parameter")
static func onPayload_didExecute(payload: Payload, source: CollectibleComponent, target: Entity) -> Variant:
	# Function entry logging done in ScriptPayload.executeImplementation()
	return false
