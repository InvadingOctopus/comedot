## Abstract base class for Payloads. A "payload" is the result of any object or action in the game world which "delivers" some effect to an Entity.
## It may be a Signal, a [Callable] function, a Script, or a Node to attach to the receiving entity.
## NOTE: Do NOT use this class when assigning the "payload" property of other objects; it has no effect. Use subclasses such as [SignalPayload], [CallablePayload], [ScriptPayload] or [NodePayload].
## Examples: A [CollectibleComponent] representing an apple could have a Payload that calls the function `decreaseHunger()`.
## The Payload of a BFG69420 gun [Upgrade] would be a customized [GunComponent] to be instantiated and attached to the player Entity.
## The Payload of an [Action] representing a Fireball Spell would be the `Fireball.gd` script that may run complex code to check the terrain for flammability etc.

class_name Payload
extends Resource


#region Parameters
@export var debugMode: bool = false
#endregion


#region State
var logName: String: # Subclasses may add more details.
	get: return str(self.get_script().get_global_name(), " ", self.resource_path.get_file(), " ", self)
#endregion


#region Signals
@warning_ignore("unused_signal")
signal willExecute(source: Variant, target: Variant)
signal didExecute(source: Variant, target: Variant, result: Variant)
#endregion


## Called by other objects to execute, perform, or apply the actual effect of this Payload, such as a [CollectorComponent] picking up a [CollectibleComponent].
## NOTE: This method does NOT contain any actual implementation or effect; it is only the interface for other objects to call.
## A subclass which `extends Payload` (such as [ScriptPayload]) MUST implement the [method executeImplementation].
func execute(source: Variant, target: Variant) -> Variant:
	# printLog(str("execute() source: ", source, " target: ", target)) # Logged by subclasses.
	
	var result: Variant = false
	
	# Let a subclass implement this.
	result = executeImplementation(source, target)

	# NOTE: The `willExecute` signal must be emitted by subclasses, if their requirements are met.
	
	if Tools.checkResult(result): # Must not be `null` and not `false` and not an empty Array or Dictionary.
		self.didExecute.emit(source, target, result)
		return result
	else:
		return false # TBD: Should we return `null`?


## The actual code which performs the actual action or effect of the Payload.
## IMPORTANT: MUST be overridden in a subclass which `extends Payload` such as [SignalPayload] and [ScriptPayload].
func executeImplementation(source: Variant, target: Variant) -> Variant:
	Debug.printWarning(str("executeImplementation() source: ", source, ", target: ", target, " — Not implemented; Must be overridden in a Payload subclass."), self.logName)
	return false


func printLog(message: String) -> void:
	if debugMode: Debug.printLog(message, self.logName, "", "pink")

