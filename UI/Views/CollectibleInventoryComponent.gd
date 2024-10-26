## A subclass of [CollectibleComponent] which adds an [InventoryItem] to the [InventoryComponent] of the collector Entity.

class_name CollectibleInventoryComponent
extends CollectibleComponent

# TODO: Automatically set Sprite2D texture to InventoryItem.icon


#region Parameters

@export var inventoryItem: InventoryItem

## Decline collection if the [member inventoryItem] already exists in the receiving [InventoryComponent].
@export var preventCollectionIfDuplicateItem: bool = true # TBD: Better name? :')

@export var shouldDisplayIndicator: bool = true

#endregion


func _ready() -> void:
	# Override the Payload
	self.payload = CallablePayload.new()
	(self.payload as CallablePayload).payloadCallable = self.onCollectible_didCollect


## Prevents collection if [member preventCollectionIfDuplicateItem] and the [member inventoryItem] is already in the [param collectorEntity]'s [InventoryComponent].
func checkCollectionConditions(collectorEntity: Entity, collectorComponent: CollectorComponent) -> bool:
	if not super.checkCollectionConditions(collectorEntity, collectorComponent): return false

	var inventoryComponent: InventoryComponent = collectorEntity.components.get(&"InventoryComponent")

	if not inventoryComponent:
		if shouldShowDebugInfo: printDebug(str("collectorEntity missing InventoryComponent: ", collectorEntity.logName))
		return false
	elif (preventCollectionIfDuplicateItem or inventoryComponent.shouldPreventDuplicates) and inventoryComponent.items.has(inventoryItem):
		if shouldShowDebugInfo: printDebug(str("preventCollectionIfDuplicateItem/inventoryComponent.shouldPreventDuplicates and item already in inventory: ", inventoryItem.logName))
		return false
	else:
		return true


## Returns: The [InventoryItem].
func onCollectible_didCollect(collectibleComponent: CollectibleComponent, collectorEntity: Entity) -> InventoryItem:
	if shouldShowDebugInfo:
		printLog(str("onCollectible_didCollect() collectibleComponent: ", collectibleComponent, ", collectorEntity: ", collectorEntity.logName, ", inventoryItem: ", inventoryItem.logName))

	var inventoryComponent: InventoryComponent = collectorEntity.components.get(&"InventoryComponent")

	if not inventoryComponent:
		if shouldShowDebugInfo: printDebug("collectorEntity missing InventoryComponent")
		return null

	var result: bool = inventoryComponent.addItem(self.inventoryItem)

	if not result:
		if shouldShowDebugInfo: printDebug(str("inventoryComponent.addItem() returned false: ", inventoryItem.logName))
		return null

	# Create a visual indicator
	# TODO: Make it customizable

	if shouldDisplayIndicator:
		TextBubble.create(collectorEntity, "GET " + inventoryItem.displayName.capitalize())

	return inventoryItem
