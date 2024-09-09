## Abstract base class for Payloads. A "payload" is the result of any object or action in the game world which "delivers" some effect to an Entity.
## It may be a Signal, a [Callable] function, a Script, or a Node to attach to the receiving entity.
##
## Examples: A [CollectibleComponent] representing an apple could have a Payload that calls the function `decreaseHunger()`.
## The Payload of a BFG69420 gun [Upgrade] would be a customized [GunComponent] to be instantiated and attached to the player Entity.
## The Payload of an [Action] representing a Fireball Spell would be the `Fireball.gd` script that may run complex code to check the terrain for flammability etc.
## @experimental

class_name Payload
extends Resource


#region Parameters
@export var shouldShowDebugInfo: bool = false
#endregion


#region State
var logName: String = str(self.get_script().get_global_name(), " ", self) # Add more details in subclass.
#endregion


#region Signals
@warning_ignore("unused_signal")
signal willExecute(source: Variant, target: Variant)
signal didExecute(source: Variant, target: Variant, result: Variant)
#endregion


## Called by other objects (such as a [CollectorComponent] picking up a [CollectibleComponent]) to execute this Payload.
## NOTE: Does NOT contain the actual payload implementation. 
## A subclass that `extend`s [Payload] (such as [ScriptPayload]) must implement the [method executeImplementation].
func execute(source: Variant, target: Variant) -> Variant:
	# printLog(str("execute() source: ", source, " target: ", target)) # Logged by subclasses.
	
	var result: Variant = false
	
	# Let a subclass implement this.
	result = executeImplementation(source, target)

	# NOTE: The `willExecute` signal must be emitted by subclasses, if their requirements are met.
	
	if result != null or result != false:
		self.didExecute.emit(source, target, result)
		return result
	else:
		return false # TBD: Should we return `null`?


## The actual code that performs the actual action or effect of the Payload.
## IMPORTANT: MUST be overridden in a subclass that `extend`s [Payload] such as [SignalPayload] and [ScriptPayload].
func executeImplementation(source: Variant, target: Variant) -> Variant:
	Debug.printWarning(str("executeImplementation() source: ", source, ", target: ", target, " — Not implemented; Must be overridden in a subclass of Payload"), self.logName)
	return false


func printLog(message: String) -> void:
	if shouldShowDebugInfo: Debug.printLog(message, "", self.logName)

