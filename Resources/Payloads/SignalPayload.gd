## A [Payload] that emits a [Signal] defined in the global [GameState] AutoLoad.

class_name SignalPayload
extends Payload


#region Parameters

## The name of a game-specific [Signal] in the global [GameState] AutoLoad.
## The Signal must be emitted with 2 arguments: `source: Variant, target: Variant`
## IMPORTANT: The signal MUST ALREADY be defined in [GameState].gd as it is NOT created at runtime.
@export var payloadSignalName: StringName

#endregion


## Returns `true` if the signal was found and emitted.
func executeImplementation(source: Variant, target: Variant) -> bool:
	printLog(str("executeImplementation() signal: GameState.", payloadSignalName, ", source: ", source, ", target: ", target))

	if self.payloadSignalName.is_empty():
		Debug.printWarning("Missing payloadSignalName", self.logName)
		return false

	if not GameState.has_signal(payloadSignalName):
		Debug.printWarning("GameState missing payloadSignalName: " + payloadSignalName, self.logName)
		return false

	self.willExecute.emit(source, target)

	var result: Error = GameState.emit_signal(payloadSignalName, source, target)
	if  result == 0: return true 
	else:
		Debug.printWarning(str("Error emitting signal: ", result), self.logName)
		return false
