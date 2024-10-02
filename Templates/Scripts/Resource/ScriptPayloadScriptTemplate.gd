# meta-default: true

## A script for a [ScriptPayload] to execute.

extends Resource


static func onPayload_didExecute(payload: Payload, source: Variant, target: Variant) -> Variant:
	Debug.printLog(str("onPayload_didExecute() payload: ", payload, ", source: ", source, ", target: ", target))
	return false
