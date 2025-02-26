## Comedot Plugin. Adds a custom dock ("Comedock") to the Godot Editor that provides convenience features for quickly creating [Entity] and [Component] objects.
## NOTE: This plugin is NOT necessary for using Comedot.
## Only `Entity.gd` and the scripts in the `Components` folder (and the AutoLoads etc. that they depend on) are the core functionality of Comedot.

@tool
extends EditorPlugin

# TODO: Menu item shortcut customization: List it in the Editor's Command Palette
# FIXME: BUG: Menu shortcuts only work when the Scene Editor is in focus, not any other dock etc.?
# TODO: Fix the Entity & Component icons SVG


#region Constants
const pluginPath		:= "res://addons/Comedot"
const pluginsettingsPath:= "addons/Comedot"

const entityTypeName	:= &"Comedot Entity"
const entityScript		:= preload("res://Entities/Entity.gd")
const entityIcon		:= preload("res://Assets/Icons/Entity.svg")

const componentTypeName	:= &"Comedot Component"
const componentScript	:= preload("res://Components/Component.gd")
const componentIcon		:= preload("res://Assets/Icons/Component.svg")
#endregion


func _enter_tree() -> void:
	printLog("Plugin _enter_tree()")
	addCustomTypes()
	# `call_deferred` because Godot seems to be loading this "too soon" and raising errors.
	addDock.call_deferred()
	addMenuItems.call_deferred()


func _exit_tree() -> void:
	removeMenuItems()
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
	componentsDock = preload("res://addons/Comedot/ComponentsDock.tscn").instantiate()
	componentsDock.plugin = self as EditorPlugin
	self.add_control_to_dock(DOCK_SLOT_LEFT_BR, componentsDock) #add_control_to_dock(DOCK_SLOT_LEFT_BR, componentsDock)
	self.set_dock_tab_icon(componentsDock, componentIcon)
	

func removeDock() -> void:
	remove_control_from_docks(componentsDock)
	componentsDock.queue_free()

#endregion


#region Custom Menu Items

const componentMenuItem := "New Component in Selected Folder..."
# TBD: const newComponentInFolderShortcutPath := pluginPath + "/newComponentInFolderShortcut"
var newComponentInFolderShortcut: Shortcut


func addMenuItems() -> void:
	self.add_tool_menu_item(componentMenuItem, componentsDock.createNewComponentInSelectedFolder)
	self.newComponentInFolderShortcut = load("res://addons/Comedot/NewComponentInFolderShortcut.tres")
	# TBD: ProjectSettings.set_setting(newComponentInFolderShortcutPath, newComponentInFolderShortcut)
	printLog(str("Added menu item: Project → Tools → ", componentMenuItem, " Shortcut: ", newComponentInFolderShortcut.get_as_text()))


func removeMenuItems() -> void:
	newComponentInFolderShortcut = null
	# TBD: ProjectSettings.clear(newComponentInFolderShortcutPath)
	# TBD: ProjectSettings.save()
	self.remove_tool_menu_item(componentMenuItem)


## Handles keyboard shortcuts for custom menu items
func _shortcut_input(event: InputEvent) -> void:
	# Handle shortcut only once, only when pressed
	if not event.is_pressed() or event.is_echo(): 
		return

	if newComponentInFolderShortcut.matches_event(event):
		componentsDock.createNewComponentInSelectedFolder()

#endregion

