## A [Payload] which creates a new copy of a specified [PackedScene] and attaches it to a receiving target Node.
## May be used for adding new [Component]s to a player [Entity] or other character, or for spawning new objects or characters in the game world.
## TIP: To create or remove [Component]s on an [Entity], use [ComponentPayload]

class_name NodePayload
extends Payload


#region Constants
enum ParentOptions {
	payloadSource,
	parentOfPayloadSource,
	payloadTarget,
	parentOfPayloadTarget,
	}
#endregion


#region Parameters

## A Scene whose copy (instance) will be added to the receiving [Node] that is the target of this Payload.
## May be used for adding new components to an Entity.
## [method executeImplementation] will return an instance of this scene.
@export var payloadScene: PackedScene # TBD: Which type to use here for instantiating copies from? Should this be a path String?

## The parent [Node] to add a new instance of [member payloadScene] to.
@export var parentChoice: ParentOptions = ParentOptions.payloadTarget

@export var shouldUseSourcePosition: bool = false ## If `true` then the payload node's position will be set to the position of the payload "source" or initiator, e.g. an [InteractionComponent]. Otherwise the initial position will be 0,0 in the target parent's space.
@export var positionOffset: Vector2
@export var randomPositionOffsetMin: Vector2 ## The lower bound of the random offset for the spawned node's position, which defaults to the position of the Payload's `source` if it is a [Node2D].
@export var randomPositionOffsetMax: Vector2 ## The upper bound of the random offset for the spawned node's position, which defaults to the position of the Payload's `source` if it is a [Node2D].

#endregion


## Executes the payload, where the [param source] is the [Action], [InteractionComponent] or [Upgrade] etc. and the [param target] is the Entity etc. to which the node payload will be attached.
## Returns the [Node] instance that was created from the [member payloadScene].
func executeImplementation(source: Variant, target: Variant) -> Node:
	printLog(str("executeImplementation() scene: ", payloadScene, ", source: ", source, ", target: ", target))

	if not self.payloadScene:
		Debug.printWarning("Missing payloadScene", self.logName)
		return null

	# Decide the parent of the new node instance

	var parent: Node

	match parentChoice:
		ParentOptions.payloadSource:
			if source is Node: parent = source
			else: Debug.printWarning("source is not a Node; cannot be a parent", self.logName)
		ParentOptions.parentOfPayloadSource:
			if source is Node: parent = source.get_parent()
			else: Debug.printWarning("source is not a Node; cannot get_parent()", self.logName)
		ParentOptions.payloadTarget:
			if target is Node: parent = target
			else: Debug.printWarning("target is not a Node; cannot be a parent", self.logName)
		ParentOptions.parentOfPayloadTarget:
			if target is Node: parent = target.get_parent()
			else: Debug.printWarning("target is not a Node; cannot get_parent()", self.logName)

	if not parent:
		Debug.printWarning(str("Cannot get parent for parentChoice: ", ParentOptions.keys()[parentChoice]), self.logName)
		return null

	# Instantiate

	self.willExecute.emit(source, target)
	var payloadNode: Node = createPayloadNode()

	# Position

	if payloadNode is Node2D:
		if shouldUseSourcePosition and source is Node2D:
			payloadNode.global_position = source.global_position
			payloadNode.position = parent.to_local(payloadNode.position)
		payloadNode.position   += positionOffset
		payloadNode.position.x += randf_range(randomPositionOffsetMin.x, randomPositionOffsetMax.x)
		payloadNode.position.y += randf_range(randomPositionOffsetMin.y, randomPositionOffsetMax.y)

	# Attach

	parent.add_child(payloadNode)
	payloadNode.owner = parent # INFO: Necessary for persistence to a [PackedScene] for save/load.
	return payloadNode


## Creates and returns a new instance of [member payloadScene].
## TIP: May be overridden in game-specific subclasses to further customize a newly instantiated Node.
func createPayloadNode() -> Node:
	var newNode: Node = payloadScene.instantiate()
	return newNode

