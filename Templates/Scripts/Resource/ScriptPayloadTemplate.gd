# meta-default: true

## A script for a [ScriptPayload] to execute.

extends GDScript


@warning_ignore("unused_parameter")
static func onPayload_didExecute(payload: Payload, source: Variant, target: Variant) -> Variant: # `Variant` may be replaced by specific types such as `Entity` or `Component`.
	# Function entry logging done in ScriptPayload.executeImplementation()
	return false
