## When this component collides with a [CollectibleComponent], the "payload" of the collectible is executed.
## The "payload" may be a new Component added to the collector [Entity], or a change in an [Stat], and so on.

class_name CollectorComponent
extends Component


signal didCollideWithCollectible(collectibleComponent: CollectibleComponent)
signal didCollect(collectibleComponent: CollectibleComponent, payload: Variant, result: Variant)


func onAreaEntered(area: Area2D) -> void:
	var collectibleComponent: CollectibleComponent = area.get_node(".") as CollectibleComponent # HACK: TODO: Find better way to cast
	if not collectibleComponent: return

	printDebug(str("onAreaEntered() CollectibleComponent: ", collectibleComponent))
	didCollideWithCollectible.emit(collectibleComponent)

	handleCollection(collectibleComponent)


func handleCollection(collectibleComponent: CollectibleComponent) -> Variant:

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
## either by adding a [Payload] [Node] to this component's parent [Entity],
## or by executing a script provided by the collectible.
func collect(collectibleComponent: CollectibleComponent) -> Variant:
	printDebug(str("collect() collectibleComponent: ", collectibleComponent))
	var payload: Payload = collectibleComponent.payload
	var result:  Variant = false

	if payload: result = payload.execute(collectibleComponent, self.parentEntity) # TBD: Should this be the CollectibleComponent's job?
	else: printWarning("collectibleComponent missing payload")

	if   result != null \
	and (result is not bool or result != false): # Must not be `null` and not `false`
		didCollect.emit(collectibleComponent, payload, result)

	return result
