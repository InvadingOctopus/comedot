## Builds a list of the [InventoryItem]s from an [InventoryComponent].

class_name InventoryList
extends Container


#region Parameters

## The [InventoryComponent] to build [InventoryItemUI]s from.
## If `null`, then the [member GameState.players] Player Entity will be searched.
## NOTE: Does NOT monitor the addition or removal of items at runtime.
@export var inventoryComponent: InventoryComponent

@export var shouldUppercase: bool = false ## Make all [InventoryItemUI]s [member Label.uppercase].
@export var shouldShowText:  bool = false ## Only affects newly created [InventoryItemUI]s.
@export var shouldShowIcon:  bool = true  ## Only affects newly created [InventoryItemUI]s.

#endregion


#region Dependencies
static var inventoryItemUIScene: PackedScene:
	get:
		if not inventoryItemUIScene: inventoryItemUIScene = load("res://UI/Views/InventoryItemUI.tscn")
		return inventoryItemUIScene
#endregion


func _ready() -> void:
	if not inventoryComponent:
		var player: PlayerEntity = GameState.players.front()
		if player: self.inventoryComponent = player.inventoryComponent

	if inventoryComponent:
		connectSignals()
		buildListItems()
	else:
		Debug.printWarning("Missing inventoryComponent", self)


func connectSignals() -> void:
	inventoryComponent.didAddItem.connect(self.inventoryComponent_didAddItem)
	inventoryComponent.didRemovetem.connect(self.inventoryComponent_didRemovetem)


func inventoryComponent_didAddItem(_item: InventoryItem) -> void:
	# TODO: PERFORMANCE: Only update the new item!
	buildListItems()


func inventoryComponent_didRemovetem(_item: InventoryItem) -> void:
	# TODO: PERFORMANCE: Only update the removed item!
	buildListItems()


## Creates an [InventoryItemUI] for each of the [InventoryItem] data items returned by [method getResources].
## WARNING: Removes all existing child nodes first.
func buildListItems() -> void:
	Tools.removeAllChildren(self)
	for listItem: InventoryItem in inventoryComponent.items:
		createListItemUI(listItem)


## Creates an [InventoryItemUI] for the visual representation of an [InventoryItem]'s data.
func createListItemUI(listItem: InventoryItem) -> InventoryItemUI:
	var newItemUI: InventoryItemUI = inventoryItemUIScene.instantiate()
	newItemUI.inventoryItem		= listItem
	newItemUI.shouldShowText	= self.shouldShowText
	newItemUI.shouldShowIcon	= self.shouldShowIcon
	newItemUI.shouldUppercase	= self.shouldUppercase

	Tools.addChildAndSetOwner(newItemUI, self)

	# newItemUI.updateText() # Is this necessary? Won't it be called on the label's _ready()?
	return newItemUI
