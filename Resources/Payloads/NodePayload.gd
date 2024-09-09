## A Payload which creates a new copy of a specified [PackedScene] and attaches it to a receiving target Node.
## May be used for adding new [Component]s to a player [Entity] or other character.

class_name NodePayload
extends Payload


#region Parameters

## A Scene whose copy (instance) will be added to the receiving [Node] that is the target of this Payload.
## May be used for adding new components to an Entity.
@export var payloadScene: PackedScene # TBD: Which type to use here for instantiating copies from?

#endregion


func executeImplementation(source: Variant, target: Variant) -> Node:
	printLog(str("executeNode() scene: ", payloadScene, ", source: ", source, " target: ", target))
	
	var targetParent: Node = target as Node

	if not targetParent:
		Debug.printWarning("target is not a Node; cannot be a parent", self.logName)
		return null

	if self.payloadScene:
		self.willExecute.emit(source, target)
		var payloadNode: Node = createPayloadNode()
		
		targetParent.add_child(payloadNode)
		payloadNode.owner = targetParent # INFO: Necessary for persistence to a [PackedScene] for save/load.
		return payloadNode
	else:
		Debug.printWarning("Missing payloadScene", self.logName)
		return null


## Creates and returns a new instance of [member payloadScene].
## TIP: May be overridden in game-specific subclasses to further customize a newly instantiated Node.
func createPayloadNode() -> Node:
	var newNode: Node = payloadScene.instantiate()
	return newNode

