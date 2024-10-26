## Represents an item that may be picked up by a character [Entity] which has a [CollectorComponent].
## Provides a "[Payload]" which may be a new child node that will be attached to the collector [Entity], or a script or [Callable] that will be executed by the [CollectorComponent], or a signal to be emitted.
##
## NOTE: DESIGN: By default, a [CollectibleComponent] starts with [member Area2D.monitoring] disabled, so it does not waste processing time.
## In the recommended convention, a [CollectorComponent] handles the collision, checks its own collection conditions (such as maximum health or ammo), then calls the [method requestToCollect] on the collectible.
## The collectible then handles its own conditions and removal if the collection is approved.
##
## TIP: Should be subclassed with game-specific logic in most cases.

class_name CollectibleComponent
extends Component

# NOTE: DESIGN: [CollectibleComponent]s shouldn't include code to perform the handling of collision/transfer etc.
# This component should only contain data about the collectible.
# The pickup process should be covered by a [CollectorComponent].


#region Parameters

## The actual gameplay effect of picking up this collectibe, where this [CollectibleComponent] is passed as the `source` for [method Payload.execute], and the [CollectorComponent]'s parent [Entity] is the `target`.
## See [Payload] for explanation and available options.
@export var payload: Payload

@export var isEnabled: bool = true
#endregion


#region Signals
signal didCollideWithCollector(collectorComponent: CollectorComponent)
signal willBeCollected(collectorEntity: Entity)
signal didDenyCollection(collectorEntity: Entity) ## When this component declines or cancels the collection.
signal willBeFreed
#endregion


func onAreaEntered(area: Area2D) -> void:
	if not isEnabled: return

	var collectorComponent: CollectorComponent = area.get_node(".") as CollectorComponent # HACK: TODO: Find better way to cast
	if not collectorComponent: return

	printDebug(str("onAreaEntered() CollectorComponent: ", collectorComponent))
	didCollideWithCollector.emit(collectorComponent)


## Called by a [CollectorComponent].
## When a collision occurs, the [CollectorComponent] handles the event and checks the conditions for collection (such as maximum allowed health or remaining inventory space).
## If the collector wants to pick this item, this method is called,
## then this [CollectibleComponent] checks its own conditions (such as whether the item is ready to be picked up, e.g. a chopped tree or mined rock).
## If the transfer is successful, this [CollectibleComponent] may then remove itself from the scene, or it may choose to enter a cooldown recovery state.
func requestToCollect(collectorEntity: Entity, collectorComponent: CollectorComponent) -> bool:
	if not isEnabled: return false
	printDebug(str("requestToCollect() collectorEntity: ", collectorEntity.logName, ", collectorComponent: ", collectorComponent))

	var isCollectionApproved: bool = checkCollectionConditions(collectorEntity, collectorComponent)

	if isCollectionApproved:
		willBeCollected.emit(collectorEntity)
	else:
		didDenyCollection.emit(collectorEntity)
		return false

	if checkRemovalConditions():
		willBeFreed.emit()
		self.requestDeletionOfParentEntity()

	return isCollectionApproved


## Called by a [CollectorComponent] to perform the collection of this [CollectibleComponent],
## by calling [method Payload.execute] and passing this [CollectibleComponent] as the `source` and the [CollectorComponent]'s parent [Entity] as the `target`.
## Returns: The result of [method Payload.execute] or `false` if the [member payload] is missing.
func collect(collectorComponent: CollectorComponent) -> Variant:
	return payload.execute(self, collectorComponent.parentEntity) if payload else false


#region Virtual Methods

## May be overridden in a subclass to approve or deny the collection of this item by a [CollectorComponent].
## Default: `isEnabled`
func checkCollectionConditions(collectorEntity: Entity, collectorComponent: CollectorComponent) -> bool:
	# CHECK: Maybe a better name? :p
	printDebug(str("checkCollectionConditions() collectorEntity: ", collectorEntity.logName, ", collectorComponent: ", collectorComponent))
	return isEnabled


## May be overridden in a subclass to approve or deny the removal of this item after it has been collected by a [CollectorComponent].
## Default: `true`
func checkRemovalConditions() -> bool:
	# CHECK: Maybe a better name? :p
	printDebug("checkRemovalConditions()")
	return isEnabled


## If the [Payload] type os [CallablePayload], this function may be called when a [CollectorComponent] picks up this [CollectibleComponent]. 
## May optionally return any value.
## MUST be overridden by subclasses.
func onCollectible_didCollect(collectibleComponent: CollectibleComponent, collectorEntity: Entity) -> Variant:
	printWarning(str("onCollectible_didCollect() must be overridden by a subclass! collectibleComponent: ", collectibleComponent, ", collectorEntity: ", collectorEntity.logName))
	return null

#endregion
