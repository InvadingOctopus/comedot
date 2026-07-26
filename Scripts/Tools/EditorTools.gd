## Helper functions for interacting with the Godot Editor from addons/plugins & `@tool` scripts.
## In the future, these functions & types may be incorporated into the builtin Godot API as native code or via custom extensions.

@tool
class_name EditorTools
extends Node


## Clears the Editor selection and selects a single specific node.
## TIP: Call with [method Callable.call_deferred] to avoid Godot errors when trying to select nodes that are being created etc.
static func selectNode(node: Node) -> void:
	if not is_instance_valid(node): return
	var selection: EditorSelection = EditorInterface.get_selection()
	selection.clear()
	selection.add_node(node)
	EditorInterface.edit_node(node)
