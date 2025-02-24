## A container for [InventoryItem]s.

class_name InventoryComponent
extends Component


#region Parameters

## IMPORTANT: Do NOT modify this array directly! Use the [method addItems], [method removeItems] etc. methods to ensure that [member maximumItems] and [member maximumWeight] are properly checked and updated.
@export var items: Array[InventoryItem]

@export_range(1, 1000) var maximumItems:  int   = 100 # NOTE: Decrease this value will NOT automatically remove excess items.
@export_range(1, 1000) var maximumWeight: float = 100 # NOTE: Decrease this value will NOT automatically remove excess items.

@export var shouldPreventDuplicates: bool = false
@export var isEnabled: bool = true

#endregion


#region State
var totalWeight: float
#endregion


#region Signals
# TBD: Should the signals be emitted per item or for arrays of items only?
signal didAddItem(item: InventoryItem)
signal didRemovetem(item: InventoryItem)
#endregion


func _init() -> void:
	self.recalculateWeight()


#region Interface

## Returns a list of the items that were successfully added.
func addItems(newItems: Array[InventoryItem]) -> Array[InventoryItem]:
	if not isEnabled: return []

	var itemsAdded: Array[InventoryItem]

	for newItem in newItems:
		if self.addItem(newItem): itemsAdded.append(newItem)

	return itemsAdded


## Adds the new item if the inventory is not full or overloaded.
func addItem(newItem: InventoryItem) -> bool:
	if not isEnabled: return false

	if self.items.size() >= self.maximumItems:
		if debugMode: printDebug(str("Inventory full (", self.maximumItems, ") — Cannot add: ", newItem.logName))
		return false
	elif self.totalWeight + newItem.weight > self.maximumWeight:
		if debugMode: printDebug(str("Inventory overloaded (", self.maximumWeight, ") — Cannot add: ", newItem.logName))
		return false
	elif shouldPreventDuplicates and self.items.has(newItem):
		if debugMode: printDebug(str("shouldPreventDuplicates and item already in inventory: ", newItem.logName))
		return false
	else:
		self.items.append(newItem)
		self.totalWeight += newItem.weight
		if debugMode: printDebug(str("Added: ", newItem.logName, " — Total: ", self.items.size(), " items, weight: ", self.totalWeight))
		self.didAddItem.emit(newItem)
		return true


## Returns a list of the items that were successfully removed.
func removeItems(itemsToRemove: Array[InventoryItem]) -> Array[InventoryItem]:
	if not isEnabled: return []  # TBD: Should removal depend on `isEnabled`?

	var itemsRemoved: Array[InventoryItem]

	for itemToRemove in itemsToRemove:
		if self.removeItem(itemToRemove): itemsRemoved.append(itemToRemove)

	return itemsRemoved


## Returns `true` if the item was in the inventory and removed.
func removeItem(itemToRemove: InventoryItem) -> bool:
	if not isEnabled: return false # TBD: Should removal depend on `isEnabled`?

	# TBD: Allow support for conditions on removal such as cursed items?

	if self.items.has(itemToRemove):
		self.items.erase(itemToRemove)
		self.totalWeight -= itemToRemove.weight
		if debugMode: printDebug(str("Removed: ", itemToRemove.logName, " — Total: ", self.items.size(), " items, weight: ", self.totalWeight))
		self.didRemovetem.emit(itemToRemove)
		return true
	else:
		return false


func recalculateWeight() -> float:
	self.totalWeight = 0

	if not self.items.is_empty():
		for item in self.items:
			self.totalWeight += item.weight

	if debugMode: printDebug(str("recalculateWeight(): ", self.totalWeight))
	return self.totalWeight

#endregion
