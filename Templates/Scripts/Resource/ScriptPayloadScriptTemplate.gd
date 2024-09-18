# meta-default: true

## A script for an [ScriptPayload] to execute.

extends Resource # TBD: Should the base be a `ScriptPayloadScript`? :)


static func onPayload_didExecute(source: Variant, target: Variant) -> Variant:
	Debug.printLog(str("onPayload_didExecute() source: ", source, ", target: ", target))
	return false
