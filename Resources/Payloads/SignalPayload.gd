## A Payload which emits a [Signal] defined in the global [GameState] AutoLoad.

class_name SignalPayload
extends Payload


#region Parameters

## The name of a [Signal] in the global [GameState] AutoLoad.
## IMPORTANT: The signal MUST ALREADY be defined in [GameState].gd
@export var payloadSignalName: StringName

#endregion


func executeImplementation(source: Variant, target: Variant) -> bool:
	printLog(str("executeSignal() signal: GameState.", payloadSignalName, ", source: ", source, " target: ", target))

	if not self.payloadSignalName.is_empty():
		self.willExecute.emit(source, target)
	
		var result: Error = GameState.emit_signal(payloadSignalName, source, target)
		
		if result == 0: return true 
		else: Debug.printWarning(str("Error emitting signal: ", result), self.logName)
	
	else:
		Debug.printWarning("Missing payloadSignalName", self.logName)
	
	return false
