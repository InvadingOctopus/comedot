## An example script called by the [ScriptPayload] of a "Look" [Action].

extends GDScript


static func onPayload_didExecute(_payload: Payload, _source: Entity, target: Entity) -> Variant:
	# Function entry logging done in ScriptPayload.executeImplementation()
	GlobalUI.createTemporaryLabel(str("It looks like a ", target))
	return true
