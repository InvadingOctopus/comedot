## A [Container] with an icon and other [Control]s to represent an [InventoryItem].

@warning_ignore("missing_tool")
class_name InventoryItemUI
extends GameplayResourceUI


#region Parameters
@export var inventoryItem: InventoryItem
#endregion


func _ready() -> void:
	applyInitialFlags()

	if inventoryItem:
		updateUI(false) # Display the initial value, without animation
		inventoryItem.changed.connect(self.onInventoryItem_changed)
	else:
		Debug.printWarning("Missing inventoryItem", self)


func onInventoryItem_changed() -> void:
	updateText()


## TIP: May be overridden in subclass to customize the icon, for example, show different icons or colors for different ranges of the [member Stat.value].
func updateIcon(_animate: bool = self.shouldAnimate) -> void:
	icon.texture = inventoryItem.icon


func updateText(_animate: bool = self.shouldAnimate) -> void:
	self.label.text   = inventoryItem.displayName
	self.tooltip_text = inventoryItem.description
