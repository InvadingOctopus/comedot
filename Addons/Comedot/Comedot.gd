## Comedot Plugin. Adds a custom dock ("Comedock") to the Godot Editor that provides convenience features for quickly creating [Entity] and [Component] objects.

@tool
extends EditorPlugin

# TODO: add_tool_menu_item


#region Constants
const entityTypeName    := &"Comedot Entity"
const componentTypeName := &"Comedot Component"
#endregion


func _enter_tree() -> void:
	addCustomTypes()
	call_deferred(&"addDock") # `call_deferred` because Godot seems to be loading this "too soon" and raising errors.


func _exit_tree() -> void:
	removeDock()
	removeCustomTypes()


#region Custom Types

func addCustomTypes() -> void:
	# Entity
	const entityScript := preload("res://Entities/Entity.gd")
	const entityIcon   := preload("res://Assets/Icons/Entity.svg")
	add_custom_type(entityTypeName, "Node2D", entityScript, entityIcon)

	# Component
	const componentScript := preload("res://Components/Component.gd")
	const componentIcon   := preload("res://Assets/Icons/Component.svg")
	add_custom_type(componentTypeName, "Node", componentScript, componentIcon)


func removeCustomTypes() -> void:
	remove_custom_type(entityTypeName)
	remove_custom_type(componentTypeName)

#endregion


#region Components Dock

var componentsDock: ComponentsDock

func addDock() -> void:
	componentsDock = preload("res://Addons/Comedot/ComponentsDock.tscn").instantiate()
	componentsDock.plugin = self as EditorPlugin
	componentsDock.editorInterface = get_editor_interface()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, componentsDock) #add_control_to_dock(DOCK_SLOT_LEFT_BR, componentsDock)


func removeDock() -> void:
	remove_control_from_docks(componentsDock)
	componentsDock.queue_free()

#endregion
