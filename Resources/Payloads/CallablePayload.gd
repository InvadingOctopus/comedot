## A [Payload] which calls a function or method.

class_name CallablePayload
extends Payload


#region Parameters

## A function to call when this [Payload] is executed. MUST take the following arguments:
## `func anyName(source: Variant, target: Variant) -> Variant`
## [method executeImplementation] will return the result of the [Callable].
## TIP: The parameter names and the [Variant] types may be replaced with any name and any specific type, for better reliability and performance.
## For example, `func onCollectible_didCollect(collectibleComponent: CollectibleComponent, collectorEntity: Entity) -> int` as in [CollectibleStatComponent].
@export var payloadCallable: Callable

# DESIGN: No `payload` argument for `payloadCallable()` because `CallablePayload` is intended for calling an existing function in an existing script/class,
# so any extra information/properties etc. would be in the called script, instead of in the `CallablePayload`.
# This is unlike a `ScriptPayload` which may call a generic/reusable script, and that script may need to access specific properties from the `ScriptPayload`.

#endregion


## Returns the result of the [member payloadCallable].
func executeImplementation(source: Variant, target: Variant) -> Variant:
	printLog(str("executeImplementation() callable: ", payloadCallable, ", source: ", source, ", target: ", target))
	if self.payloadCallable:
		self.willExecute.emit(source, target)
		# A function with the following arguments:
		# func anyName(source: Variant, target: Variant) -> Variant
		return payloadCallable.call(source, target)
	else:
		Debug.printWarning("Missing payloadCallable", self.logName)
		return false
