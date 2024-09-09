## A Payload which calls a function or method.

class_name CallablePayload
extends Payload


#region Parameters

## A function to call when this Payload is executed. MUST take the following arguments:
## `func anyName(source: Variant, target: Variant) -> Variant`
@export var payloadCallable:Callable

#endregion


func executeImplementation(source: Variant, target: Variant) -> Variant:
	printLog(str("executeCallable() callable: ", payloadCallable, ", source: ", source, " target: ", target))
	if self.payloadCallable:
		self.willExecute.emit(source, target)
		# A function with the following arguments:
		# func anyName(source: Variant, target: Variant) -> Variant
		return payloadCallable.call(source, target)
	else:
		Debug.printWarning("Missing payloadCallable", self.logName)
		return false