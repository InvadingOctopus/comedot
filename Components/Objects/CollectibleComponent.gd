## Represents an item that may be picked up by a character [Entity] which has a [CollectorComponent].
## Provides a "[Payload]" which may be a new child node that will be attached to the collector [Entity], or a script or [Callable] that will be executed by the [CollectorComponent], or a [Signal] to be emitted etc.
##
## NOTE: DESIGN: By default, a [CollectibleComponent] starts with [member Area2D.monitoring] disabled, so it does not waste processing time.
## In the recommended convention, a [CollectorComponent] handles the collision, checks its own collection conditions (such as maximum health or ammo), then the COLLECTOR calls the [method requestToCollect] on the collectible.
## The collectible then handles its own conditions and removal of the parent Entity (to destroy the in-game item so it cannot be collected again) if the collection is approved.
##
## TIP: Should be subclassed with game-specific logic in most cases.

class_name CollectibleComponent
extends Component

# NOTE: DESIGN: PERFORMANCE: [CollectibleComponent] shouldn't inherit from [AreaCollisionComponent] or include code to perform the handling of collision to keep the component lightweight.
# This component should only contain data about the collectible.
# The pickup process should be covered by a [CollectorComponent] or subclasses such as [CollectibleStatComponent].


#region Parameters

## The "contents" of this item: The actual gameplay effect of picking up this collectibe, where this [CollectibleComponent] is passed as the `source` for [method Payload.execute], and the [CollectorComponent]'s parent [Entity] is the `target`.
## See [Payload] for explanation and available options.
@export var payload: Payload

@export var isEnabled: bool = true
#endregion


#region State
## Stores the most recent result, if any, of the [Payload]'s [method Payload.execute] method, to allow removal of the Entity representing the collectible item after it has been successfully collected.
var previousPayloadResult: bool = false # TBD: Should this be a Variant to remember the result directly instead of a boolean flag?
#endregion


#region Signals
@warning_ignore("unused_signal")
signal didCollideCollector(collectorComponent: CollectorComponent) ## NOTE: Unused by the base [CollectibleComponent], but may be emitted by subclasses.
signal willBeCollected(collectorEntity: Entity)
signal didDenyCollection(collectorEntity: Entity) ## When this component declines or cancels the collection.
signal willBeFreed
#endregion


# DEBUG: UNUSED: May be used for subclasses.
# func onAreaEntered(area: Area2D) -> void:
# 	if not isEnabled: return

# 	var collectorComponent: CollectorComponent = area.get_node(^".") as CollectorComponent # HACK: Find better way to cast self?
# 	if not collectorComponent: return

# 	if debugMode: printDebug(str("onAreaEntered() CollectorComponent: ", collectorComponent))
# 	didCollideCollector.emit(collectorComponent)


#region Collection

## Called by a [CollectorComponent].
## When a collision occurs, the [CollectorComponent] handles the event and checks the conditions for collection (such as maximum allowed health or remaining inventory space).
## If the collector wants to pick this item, this method is called,
## then this [CollectibleComponent] checks its own conditions (such as whether the item is ready to be picked up, e.g. a chopped tree or mined rock).
func requestToCollect(collectorEntity: Entity, collectorComponent: CollectorComponent) -> bool:
	if not isEnabled: return false
	if debugMode: printDebug(str("requestToCollect() collectorEntity: ", collectorEntity.logName, ", collectorComponent: ", collectorComponent))

	var isCollectionApproved: bool = checkCollectionConditions(collectorEntity, collectorComponent)

	if isCollectionApproved:
		willBeCollected.emit(collectorEntity)
	else:
		didDenyCollection.emit(collectorEntity)
		return false

	return isCollectionApproved


## Called by a [CollectorComponent] to perform the collection of this [CollectibleComponent],
## by calling [method Payload.execute] and passing this [CollectibleComponent] as the `source` and the [CollectorComponent]'s parent [Entity] as the `target`.
## If the collection is successful, this [CollectibleComponent] may then remove itself from the scene, or it may choose to enter a cooldown recovery state.
## Returns: The result of [method Payload.execute] or `false` if the [member payload] is missing.
func collect(collectorComponent: CollectorComponent) -> Variant:
	self.previousPayloadResult = Tools.checkResult(payload.execute(self, collectorComponent.parentEntity)) if payload else false

	if debugMode: printDebug(str("collect() collectorComponent: ", collectorComponent, ", previousPayloadResult: ", previousPayloadResult))

	if checkRemovalConditions():
		willBeFreed.emit()
		self.requestDeletionOfParentEntity()

	return previousPayloadResult


#endregion


#region Virtual Methods

## May be overridden in a subclass to approve or deny the collection of this item by a [CollectorComponent].
## Default: `isEnabled`
func checkCollectionConditions(collectorEntity: Entity, collectorComponent: CollectorComponent) -> bool:
	# CHECK: Maybe a better name? :p
	if debugMode: printDebug(str("checkCollectionConditions() collectorEntity: ", collectorEntity.logName, ", collectorComponent: ", collectorComponent, ", isEnabled: ", isEnabled))
	return isEnabled


## Returns `true` if [member previousPayloadResult] is `true` to approve removal of the item after it has been collected.
## May be overridden in a subclass to approve or deny the removal of this item after it has been collected by a [CollectorComponent].
func checkRemovalConditions() -> bool:
	# CHECK: Maybe a better name? :p
	if debugMode: printDebug(str("checkRemovalConditions() previousPayloadResult: ", previousPayloadResult))
	return previousPayloadResult # NOTE: TBD: Should removal also depend on isEnabled?


## If the [Payload] type os [CallablePayload], this function may be called when a [CollectorComponent] picks up this [CollectibleComponent].
## May optionally return any value.
## MUST be overridden by subclasses.
func onCollectible_didCollect(collectibleComponent: CollectibleComponent, collectorEntity: Entity) -> Variant:
	printWarning(str("onCollectible_didCollect() must be overridden by a subclass! collectibleComponent: ", collectibleComponent, ", collectorEntity: ", collectorEntity.logName))
	return null

#endregion
