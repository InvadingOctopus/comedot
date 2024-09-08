## A "payload" is the result of any object or action in the game world which "delivers" some effect to an Entity.
## It may be a Signal, a [Callable] function, a Script, or a Node to attach to the receiving entity.
##
## Examples: A [CollectibleComponent] representing an apple could have a Payload that executes the function `decreaseHunger()`
## The Payload of a BFG69420 gun [Upgrade] would be a customized [GunComponent] to be instantiated and attached to the player Entity.
## The Payload of an [Action] representing a Fireball spell would be the `Fireball.gd` script that may run complex code to check the terrain for flammability etc.
## @experimental

class_name Payload
extends Resource


#region Constants
enum PayloadType {
	signalPayload	= 1,
	callablePayload	= 2,
	scriptPayload	= 3,
	nodePayload		= 4,
	} # TBD: Order & value: start from 0 or 1?
#endregion


#region Parameters
@export var payloadType: PayloadType = PayloadType.signalPayload

@export var payloadSignal: Signal

## A function to call when this Payload is executed. MUST take the following arguments:
## `func anyName(source: Variant, target: Variant) -> Variant`
@export var payloadCallable:Callable

## A script to run when this Payload is executed.
## IMPORTANT: The script MUST have a function with the same name as [member payloadScriptMethodName] and the following arguments:
## `func payloadScriptMethodName(source: Variant, target: Variant) -> Variant`
@export var payloadScript: GDScript # TODO: Stronger typing when Godot allows it :')

@export var payloadScriptMethodName: StringName = &"onPayload_didExecute" ## The method/function which will be executed from the [member payloadScript].

## A Scene whose copy (instance) will be added to the receiving [Entity] that is the target of this Payload.
## May be used for adding new components to an Entity.
@export var payloadScene: PackedScene # TBD: Which type to use here for instantiating copies from?

@export var shouldShowDebugInfo: bool = false
#endregion


#region State
var logName: String:
	get: return str(self, " ", PayloadType.keys()[payloadType])
#endregion


#region Signals
signal willExecute(source: Variant, target: Variant)
signal didExecute(source: Variant, target: Variant, result: Variant)
#endregion


#region Dependencies
#endregion


func execute(source: Variant, target: Variant) -> Variant:
	# printLog(str("execute() source: ", source, " target: ", target)) # Logged by functions
	
	var result: Variant

	match self.payloadType:
		PayloadType.signalPayload:	 result = executeSignal(source, target)
		PayloadType.callablePayload: result = executeCallable(source, target)
		PayloadType.scriptPayload:	 result = executeScript(source, target)
		PayloadType.nodePayload:	 result = executeNode(source, target)
		_: result = false

	if result != null or result != false:
		self.didExecute.emit(source, target, result)
		return result
	else:
		return false # TBD: Should we return `null`?


func executeSignal(source: Variant, target: Variant) -> bool:
	printLog(str("executeSignal() signal: ", payloadSignal, ", source: ", source, " target: ", target))

	if self.payloadSignal:
		self.willExecute.emit(source, target)
		payloadSignal.emit(source, target)		
		return true
	else:
		Debug.printWarning("Missing callable", self.logName)
		return false
	

func executeCallable(source: Variant, target: Variant) -> Variant:
	printLog(str("executeCallable() callable: ", payloadCallable, ", source: ", source, " target: ", target))
	if self.payloadSignal:
		# A function with the following arguments:
		# func anyName(source: Variant, target: Variant) -> Variant
		return payloadCallable.call(source, target)
	else:
		Debug.printWarning("Missing callable", self.logName)
		return false


func executeScript(source: Variant, target: Entity) -> bool:
	printLog(str("executeScript() script: ", payloadScript, " ", payloadScript.get_global_name(), ", source: ", source, " target: ", target))

	if self.payloadScript:
		# A script that matches this interface:
		# static func payloadScriptMethodName(source: Variant, target: Variant) -> Variant:
		return self.payload.call(self.payloadScriptMethodName, source, target)
	else:
		Debug.printWarning("Missing script", self.logName)
		return false


func executeNode(source: Variant, target: Variant) -> Node:
	printLog(str("executeNode() scene: ", payloadScene, ", source: ", source, " target: ", target))
	
	var targetParent: Node = target as Node

	if not targetParent:
		Debug.printWarning("target is not a Node; cannot be a parent", self.logName)
		return null

	if self.payloadScene:
		var payloadNode: Node = payloadScene.instantiate()
		# TODO: Add hook for customization of new scene instances
		targetParent.add_child(payloadNode)
		payloadNode.owner = targetParent # INFO: Necessary for persistence to a [PackedScene] for save/load.
		return payloadNode
	else:
		Debug.printWarning("Missing scene", self.logName)
		return null


func printLog(message: String) -> void:
	if shouldShowDebugInfo: Debug.printLog(message, self.logName)

