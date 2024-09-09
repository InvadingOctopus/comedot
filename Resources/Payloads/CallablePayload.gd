## A [Payload] which calls a function or method.

class_name CallablePayload
extends Payload


#region Parameters

## A function to call when this [Payload] is executed. MUST take the following arguments:
## `func anyName(source: Variant, target: Variant) -> Variant`
## [method executeImplementation] will return the result of the [Callable].
## TIP: The parameter names and the [Variant] types may be replaced with any name and any type, for better clarity.
## For example, `func onCollectible_didCollect(collectibleComponent: CollectibleComponent, collectorEntity: Entity) -> int` as in [StatCollectibleComponent].
@export var payloadCallable: Callable

#endregion


## Returns the result of the [member payloadCallable].
func executeImplementation(source: Variant, target: Variant) -> Variant:
	printLog(str("executeImplementation() callable: ", payloadCallable, ", source: ", source, " target: ", target))
	if self.payloadCallable:
		self.willExecute.emit(source, target)
		# A function with the following arguments:
		# func anyName(source: Variant, target: Variant) -> Variant
		return payloadCallable.call(source, target)
	else:
		Debug.printWarning("Missing payloadCallable", self.logName)
		return false
