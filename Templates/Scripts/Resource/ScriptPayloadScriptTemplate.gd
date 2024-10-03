# meta-default: true

## A script for a [ScriptPayload] to execute.

extends Resource


@warning_ignore("unused_parameter")
static func onPayload_didExecute(payload: Payload, source: Variant, target: Variant) -> Variant:
	# Function entry logging done in ScriptPayload.executeImplementation()
	return false
