## When this component collides with a [CollectibleComponent], the "payload" component is transfered to this [CollectorComponent]'s parent [Entity].
class_name CollectorComponent
extends Component


signal didCollideWithCollectible(collectibleComponent: CollectibleComponent)
signal didCollect(collectibleComponent: CollectibleComponent, payload)

func onAreaEntered(area: Area2D) -> void:
	var collectibleComponent: CollectibleComponent = area.get_node(".") as CollectibleComponent # HACK: TODO: Find better way to cast
	if not collectibleComponent: return

	printDebug("Collided with CollectibleComponent: " + str(collectibleComponent))
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
func checkCollectionConditions(collectibleComponent: CollectibleComponent) -> bool:
	return true


func collect(collectibleComponent: CollectibleComponent) -> bool:

	var payload: Variant

	match collectibleComponent.payloadType:

		CollectibleComponent.PayloadType.node:
			payload = collectibleComponent.createPayloadNode()
			self.parentEntity.add_child(payload)

		CollectibleComponent.PayloadType.script:
			payload = collectibleComponent.payloadScript
			payload.executeCollectibleScript(self.parentEntity, self, collectibleComponent)

	didCollect.emit(collectibleComponent, payload)
	return true
