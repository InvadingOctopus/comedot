## Tells the parent [UINavigationContainer] to replace its first child control with a different control,
## effectively displaying a new UI "page".

class_name UINavigationButton
extends Button


## The path of the new control to display in the parent [UINavigationContainer], replacing the parent's current first child control.
@export_file("*.tscn") var navigationDestination: String

## Optional: The [UINavigationContainer] whose child to replace with the [member navigationDestination]
## If `null`, then the first parent or grandparent of type [UINavigationContainer] is used.
@export var parentOverride: UINavigationContainer

func onPressed() -> void:
	Debug.printDebug(str(self, " onPressed(): navigationDestination: ", navigationDestination))
	if not navigationDestination: return

	var parentContainer: UINavigationContainer = parentOverride if parentOverride else Tools.findFirstParentOfType(self, UINavigationContainer)
	if not parentContainer: return

	parentContainer.displayNavigationDestination(navigationDestination)
