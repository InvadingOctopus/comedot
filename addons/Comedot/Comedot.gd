## Comedot Plugin. Adds a custom dock ("Comedock") to the Godot Editor that provides convenience features for quickly creating [Entity] and [Component] objects.

@tool
extends EditorPlugin

# TODO: add_tool_menu_item
# TODO: Fix the Entity & Component icons SVG


#region Constants
const entityTypeName	:= &"Comedot Entity"
const entityScript		:= preload("res://Entities/Entity.gd")
const entityIcon		:= preload("res://Assets/Icons/Entity.svg")

const componentTypeName	:= &"Comedot Component"
const componentScript	:= preload("res://Components/Component.gd")
const componentIcon		:= preload("res://Assets/Icons/Component.svg")

const componentMenuItem := "New Component in Selected Folder..."
#endregion


func _enter_tree() -> void:
	printLog("Plugin _enter_tree()")
	addCustomTypes()
	call_deferred(&"addDock") # `call_deferred` because Godot seems to be loading this "too soon" and raising errors.


func _exit_tree() -> void:
	removeDock()
	removeCustomTypes()


func _get_plugin_icon() -> Texture2D:
	return componentIcon


func printLog(message: String) -> void:
	print(str("Comedot:  ", message)) # Extra space to align with "Comedock: " :)


#region Custom Types

func addCustomTypes() -> void:
	# Entity
	add_custom_type(entityTypeName, "Node2D", entityScript, entityIcon)

	# Component
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
	self.add_control_to_dock(DOCK_SLOT_LEFT_BR, componentsDock) #add_control_to_dock(DOCK_SLOT_LEFT_BR, componentsDock)
	self.set_dock_tab_icon(componentsDock, componentIcon)
	self.add_tool_menu_item(componentMenuItem, componentsDock.createNewComponentInSelectedFolder)
	printLog("Added menu item: Project → Tools → " + componentMenuItem)


func removeDock() -> void:
	self.remove_tool_menu_item(componentMenuItem)
	remove_control_from_docks(componentsDock)
	componentsDock.queue_free()

#endregion
