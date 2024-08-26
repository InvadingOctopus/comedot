## When this component collides with a [CollectibleComponent], the "payload" component is transfered to this [CollectorComponent]'s parent [Entity].

class_name CollectorComponent
extends Component


signal didCollideWithCollectible(collectibleComponent: CollectibleComponent)
signal didCollect(collectibleComponent: CollectibleComponent, payload: Variant)


func onAreaEntered(area: Area2D) -> void:
	var collectibleComponent: CollectibleComponent = area.get_node(".") as CollectibleComponent # HACK: TODO: Find better way to cast
	if not collectibleComponent: return

	printDebug(str("onAreaEntered() CollectibleComponent: ", collectibleComponent))
	didCollideWithCollectible.emit(collectibleComponent)

	handleCollection(collectibleComponent)


func handleCollection(collectibleComponent: CollectibleComponent) -> bool:

	# First, check our own conditions. Can we collect this item?
	# For example, are we already at maximum health or ammo, or do we have enough inventory space?

	if not checkCollectionConditions(collectibleComponent): return false

	if collectibleComponent.requestToCollect(self.parentEntity, self) == true:
		return collect(collectibleComponent)
	else:
		printDebug("CollectibleComponent denied collection: " + str(collectibleComponent))
		return false


## May be overridden in a subclass to approve or deny the collection of a [CollectibleComponent] by this [CollectorComponent] and the parent [Entity].
## Default: `true`
func checkCollectionConditions(_collectibleComponent: CollectibleComponent) -> bool:
	return true


## Performs the collection of a [CollectibleComponent],
## either by adding a "Payload" [Node] to this component's parent [Entity],
## or by executing a script provided by the collectible.
func collect(collectibleComponent: CollectibleComponent) -> bool:
	var payload: Variant
	printDebug(str("collect() collectibleComponent: ", collectibleComponent))

	match collectibleComponent.payloadType:

		CollectibleComponent.PayloadType.node:
			var payloadNode: Node = collectibleComponent.createPayloadNode()
			payload = payloadNode
			printDebug(str("Payload Node: ", payloadNode))
			self.parentEntity.add_child(payloadNode)
			payloadNode.owner = self.parentEntity # INFO: Necessary for persistence to a [PackedScene] for save/load.

		CollectibleComponent.PayloadType.script:
			# A script that matches this interface:
			# static func onCollectible_didCollect(collectorEntity: Entity, collectorComponent: CollectorComponent, collectibleComponent: CollectibleComponent) -> Variant:

			var payloadScript: GDScript = collectibleComponent.payloadScript
			payload = payloadScript
			printDebug(str("Payload Script: ", payloadScript, " ", payloadScript.get_global_name()))
			payloadScript.call(CollectibleComponent.payloadMethodName, self.parentEntity, self, collectibleComponent)

		CollectibleComponent.PayloadType.callable:
			# A function that matches this signature:
			# func onCollectible_didCollect(collectorEntity: Entity, collectorComponent: CollectorComponent) -> Variant

			var payloadCallable: Callable = collectibleComponent.payloadCallable
			payload = payloadCallable
			payloadCallable.call(self.parentEntity, self)

	didCollect.emit(collectibleComponent, payload)
	return true
