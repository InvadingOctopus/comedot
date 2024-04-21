## Represents an item that may be picked up by a character [Entity] which has a [CollectorComponent].
## Provides a "payload" child node that will be copied to the collector [Entity], or a script [CollectiblePayloadScript] resource that will be executed by the [CollectorComponent].
##
## NOTE: DESIGN: By default, a [CollectibleComponent] starts with [member Area2D.monitoring] disabled, so it does not waste processing time.
## In the recommended convention, a [CollectorComponent] handles the collision, checks its own collection conditions (such as maximum health or ammo), then calls the [method requestToCollect] on the collectible.
## The collectible then handles its own conditions and removal if the collection is approved.
##
## Should be subclassed in most cases.
class_name CollectibleComponent
extends Component

# NOTE: DESIGN: [CollectibleComponent]s shouldn't include code to perform the handling of collision/transfer etc.
# This component should only contain data about the collectible.
# The pickup process should be covered by a [CollectorComponent].


enum PayloadType {node = 0, script = 1}


#region Parameters

@export var isEnabled := true

@export var payloadType: PayloadType

@export var payloadNode:   PackedScene # TBD: Which type to use here for instantiating copies from?
@export var payloadScript: CollectiblePayloadScript # NOTE: CHECK: Which type to use here for passing around scripts?

#endregion

#region Signals
signal didCollideWithCollector(collectorComponent: CollectorComponent)
signal willBeCollected(collectorEntity: Entity)
signal didDenyCollection(collectorEntity: Entity) ## When this component declines or cancels the collection.
signal willBeFreed
#endregion

func onAreaEntered(area: Area2D):
	if not isEnabled: return

	var collectorComponent: CollectorComponent = area.get_node(".") as CollectorComponent # HACK: TODO: Find better way to cast
	if not collectorComponent: return

	printDebug("Collided with CollectorComponent: " + str(collectorComponent))
	didCollideWithCollector.emit(collectorComponent)


## Called by a [CollectorComponent].
## When a collision occurs, the [CollectorComponent] handles the event and checks the conditions for collection (such as maximum allowed health or remaining inventory space).
## If the collector wants to pick this item, this method is called,
## then this [CollectibleComponent] checks its own conditions (such as whether the item is ready to be picked up, e.g. a chopped tree or mined rock).
## If the transfer is successful, this [CollectibleComponent] may then remove itself from the scene, or it may choose to enter a cooldown recovery state.
func requestToCollect(collectorEntity: Entity, collectorComponent: CollectorComponent) -> bool:
	if not isEnabled: return false

	var isCollectionApproved := checkCollectionConditions(collectorEntity, collectorComponent)

	if isCollectionApproved:
		willBeCollected.emit(collectorEntity)
	else:
		didDenyCollection.emit(collectorEntity)
		return false

	if checkRemovalConditions():
		willBeFreed.emit()
		self.requestRemovalOfParentEntity()

	return isCollectionApproved


func createPayloadNode() -> Node2D:
	var payloadResource := load(payloadNode.resource_path)
	var newPayloadCopy: Node2D = payloadResource.instantiate()

	if not newPayloadCopy:
		printError("Cannot instantiate a new copy of the collectible payload: " + str(payloadNode.resource_path))
		return null

	return newPayloadCopy


#region Virtual Methods

## May be overridden in a subclass to approve or deny the collection of this item by a [CollectorComponent].
## Default: `true`
func checkCollectionConditions(collectorEntity: Entity, collectorComponent: CollectorComponent) -> bool:
	# CHECK: Maybe a better name? :p
	return true


## May be overridden in a subclass to approve or deny the removal of this item after it has been collected by a [CollectorComponent].
## Default: `true`
func checkRemovalConditions() -> bool:
	# CHECK: Maybe a better name? :p
	return isEnabled

#endregion
