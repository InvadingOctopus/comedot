## An abstract base class for scripts that may be attached to any [Container] [Control]s to display a list of [GameplayResourceBase] Resources such as [Stat]s or [Action]s.

class_name ResourceListBase
extends Container

# TODO: Better abstraction when GDScript supports overriding properties :')


func _ready() -> void:
	self.buildListItems()


## Creates a UI [Control] for each of the [GameplayResourceBase] data items returned by [method getResources].
## WARNING: Removes all existing child nodes first.
func buildListItems() -> void:
	Tools.removeAllChildren(self)
	for listItem: GameplayResourceBase in self.getResources():
		createListItemUI(listItem)


## Returns the collection of [GameplayResourceBase] data to be displayed by this UI [Container].
## IMPORTANT: Abstract; MUST be implemented in subclass.
func getResources() -> Array[GameplayResourceBase]:
	Debug.printWarning("getResources() not implemented in subclass!", self)
	return []


## Creates a UI [Control] for the visual representation of a [GameplayResourceBase]'s data.
## IMPORTANT: Abstract; MUST be implemented in subclass.
@warning_ignore("unused_parameter")
func createListItemUI(listItem: Variant) -> Control:
	Debug.printWarning("createListItemUI() not implemented in subclass!", self)
	return null