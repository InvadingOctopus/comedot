## Tells the parent [UINavigationContainer] to replace its first child control with a different control,
## effectively displaying a new UI "page".

class_name UINavigationButton
extends Button

# TODO: Only allow Control scenes as navigationDestination
# TODO: A UI navigation system based on global signals


#region Parameters

## The path of the new [Control] to display in the parent [UINavigationContainer], replacing the parent's current first child [Control].
@export_file("*.tscn") var navigationDestination: String

## Optional: The [UINavigationContainer] whose child to replace with the [member navigationDestination]
## If `null`, then the first parent or grandparent of type [UINavigationContainer] is used.
@export var parentOverride: UINavigationContainer

@export var debugMode: bool

#endregion


func _ready() -> void:
	if not self.pressed.is_connected(self.onPressed):
		self.pressed.connect(self.onPressed)


func onPressed() -> void:
	if debugMode: Debug.printDebug(str("onPressed(): navigationDestination: ", navigationDestination), self)
	if not navigationDestination: return

	var parentContainer: UINavigationContainer = parentOverride if parentOverride else Tools.findFirstParentOfType(self, UINavigationContainer)
	if debugMode: Debug.printDebug(str("parentContainer: ", parentContainer), self)
	if not parentContainer: return

	parentContainer.displayNavigationDestination(navigationDestination)
