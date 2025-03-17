## A script called by a [ScriptPayload] when it is executed by an [Action].

extends GDScript


static func onPayload_didExecute(_payload: Payload, _source: Entity, target: Entity) -> Variant:
	# Function entry logging done in ScriptPayload.executeImplementation()
	GlobalUI.createTemporaryLabel(str("It looks like a ", target))
	return true
